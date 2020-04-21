import chroma, hashes, internal, opengl/base, opengl/context, input,
    strformat, strutils, tables, times, typography, typography/textboxes,
    uibase, vmath, flippy

export input

var
  ctx*: Context
  fonts: Table[string, Font]
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

proc focus*(keyboard: Keyboard, group: Group) =
  if group.editableText and keyboard.inputFocusIdPath != group.idPath:
    keyboard.inputFocusIdPath = group.idPath
    keyboard.input = group.text
    textBox = newTextBox(
      fonts[group.textStyle.fontFamily],
      int group.screenBox.w,
      int group.screenBox.w,
      group.text,
      group.multiline
    )
    refresh()

proc unFocus*(keyboard: Keyboard, group: Group) =
  if keyboard.inputFocusIdPath == group.idPath:
    keyboard.inputFocusIdPath = ""

proc drawText(group: Group) =
  if group.textStyle.fontFamily notin fonts:
    quit &"font not found: {group.textStyle.fontFamily}"

  var font = fonts[group.textStyle.fontFamily]
  font.size = group.textStyle.fontSize
  font.lineHeight = group.textStyle.lineHeight

  if font.lineHeight == 0:
    font.lineHeight = font.size

  let mousePos = mouse.pos - group.screenBox.xy

  # draw masked region
  # TODO: mask should not be a text property
  # ctx.beginMask()
  # ctx.fillRect(
  #   rect(0, 0, group.screenBox.w, group.screenBox.h),
  #   rgba(255, 0, 0, 255).color
  # )
  # ctx.endMask()
  # defer: ctx.popMask()

  if current.editableText and
      mouse.down and
      mouse.pos.inside(current.screenBox):
    # mouse actions click, drag, double clicking
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
      keyboard.inputFocusIdPath == group.idPath:
    # Dragging the mouse:
    textBox.mouseAction(mousePos, click = false, keyboard.shiftKey)

  let editing = keyboard.inputFocusIdPath == group.idPath
  var layout: seq[GlyphPosition]

  if editing:
    if textBox.size != group.screenBox.wh:
      textBox.resize(group.screenBox.wh)
    layout = textBox.layout
    ctx.saveTransform()
    ctx.translate(-textBox.scroll)
    for rect in textBox.selectionRegions():
      ctx.fillRect(rect, group.highlightColor)
  else:
    layout = font.typeset(
      group.text,
      pos = vec2(0, 0),
      size = group.screenBox.wh,
      hAlignMode(group.textStyle.textAlignHorizontal),
      vAlignMode(group.textStyle.textAlignVertical)
    )

  # draw characters
  for glyphIdx, pos in layout:
    if pos.character notin font.glyphs:
      continue

    let
      font = pos.font
      subPixelShift = floor(pos.subPixelShift * 10) / 10
      fontFamily = group.textStyle.fontFamily

    var
      hashFill = hash((
        fontFamily,
        pos.character,
        font.size,
        subPixelShift,
        0
      ))
      hashStorke: Hash

    if group.strokeWeight > 0:
      hashStorke = hash((
        fontFamily,
        pos.character,
        font.size,
        subPixelShift,
        group.strokeWeight
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


    if group.strokeWeight > 0 and hashStorke notin ctx.entries:
      var
        glyph = font.glyphs[pos.character]
        glyphOffset: Vec2
      let glyphFill = font.getGlyphImage(
        glyph,
        glyphOffset,
        subPixelShift = subPixelShift
      )
      let glyphStroke = glyphFill.outlineBorder(group.strokeWeight.int)
      ctx.putImage(hashStorke, glyphStroke)

    let
      glyphOffset = glyphOffsets[hashFill]
      charPos = vec2(pos.rect.x + glyphOffset.x, pos.rect.y + glyphOffset.y)

    if group.strokeWeight > 0 and group.stroke.a > 0:
      ctx.drawImage(
        hashStorke,
        charPos - vec2(group.strokeWeight, group.strokeWeight),
        group.stroke
      )

    ctx.drawImage(hashFill, charPos, group.fill)

  if editing:
    # draw cursor
    ctx.fillRect(textBox.cursorRect, group.cursorColor)
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

proc draw*(group: Group) =
  ## Draws the group
  ctx.saveTransform()
  ctx.translate(group.screenBox.xy)
  if group.rotation != 0:
    ctx.translate(group.screenBox.wh/2)
    ctx.rotate(group.rotation/180*PI)
    ctx.translate(-group.screenBox.wh/2)

  if group.kind == "text":
    drawText(group)
  else:
    if group.fill.a > 0:
      if group.imageName == "":
        if group.cornerRadius[0] != 0:
          ctx.fillRoundedRect(rect(
            0, 0,
            group.screenBox.w, group.screenBox.h
          ), group.fill, group.cornerRadius[0])
        else:
          ctx.fillRect(rect(
            0, 0,
            group.screenBox.w, group.screenBox.h
          ), group.fill)

    if group.stroke.a > 0 and group.strokeWeight > 0 and group.kind != "text":
      ctx.strokeRoundedRect(rect(
        0, 0,
        group.screenBox.w, group.screenBox.h
      ), group.stroke, group.strokeWeight, group.cornerRadius[0])

    if group.imageName != "":
      let path = &"data/{group.imageName}"
      ctx.drawImage(path, size = vec2(group.screenBox.w, group.screenBox.h))

  ctx.restoreTransform()

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

  base.drawFrame = proc() =
    setupRoot()

    pathChecker.clear()

    root.box.x = float 0
    root.box.y = float 0
    root.box.w = windowSize.x
    root.box.h = windowSize.y

    scrollBox.x = float 0
    scrollBox.y = float 0
    scrollBox.w = root.box.w
    scrollBox.h = root.box.h

    clearColorBuffer(color(1.0, 1.0, 1.0, 1.0))
    ctx.beginFrame(windowFrame)
    ctx.saveTransform()
    mouse.pos = mouse.pos / pixelRatio

    drawMain()

    ctx.restoreTransform()
    ctx.endFrame()

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
  uibase.fullscreen = fullscreen
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
