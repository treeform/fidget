import chroma, common, flippy, hashes, input, internal, opengl/base,
    opengl/context, os, strformat, strutils, tables, times, typography,
    typography/textboxes, unicode, vmath

when not defined(emscripten) and not defined(fidgetNoAsync):
  import httpClient, asyncdispatch, asyncfutures, json

export input

var
  ctx*: Context
  glyphOffsets: Table[Hash, Vec2]
  windowTitle, windowUrl: string

  # Used for double-clicking
  multiClick: int
  lastClickTime: float

computeTextLayout = proc(node: Node) =
  var font = fonts[node.textStyle.fontFamily]
  font.size = node.textStyle.fontSize
  font.lineHeight = node.textStyle.lineHeight
  if font.lineHeight == 0:
    font.lineHeight = font.size
  var
    boundsMin: Vec2
    boundsMax: Vec2
    size = node.box.wh
  if node.textStyle.autoResize == tsWidthAndHeight:
    size = vec2(0, 0)
  node.textLayout = font.typeset(
    node.text.toRunes(),
    pos = vec2(0, 0),
    size = size,
    hAlignMode(node.textStyle.textAlignHorizontal),
    vAlignMode(node.textStyle.textAlignVertical),
    clip = false,
    boundsMin = boundsMin,
    boundsMax = boundsMax
  )
  node.textLayoutWidth = boundsMax.x - boundsMin.x
  node.textLayoutHeight = boundsMax.y - boundsMin.y

proc refresh*() =
  ## Request the screen be redrawn
  requestedFrame = true

proc focus*(keyboard: Keyboard, node: Node) =
  if keyboard.focusNode != node:
    keyboard.onUnFocusNode = keyboard.focusNode
    keyboard.onFocusNode = node
    keyboard.focusNode = node

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
    textBox.scrollable = true

    refresh()

proc unFocus*(keyboard: Keyboard, node: Node) =
  if keyboard.focusNode == node:
    keyboard.onUnFocusNode = keyboard.focusNode
    keyboard.onFocusNode = nil
    keyboard.focusNode = nil

proc drawText(node: Node) =
  if node.textStyle.fontFamily notin fonts:
    quit &"font not found: {node.textStyle.fontFamily}"

  var font = fonts[node.textStyle.fontFamily]
  font.size = node.textStyle.fontSize
  font.lineHeight = node.textStyle.lineHeight
  if font.lineHeight == 0:
    font.lineHeight = font.size

  let mousePos = mouse.pos - node.screenBox.xy

  if node.selectable and mouse.down and mouse.pos.inside(node.screenBox):
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
      keyboard.focusNode == node:
    # Dragging the mouse:
    textBox.mouseAction(mousePos, click = false, keyboard.shiftKey)

  let editing = keyboard.focusNode == node

  if editing:
    if textBox.size != node.box.wh:
      textBox.resize(node.box.wh)
    node.textLayout = textBox.layout
    ctx.saveTransform()
    ctx.translate(-textBox.scroll)
    for rect in textBox.selectionRegions():
      ctx.fillRect(rect, node.highlightColor)
  else:
    discard

  # draw characters
  for glyphIdx, pos in node.textLayout:
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

  #ctx.clearMask()

proc capture*(mouse: Mouse) =
  captureMouse()

proc release*(mouse: Mouse) =
  releaseMouse()

proc hide*(mouse: Mouse) =
  hideMouse()

proc remove*(node: Node) =
  ## Removes the node.
  discard

proc removeExtraChildren*(node: Node) =
  ## Deal with removed nodes.
  node.nodes.setLen(node.diffIndex)

