import tables, unicode, times
import vmath, chroma, typography, typography/textboxes, print
import openglbackend/base, openglbackend/context, openglbackend/input
import uibase

export windowFrame
export input

var
  ctx*: Context
  fonts* = newTable[string, Font]()

  # used for double cliking:
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
  # let fontHeight = font.ascent - font.descent
  # let scale = font.size / fontHeight

  if mouse.down and mouse.pos.inside(current.screenBox):
    if mouse.click and keyboard.inputFocusIdPath != group.idPath:
      print "gain focus"
      keyboard.inputFocusIdPath = group.idPath
      print "created new text box", group.idPath
      textBox = newTextBox(
        font,
        int group.screenBox.w,
        int group.screenBox.w,
        group.text
      )

    # mouse actions click, drag, double clicking
    let mousePos = mouse.pos - group.screenBox.xy
    if mouse.click:
      if epochTime() - lastClickTime < 0.5:
        inc multiClick
      else:
        multiClick = 0
      print multiClick, epochTime() - lastClickTime
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
        textBox.mouseAction(mousePos, click=true)

  if mouse.down and not mouse.click:
    # draggin the mouse
    let mousePos = mouse.pos - group.screenBox.xy
    textBox.mouseAction(mousePos, click=false)

  let editing = keyboard.inputFocusIdPath == group.idPath

  var layout: seq[GlyphPosition]

  if editing:
    if textBox.size != group.screenBox.wh:
      textBox.resize(group.screenBox.wh)
    layout = textBox.layout
    ctx.saveTransform()
    ctx.translate(vec2(0, float -textBox.scrollY))

    for rect in textBox.selectionRegions():
      ctx.fillRect(rect, rgba(0, 255, 0, 155).color)

  else:
    layout = font.typeset(
      group.text,
      pos=vec2(0, 0), #group.screenBox.xy,
      size=group.screenBox.wh,
      hAlignNum(group.textStyle.textAlignHorizontal),
      vAlignNum(group.textStyle.textAlignVertical)
    )

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

  if editing:
    # draw cursor
    ctx.fillRect(textBox.selectorRect, rgba(0, 0, 255, 255).color)
    ctx.fillRect(textBox.cursorRect, rgba(255, 0, 0, 255).color)

    # draw mouse pos
    ctx.fillRect(rect(textBox.mousePos, vec2(4, 4)), rgba(255, 128, 128, 255).color)

    ctx.restoreTransform()

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