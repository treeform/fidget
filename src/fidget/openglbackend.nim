import chroma, hashes, internal, opengl/base, opengl/context, input,
    strformat, strutils, tables, times, typography, typography/textboxes,
    common, vmath, flippy, unicode

export input

var
  ctx*: Context
  fonts*: Table[string, Font]
  glyphOffsets: Table[Hash, Vec2]
  windowTitle, windowUrl: string

  # Used for double-clicking
  multiClick: int
  lastClickTime: float

func hAlignMode(align: HAlign): HAlignMode =
  case align:
    of hLeft: HAlignMode.Left
    of hCenter: Center
    of hRight: HAlignMode.Right

func vAlignMode(align: VAlign): VAlignMode =
  case align:
    of vTop: Top
    of vCenter: Middle
    of vBottom: Bottom

proc refresh*() =
  ## Request the screen be redrawn
  requestedFrame = true

proc focus*(keyboard: Keyboard, node: Node) =
  if keyboard.inputFocusIdPath != node.idPath:
    keyboard.inputFocusIdPath = node.idPath
    keyboard.input = node.text
    textBox = newTextBox(
      fonts[node.textStyle.fontFamily],
      int node.screenBox.w,
      int node.screenBox.h,
      node.text,
      hAlignMode(node.textStyle.textAlignHorizontal),
      vAlignMode(node.textStyle.textAlignVertical),
      node.multiline,
      worldWrap = true,
    )
    textBox.editable = node.editableText
    textBox.scrollable = false
    refresh()

proc unFocus*(keyboard: Keyboard, node: Node) =
  if keyboard.inputFocusIdPath == node.idPath:
    keyboard.inputFocusIdPath = ""

proc drawText(node: Node) =
  if node.textStyle.fontFamily notin fonts:
    quit &"font not found: {node.textStyle.fontFamily}"

  var font = fonts[node.textStyle.fontFamily]
  font.size = node.textStyle.fontSize
  font.lineHeight = node.textStyle.lineHeight

  if font.lineHeight == 0:
    font.lineHeight = font.size

  let mousePos = mouse.pos - node.screenBox.xy

  if mouse.down and mouse.pos.inside(node.screenBox):
    # mouse actions click, drag, double clicking
    keyboard.focus(node)
    if mouse.click:
      if epochTime() - lastClickTime < 0.5:
        inc multiClick
      else:
        multiClick = 0
      lastClickTime = epochTime()
      if multiClick == 1:
        textBox.selectWord(mousePos)
        buttonDown[MOUSE_LEFT] = false
      elif multiClick == 2:
        textBox.selectParagraph(mousePos)
        buttonDown[MOUSE_LEFT] = false
      elif multiClick == 3:
        textBox.selectAll()
        buttonDown[MOUSE_LEFT] = false
      else:
        textBox.mouseAction(mousePos, click = true, keyboard.shiftKey)

  if textBox != nil and
      mouse.down and
      not mouse.click and
      keyboard.inputFocusIdPath == node.idPath:
    # Dragging the mouse:
    textBox.mouseAction(mousePos, click = false, keyboard.shiftKey)

  let editing = keyboard.inputFocusIdPath == node.idPath
  var layout: seq[GlyphPosition]

  if editing:
    if textBox.size != node.screenBox.wh:
      textBox.resize(node.screenBox.wh)
    layout = textBox.layout
    ctx.saveTransform()
    ctx.translate(-textBox.scroll)
    for rect in textBox.selectionRegions():
      ctx.fillRect(rect, node.highlightColor)
  else:
    # TODO handle auto sizing
    # var size = case node.textStyle.autoResize:
    #   of tNone:
    #     node.screenBox.wh
    #   of tWidthAndHeight:
    #     vec2(0, 0)
    #   of tHeight:
    #     vec2(0, node.screenBox.h)
    layout = font.typeset(
      node.text,
      pos = vec2(0, 0),
      size = node.screenBox.wh,
      hAlignMode(node.textStyle.textAlignHorizontal),
      vAlignMode(node.textStyle.textAlignVertical),
      clip = false,
    )

  # draw characters
  for glyphIdx, pos in layout:
    if pos.character notin font.glyphs:
      continue
    if pos.rune == Rune(32):
      # Don't draw space, even if font has a char for it.
      continue

    let
      font = pos.font
      subPixelShift = floor(pos.subPixelShift * 10) / 10
      fontFamily = node.textStyle.fontFamily

    var
      hashFill = hash((
        2344,
        fontFamily,
        pos.character,
        (font.size*100).int,
        (subPixelShift*100).int,
        0
      ))
      hashStroke: Hash

    if node.strokeWeight > 0:
      hashStroke = hash((
        9812,
        fontFamily,
        pos.character,
        (font.size*100).int,
        (subPixelShift*100).int,
        node.strokeWeight
      ))

    if hashFill notin ctx.entries:
      var
        glyph = font.glyphs[pos.character]
        glyphOffset: Vec2
      let glyphFill = font.getGlyphImage(
        glyph,
        glyphOffset,
        subPixelShift = subPixelShift
      )
      ctx.putImage(hashFill, glyphFill)
      glyphOffsets[hashFill] = glyphOffset


    if node.strokeWeight > 0 and hashStroke notin ctx.entries:
      var
        glyph = font.glyphs[pos.character]
        glyphOffset: Vec2
      let glyphFill = font.getGlyphImage(
        glyph,
        glyphOffset,
        subPixelShift = subPixelShift
      )
      let glyphStroke = glyphFill.outlineBorder(node.strokeWeight.int)
      ctx.putImage(hashStroke, glyphStroke)

    let
      glyphOffset = glyphOffsets[hashFill]
      charPos = vec2(pos.rect.x + glyphOffset.x, pos.rect.y + glyphOffset.y)

    if node.strokeWeight > 0 and node.stroke.a > 0:
      ctx.drawImage(
        hashStroke,
        charPos - vec2(node.strokeWeight, node.strokeWeight),
        node.stroke
      )

    ctx.drawImage(hashFill, charPos, node.fill)

  if editing:
    if textBox.cursor == textBox.selector and node.editableText:
      # draw cursor
      ctx.fillRect(textBox.cursorRect, node.cursorColor)
    # debug
    # ctx.fillRect(textBox.selectorRect, rgba(0, 0, 0, 255).color)
    # ctx.fillRect(rect(textBox.mousePos, vec2(4, 4)), rgba(255, 128, 128, 255).color)
    ctx.restoreTransform()

    keyboard.input = textBox.text

  #ctx.clearMask()

