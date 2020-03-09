import chroma, internal, opengl/context, opengl/input, strutils, tables, times,
    typography, typography/textboxes, uibase, vmath

when defined(ios) or defined(android):
  import opengl/basemobile as base
else:
  import opengl/base as base

export input

var
  ctx*: Context
  fonts* = newTable[string, Font]()

  # used for double-clicking:
  multiClick: int
  lastClickTime: float

proc hAlignNum(num: int): HAlignMode =
  case num:
    of -1: HAlignMode.Left
    of 0: Center
    of 1: HAlignMode.Right
    else: HAlignMode.Left

proc vAlignNum(num: int): VAlignMode =
  case num:
    of -1: Top
    of 0: Middle
    of 1: Bottom
    else: Top

var glyphOffsets = newTable[string, Vec2]()

proc drawText(group: Group) =
  if group.textStyle.fontFamily notin fonts:
    quit "font not found: " & group.textStyle.fontFamily

  var font = fonts[group.textStyle.fontFamily]
  font.size = group.textStyle.fontSize
  font.lineHeight = group.textStyle.lineHeight

  if font.lineHeight == 0:
    font.lineHeight = font.size
  #print group.textStyle.lineHeight

  let mousePos = mouse.pos - group.screenBox.xy

  # draw masked region
  ctx.beginMask()
  ctx.fillRect(
    rect(0, 0, group.screenBox.w, group.screenBox.h),
    rgba(255, 0, 0, 255).color
  )
  ctx.endMask()

  if current.editableText and mouse.down and mouse.pos.inside(
      current.screenBox):
    if mouse.click and keyboard.inputFocusIdPath != group.idPath:
      keyboard.inputFocusIdPath = group.idPath
      textBox = newTextBox(
        font,
        int group.screenBox.w,
        int group.screenBox.w,
        group.text,
        current.multiline
      )
    # mouse actions click, drag, double clicking
    if mouse.click:
      if epochTime() - lastClickTime < 0.5:
        inc multiClick
      else:
        multiClick = 0
      lastClickTime = epochTime()
      if multiClick == 1:
        textBox.selectWord(mousePos)
        mouse.down = false
      elif multiClick == 2:
        textBox.selectPeragraph(mousePos)
        mouse.down = false
      elif multiClick == 3:
        textBox.selectAll()
        mouse.down = false
      else:
        textBox.mouseAction(mousePos, click = true, keyboard.shiftKey)

  if textBox != nil and mouse.down and not mouse.click and
      keyboard.inputFocusIdPath == group.idPath:
    # draggin the mouse
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

  if layout.len == 0:
    var text = group.text
    if text == "" and group.placeholder.len > 0:
      text = group.placeholder
    layout = font.typeset(
      text,
      pos = vec2(0, -1), #group.screenBox.xy,
      size = group.screenBox.wh,
      hAlignNum(group.textStyle.textAlignHorizontal),
      vAlignNum(group.textStyle.textAlignVertical)
    )

  # draw characters
  for glphyIdx, pos in layout:
    var font = pos.font

    if pos.character in font.glyphs:
      let subPixelShift = floor(pos.subPixelShift*10)/10

      let charKey = "tmp/" & group.textStyle.fontFamily & "." & pos.character &
          "." & $font.size & "." & $subPixelShift & ".png"
      if charKey notin ctx.entries:
        var glyph = font.glyphs[pos.character]
        var glyphOffset: Vec2
        let img = font.getGlyphImage(glyph, glyphOffset,
            subPixelShift = subPixelShift)
        ctx.putImage(charKey, img)
        glyphOffsets[charKey] = glyphOffset

      let glyphOffset = glyphOffsets[charKey]
      let charPos = vec2(pos.rect.x + glyphOffset.x, pos.rect.y + glyphOffset.y)

      ctx.drawImage(charKey, charPos, group.fill)

  if editing:
    # draw cursor
    ctx.fillRect(textBox.cursorRect, group.cursorColor)
    # debug
    #ctx.fillRect(textBox.selectorRect, rgba(0, 0, 0, 255).color)
    # ctx.fillRect(rect(textBox.mousePos, vec2(4, 4)), rgba(255, 128, 128, 255).color)
    ctx.restoreTransform()

    keyboard.input = textBox.text

  ctx.clearMask()

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

  if group.fill.a > 0:
    if group.kind == "text":
      drawText(group)
    else:
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
    let path = "data/" & group.imageName & ".png"
    ctx.drawImage(path, vec2(0, 0), vec2(group.screenBox.w, group.screenBox.h))

  ctx.restoreTransform()

proc redraw*() =
  ## Request the screen to be redrawn next
  if not requestedFrame:
    requestedFrame = true

proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard

proc openBrowserWithText*(text: string) =
  ## Opens a new window with just this text on it
  discard

proc goto*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  rootUrl = url
  redraw()

proc setupFidget() =
  base.start()

  when defined(ios):
    ctx = newContext(1024*4)
  else:
    # TODO: growing context texture
    ctx = newContext(1024*1)

  base.drawFrame = proc() =
    proj = ortho(0, windowFrame.x/dpi, windowFrame.y/dpi, 0, -100, 100)
    setupRoot()

    root.box.x = float 0
    root.box.y = float 0
    root.box.w = windowSize.x
    root.box.h = windowSize.y

    scrollBox.x = float 0
    scrollBox.y = float 0
    scrollBox.w = root.box.w
    scrollBox.h = root.box.h

    clearColorBuffer(color(1.0, 1.0, 1.0, 1.0))
    ctx.startFrame(windowFrame)
    ctx.saveTransform()
    mouse.pos = mousePos / dpi

    drawMain()

    ctx.restoreTransform()
    ctx.endFrame()

  useDepthBuffer(false)

proc runFidget(draw: proc()) =
  drawMain = draw
  setupFidget()
  while base.running:
    base.tick()
  base.exit()

when defined(ios) or defined(android):
  proc startFidget*(draw: proc()) =
    ## Starts Fidget UI library
    runFidget(draw)
else:
  proc startFidget*(
      draw: proc(),
      fullscreen = false,
      w: Positive = 1280,
      h: Positive = 800
  ) =
    ## Starts Fidget UI library
    uibase.fullscreen = fullscreen
    if not fullscreen:
      windowFrame = vec2(w.float32, h.float32)

    runFidget(draw)

proc `title=`*(win: uibase.Window, title: string) =
  ## Sets window url
  win.innerTitle = title
  setWindowTitle(title)

proc `title`*(win: uibase.Window): string =
  ## Gets window url
  return win.innerTitle

proc `url=`*(win: uibase.Window, url: string) =
  ## Sets window url
  win.innerUrl = url

proc `url`*(win: uibase.Window): string =
  ## Gets window url
  return win.innerUrl

proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads a font.
  if pathOrUrl.endsWith(".svg"):
    fonts[name] = readFontSVG(pathOrUrl)
  elif pathOrUrl.endsWith(".ttf"):
    fonts[name] = readFontTTF(pathOrUrl)

proc setItem*(key, value: string) =
  ## Saves value into local storage or file.
  writeFile(key & ".data", value)

proc getItem*(key: string): string =
  ## Gets a value into local storage or file.
  readFile(key & ".data")