proc draw*(node: Node) =
  ## Draws the node.
  ctx.saveTransform()
  ctx.translate(node.screenBox.xy)
  if node.rotation != 0:
    ctx.translate(node.screenBox.wh/2)
    ctx.rotate(node.rotation/180*PI)
    ctx.translate(-node.screenBox.wh/2)

  if node.clipContent:
    ctx.beginMask()
    if node.cornerRadius[0] != 0:
      ctx.fillRoundedRect(rect(
        0, 0,
        node.screenBox.w, node.screenBox.h
      ), rgba(255, 0, 0, 255).color, node.cornerRadius[0])
    else:
      ctx.fillRect(rect(
        0, 0,
        node.screenBox.w, node.screenBox.h
      ), rgba(255, 0, 0, 255).color)
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
      let path = dataDir / node.imageName
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
  mainLoopMode: MainLoopMode,
  pixelate: bool,
  forcePixelScale: float32
) =
  pixelScale = forcePixelScale

  base.start(openglVersion, msaa, mainLoopMode)
  setWindowTitle(windowTitle)
  ctx = newContext(pixelate = pixelate, pixelScale = pixelScale)
  requestedFrame = true

  base.drawFrame = proc() =
    clearColorBuffer(color(1.0, 1.0, 1.0, 1.0))
    ctx.beginFrame(windowFrame)
    ctx.saveTransform()
    ctx.scale(ctx.pixelScale)

    mouse.cursorStyle = Default

    setupRoot()
    root.box.x = float 0
    root.box.y = float 0
    root.box.w = windowLogicalSize.x
    root.box.h = windowLogicalSize.y
    scrollBox.x = float 0
    scrollBox.y = float 0
    scrollBox.w = root.box.w
    scrollBox.h = root.box.h

    if textBox != nil:
      keyboard.input = textBox.text

    drawMain()

    computeLayout(nil, root)
    computeScreenBox(nil, root)

    # Only draw the root after everything was done:
    root.draw()

    ctx.restoreTransform()
    ctx.endFrame()

    # Only set mouse style when it changes.
    if mouse.prevCursorStyle != mouse.cursorStyle:
      mouse.prevCursorStyle = mouse.cursorStyle
      echo mouse.cursorStyle
      case mouse.cursorStyle:
        of Default:
          setCursor(cursorDefault)
        of Pointer:
          setCursor(cursorPointer)
        of Grab:
          setCursor(cursorGrab)
        of NSResize:
          setCursor(cursorNSResize)

    when defined(testOneFrame):
      ## This is used for test only
      ## Take a screen shot of the first frame and exit.
      var img = takeScreenshot()
      img.save("screenshot.png")
      quit()

  useDepthBuffer(false)

  if loadMain != nil:
    loadMain()

proc asyncPoll() =
  when not defined(emscripten) and not defined(fidgetNoAsync):
    var haveCalls = false
    for call in httpCalls.values:
      if call.status == Loading:
        haveCalls = true
        break
    if haveCalls:
      poll()

proc startFidget*(
  draw: proc(),
  tick: proc() = nil,
  load: proc() = nil,
  fullscreen = false,
  w: Positive = 1280,
  h: Positive = 800,
  openglVersion = (3, 3),
  msaa = msaaDisabled,
  mainLoopMode: MainLoopMode = RepaintOnEvent,
  pixelate = false,
  pixelScale = 1.0
) =
  ## Starts Fidget UI library
  common.fullscreen = fullscreen
  if not fullscreen:
    windowSize = vec2(w.float32, h.float32)
  drawMain = draw
  tickMain = tick
  loadMain = load
  setupFidget(openglVersion, msaa, mainLoopMode, pixelate, pixelScale)
  mouse.pixelScale = pixelScale
  when defined(emscripten):
    # Emscripten can't block so it will call this callback instead.
    proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}
    proc mainLoop() {.cdecl.} =

      asyncPoll()
      updateLoop()
    emscripten_set_main_loop(main_loop, 0, true)
  else:
    while base.running:
      updateLoop()
      asyncPoll()
    exit()

proc getTitle*(): string =
  ## Gets window title
  windowTitle

proc setTitle*(title: string) =
  ## Sets window title
  if (windowTitle != title):
    windowTitle = title
    setWindowTitle(title)
    refresh()

proc setWindowBounds*(min, max: Vec2) =
  base.setWindowBounds(min, max)

proc getUrl*(): string =
  windowUrl

proc setUrl*(url: string) =
  windowUrl = url
  refresh()

proc loadFontAbsolute*(name: string, pathOrUrl: string) =
  ## Loads fonts anywhere in the system.
  ## Not supported on js, emscripten, ios or android.
  if pathOrUrl.endsWith(".svg"):
    fonts[name] = readFontSvg(pathOrUrl)
  elif pathOrUrl.endsWith(".ttf"):
    fonts[name] = readFontTtf(pathOrUrl)
  elif pathOrUrl.endsWith(".otf"):
    fonts[name] = readFontOtf(pathOrUrl)
  else:
    raise newException(Exception, "Unsupported font format")

proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads the font from the dataDir.
  loadFontAbsolute(name, dataDir / pathOrUrl)

proc setItem*(key, value: string) =
  ## Saves value into local storage or file.
  writeFile(&"{key}.data", value)

proc getItem*(key: string): string =
  ## Gets a value into local storage or file.
  readFile(&"{key}.data")

when not defined(emscripten) and not defined(fidgetNoAsync):
  proc httpGetCb(future: Future[string]) =
    refresh()

  proc httpGet*(url: string): HttpCall =
    if url notin httpCalls:
      result = HttpCall()
      var client = newAsyncHttpClient()
      echo "new call"
      result.future = client.getContent(url)
      result.future.addCallback(httpGetCb)
      httpCalls[url] = result
      result.status = Loading
    else:
      result = httpCalls[url]

    if result.status == Loading and result.future.finished:
      result.status = Ready
      try:
        result.data = result.future.read()
        result.json = parseJson(result.data)
      except HttpRequestError:
        echo getCurrentExceptionMsg()
        result.status = Error

    return