proc capture*(mouse: Mouse) =
  captureMouse()

proc release*(mouse: Mouse) =
  releaseMouse()

proc hide*(mouse: Mouse) =
  hideMouse()

proc draw*(node: Node) =
  ## Draws the node
  ctx.saveTransform()
  ctx.translate(node.screenBox.xy)
  if node.rotation != 0:
    ctx.translate(node.screenBox.wh/2)
    ctx.rotate(node.rotation/180*PI)
    ctx.translate(-node.screenBox.wh/2)

  if node.clipContent:
    ctx.beginMask()
    ctx.fillRect(
      rect(0, 0, node.screenBox.w, node.screenBox.h),
      rgba(255, 0, 0, 255).color
    )
    ctx.endMask()

  if node.kind == nkText:
    drawText(node)
  else:
    if node.fill.a > 0:
      if node.imageName == "":
        if node.cornerRadius[0] != 0:
          ctx.fillRoundedRect(rect(
            0, 0,
            node.screenBox.w, node.screenBox.h
          ), node.fill, node.cornerRadius[0])
        else:
          ctx.fillRect(rect(
            0, 0,
            node.screenBox.w, node.screenBox.h
          ), node.fill)

    if node.stroke.a > 0 and node.strokeWeight > 0 and node.kind != nkText:
      ctx.strokeRoundedRect(rect(
        0, 0,
        node.screenBox.w, node.screenBox.h
      ), node.stroke, node.strokeWeight, node.cornerRadius[0])

    if node.imageName != "":
      let path = &"data/{node.imageName}"
      ctx.drawImage(path, size = vec2(node.screenBox.w, node.screenBox.h))

  ctx.restoreTransform()

  for j in 1 .. node.nodes.len:
    node.nodes[^j].draw()

  if node.clipContent:
    ctx.popMask()

proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard

proc setupFidget(
  openglVersion: (int, int),
  msaa: MSAA,
  mainLoopMode: MainLoopMode
) =
  base.start(openglVersion, msaa, mainLoopMode)
  setWindowTitle(windowTitle)

  ctx = newContext()
  requestedFrame = true

  base.drawFrame = proc() =

    setupRoot()
    root.box.x = float 0
    root.box.y = float 0
    root.box.w = windowSize.x
    root.box.h = windowSize.y
    scrollBox.x = float 0
    scrollBox.y = float 0
    scrollBox.w = root.box.w
    scrollBox.h = root.box.h

    drawMain()

    clearColorBuffer(color(1.0, 1.0, 1.0, 1.0))
    ctx.beginFrame(windowFrame)
    ctx.saveTransform()
    mouse.pos = mouse.pos / pixelRatio

    # Only draw the root after everything was done:
    root.draw()

    ctx.restoreTransform()
    ctx.endFrame()

    #dumpTree(root)

  useDepthBuffer(false)

proc runFidget(
  draw: proc(),
  tick: proc(),
  openglVersion: (int, int),
  msaa: MSAA,
  mainLoopMode: MainLoopMode
) =
  drawMain = draw
  tickMain = tick
  setupFidget(openglVersion, msaa, mainLoopMode)
  when defined(emscripten):
    # Emscripten can't block so it will call this callback instead.
    proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}
    proc mainLoop() {.cdecl.} =
      updateLoop()
    emscripten_set_main_loop(main_loop, 0, true);
  else:
    while running:
      updateLoop()
    exit()

proc startFidget*(
    draw: proc(),
    tick: proc() = nil,
    fullscreen = false,
    w: Positive = 1280,
    h: Positive = 800,
    openglVersion = (4, 1),
    msaa = msaaDisabled,
    mainLoopMode: MainLoopMode = RepaintOnEvent
) =
  ## Starts Fidget UI library
  common.fullscreen = fullscreen
  if not fullscreen:
    windowSize = vec2(w.float32, h.float32)
  runFidget(draw, tick, openglVersion, msaa, mainLoopMode)

proc getTitle*(): string =
  ## Gets window title
  windowTitle

proc setTitle*(title: string) =
  ## Sets window title
  if (windowTitle != title):
    windowTitle = title
    setWindowTitle(title)
    refresh()

proc getUrl*(): string =
  windowUrl

proc setUrl*(url: string) =
  windowUrl = url
  refresh()

proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads a font.
  if pathOrUrl.endsWith(".svg"):
    fonts[name] = readFontSvg(pathOrUrl)
  elif pathOrUrl.endsWith(".ttf"):
    fonts[name] = readFontTtf(pathOrUrl)
  else:
    raise newException(Exception, "Unsupported font format")

proc setItem*(key, value: string) =
  ## Saves value into local storage or file.
  writeFile(&"{key}.data", value)

proc getItem*(key: string): string =
  ## Gets a value into local storage or file.
  readFile(&"{key}.data")
