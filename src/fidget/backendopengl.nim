import tables, unicode
import vmath, chroma, typography, print
import openglbackend/base, openglbackend/context, openglbackend/input
import uibase

export windowFrame
export input

var
  ctx*: Context
  fonts* = newTable[string, Font]()


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
  # let fontHeight = font.ascent - font.descent
  # let scale = font.size / fontHeight
  let editing = keyboard.inputFocusIdPath == group.idPath
  let cursorWidth = clamp(floor(font.size/12.0), 1.0, 12.0)
  var cursorPos = vec2(0, 0)

  if editing:
    group.text = keyboard.input

  let layout = font.typeset(
    group.text,
    pos=vec2(0, 0), #group.screenBox.xy,
    size=group.screenBox.wh,
    hAlignNum(group.textStyle.textAlignHorizontal),
    vAlignNum(group.textStyle.textAlignVertical)
  )

  if keyboard.textCursor > layout.len:
    keyboard.textCursor = layout.len

  # draw layout boxes
  for pos in layout:
    ctx.fillRect(pos.selectRect, color(0, 0, 1, 0.1))

  # draw characters
  for glphyIdx, pos in layout:
    var font = pos.font

    if pos.character in font.glyphs:
      let subPixelShift = floor(pos.subPixelShift*10)/10

      let charKey = "tmp/" & group.textStyle.fontFamily & "." & pos.character & "." & $font.size & "." & $subPixelShift & ".png"
      if charKey notin ctx.entries:
        var glyph = font.glyphs[pos.character]
        var glyphOffset: Vec2
        let img = font.getGlyphImage(glyph, glyphOffset, subPixelShift=subPixelShift)
        ctx.putImage(charKey, img)
        glyphOffsets[charKey] = glyphOffset

      let glyphOffset = glyphOffsets[charKey]
      let charPos = vec2(pos.rect.x + glyphOffset.x, pos.rect.y + glyphOffset.y)

      ctx.drawImage(charKey, charPos, group.fill)

    if editing and keyboard.textCursor == glphyIdx:
      # draw text cursor at glyph pos
      cursorPos = pos.selectRect.xy


  if editing and keyboard.input.len == 0:
    # draw text cursor at the start if there is no characters
    cursorPos = group.screenBox.xy
  elif editing and keyboard.inputRunes.len == keyboard.textCursor:
    # draw text cursor at the end character
    let pos = layout[^1]
    if pos.character != "\n":
      cursorPos.x = pos.selectRect.x + pos.selectRect.w
      cursorPos.y = pos.selectRect.y
    else:
      cursorPos.x = 0
      cursorPos.y = pos.selectRect.y + font.lineHeight

  ctx.fillRect(rect(
    cursorPos.x,
    cursorPos.y,
    cursorWidth,
    font.lineHeight #font.size
  ), group.fill)


  if group.text.len > 0 or (group.editableText and group.placeholder.len > 0):
    var text = group.text
    if group.editableText:

      if group.text.len == 0 and group.placeholder.len > 0:
          text = group.placeholder

      if keyboard.inputChange and not keyboard.goingUp and not keyboard.goingDown:
        keyboard.lastUpDownX = cursorPos.x

      if keyboard.goingUp:
        let pos = layout.pickGlyphAt(vec2(keyboard.lastUpDownX, cursorPos.y - font.lineHeight * 0.5))
        if pos.character != "":
          keyboard.textCursor = pos.count
        keyboard.goingUp = false

      if keyboard.goingDown:
        let pos = layout.pickGlyphAt(vec2(keyboard.lastUpDownX, cursorPos.y + font.lineHeight * 1.5))
        if pos.character != "":
          keyboard.textCursor = pos.count
        keyboard.goingDown = false

      if mouse.click and mouse.pos.inside(current.screenBox):
        echo "gain focus"
        keyboard.inputFocusIdPath = group.idPath
        keyboard.input = group.text
        keyboard.inputRunes = group.text.toRunes()
        keyboard.textCursor = keyboard.input.len

        # pick where to playce the textCursor
        let pickMousePos = mouse.pos - current.screenBox.xy
        let pos = layout.pickGlyphAt(pickMousePos)
        if pos.character != "":
          keyboard.textCursor = pos.count
          keyboard.lastUpDownX = mouse.pos.x

          # when selecting the last character, select the end
          let pickOffset = pickMousePos - pos.selectRect.xy
          if pickOffset.x > pos.selectRect.w / 2 and keyboard.textCursor == keyboard.inputRunes.len - 1:
            inc keyboard.textCursor

        mouse.use()

      if mouse.click and not mouse.pos.inside(current.screenBox):
        echo "loose focus"
        if keyboard.inputFocusIdPath == group.idPath:
          keyboard.inputFocusIdPath = ""

  # we have processed the change
  keyboard.inputChange = false


proc draw*(group: Group) =
  ## Draws the group
  #echo group.id

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
        ctx.fillRect(rect(
          0, 0,
          group.screenBox.w, group.screenBox.h
        ), group.fill)

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


proc setupFidget*() =
  base.start()
  ctx = newContext(1024*8)

  base.drawFrame = proc() =
    proj = ortho(0, windowFrame.x, windowFrame.y, 0, -100, 100)

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

    ctx.saveTransform()
    # 4k 3840x2160
    # 2k 2048×1080
    # let rez = vec2(2048, 1080)

    #ctx.translate(windowFrame/2)
    # ctx.scale(max(windowFrame.x/rez.x, windowFrame.y/rez.y))
    # ctx.translate(-rez/2)


    # zoom height and window width
    # let zoom = windowFrame.y/1080
    # root.box.w = windowSize.x / zoom
    # root.box.h = 1080
    # ctx.scale(zoom)
    # mouse.pos = mousePos / zoom

    mouse.pos = mousePos

    drawMain()

    ctx.restoreTransform()

    # ctx.drawImage("mainMenu.png", vec2(0, 0))
    # ctx.drawImage("fleetA.png", vec2(500, 100))
    # ctx.saveTransform()
    # #ctx.translate(vec2(500, 500))
    # ctx.scale(5.0)
    # ctx.drawImage("circle100.png")
    # ctx.restoreTransform()

    ctx.flip()

  useDepthBuffer(false)


proc startFidget*() =
  ## Starts fidget UI library
  setupFidget()

  while base.running:
    base.tick()

  base.exit()


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