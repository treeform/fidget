## Flippy backend uses Flippy and glfw3 libarires to provide graphics and input

import chroma, flippy, glfw3 as glfw, math, opengl, os, print, tables, times,
    typography, uibase, unicode, vmath

const GlfwLib = "libglfw.so.3"

var
  ctx: flippy.Image
  frameCount = 0
  window: glfw.Window
  dpi*: float = 1.0
  windowFrame: Box
  viewPort: Box

# readFontSvg("examples/Ubuntu.svg")
#var font = readFontTtf("examples/IBMPlexSans-Regular.ttf")
# font.size = 40
# font.lineHeight = 20

proc hAlignNum(num: int): HAlignMode =
  case num:
    of -1: Left
    of 0: Center
    of 1: Right
    else: Left

proc vAlignNum(num: int): VAlignMode =
  case num:
    of -1: Top
    of 0: Middle
    of 1: Bottom
    else: Top

proc drawText(group: Group) =
  if group.textStyle.fontFamily notin fonts:
    quit "font not found: " & group.textStyle.fontFamily
  var font = fonts[group.textStyle.fontFamily]
  font.size = group.textStyle.fontSize
  font.lineHeight = group.textStyle.lineHeight
  let fontHeight = font.ascent - font.descent
  let scale = font.size / fontHeight
  let editing = keyboard.inputFocusId == group.id
  let cursorWidth = floor(min(1, font.size/12.0))

  if editing:
    group.text = keyboard.input

  let layout = font.typeset(
    group.text,
    pos = group.screenBox.xy,
    size = group.screenBox.wh,
    hAlignNum(group.textStyle.textAlignHorizontal),
    vAlignNum(group.textStyle.textAlignVertical)
  )

  # draw layout boxes
  for pos in layout:
    var font = pos.font
    # if pos.character == "\n":
    #   #print pos.selectRect, pos.index
    #   ctx.strokeRect(pos.selectRect, rgba(0,0,255,255))
    #   let baseLine = pos.selectRect.y + font.ascent * scale
    #   ctx.line(
    #     vec2(pos.selectRect.x, baseLine),
    #     vec2(pos.selectRect.x + pos.selectRect.w, baseLine),
    #     rgba(0,0,255,255)
    #   )

    if pos.character in font.glyphs:
      var glyph = font.glyphs[pos.character]
      var glyphOffset: Vec2
      let img = font.getGlyphImage(
        glyph,
        glyphOffset,
        subPixelShift = pos.subPixelShift
      )
      let r = rect(
          pos.rect.xy + glyphOffset,
          vec2(float img.width, float img.height)
        )
      #ctx.strokeRect(r, rgba(255,0,0,255))
      ctx.blitWithMask(
        img,
        rect(
          0, 0,
          float img.width, float img.height
        ),
        rect(
          pos.rect.x + glyphOffset.x, pos.rect.y + glyphOffset.y,
          float img.width, float img.height
        ),
        group.fill.rgba
      )

    if editing and keyboard.textCursor == pos.index:
      # draw text cursor at glyph pos
      ctx.fillRect(rect(
        pos.selectRect.x,
        pos.selectRect.y,
        cursorWidth,
        font.size
      ), group.fill.rgba)

  # draw text cursor if there is not character
  if editing and keyboard.input.len == 0:
    ctx.fillRect(rect(
      group.screenBox.x,
      group.screenBox.y,
      cursorWidth,
      font.size
    ), group.fill.rgba)
  # draw text cursor at the last character
  elif editing and keyboard.input.len == keyboard.textCursor:
    let pos = layout[^1]
    if pos.character != "\n":
      ctx.fillRect(rect(
        pos.selectRect.x + pos.selectRect.w,
        pos.selectRect.y,
        cursorWidth,
        font.size
      ), group.fill.rgba)
    else:
      ctx.fillRect(rect(
        group.screenBox.x,
        pos.selectRect.y + font.lineHeight,
        cursorWidth,
        font.size
      ), group.fill.rgba)

  if group.text.len > 0 or (group.editableText and group.placeholder.len > 0):
    var text = group.text
    if group.editableText:

      if group.text.len == 0 and group.placeholder.len > 0:
        text = group.placeholder

      if mouse.click and mouse.pos.inside(current.screenBox):
        echo "gain focus"
        keyboard.inputFocusId = group.id
        keyboard.input = group.text
        keyboard.textCursor = keyboard.input.len

        let pos = layout.pickGlyphAt(mouse.pos)
        if pos.character != "":
          keyboard.textCursor = pos.index

        mouse.use()

      if mouse.click and not mouse.pos.inside(current.screenBox):
        echo "loose focus"
        if keyboard.inputFocusId == group.id:
          keyboard.inputFocusId = ""

var imageCache = newTable[string, flippy.Image]()

proc draw*(group: Group) =
  ## Draw a single group

  if group.fill.a > 0:
    if group.kind == "text":
      drawText(group)
    else:
      if group.imageName == "":
        ctx.fillRect(rect(
          group.screenBox.x, group.screenBox.y,
          group.screenBox.w, group.screenBox.h
        ), group.fill.rgba)

  if group.imageName != "":
    if group.imageName notin imageCache:
      echo "load ", group.imageName
      imageCache[group.imageName] = loadImage("data/" & group.imageName & ".png")
    let image = imageCache[group.imageName]
    #ctx.blitWithAlpha(image, translate(vec3(group.screenBox.x, group.screenBox.y, 0)))
    ctx.blitWithAlpha(
      image,
      translate(vec3(group.screenBox.x, group.screenBox.y, 0))
    )

proc redraw*() =
  ## Request the screen to be redrawn next
  if not requestedFrame:
    requestedFrame = true

proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard

proc goto*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  discard

proc display() =
  ## Called every frame by main while loop
  setupRoot()

  root.box.x = float 0
  root.box.y = float 0
  root.box.w = windowFrame.w
  root.box.h = windowFrame.h

  scrollBox.x = float 0
  scrollBox.y = float 0
  scrollBox.w = root.box.w
  scrollBox.h = root.box.h

  ctx.fill(color(1, 1, 1, 1).rgba)

  drawMain()

  # update texture with new pixels from ctx
  let
    dataPtr = addr ctx.data[0]
    w = ctx.width
    h = ctx.height

  # openGL way
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGBA,
      GL_UNSIGNED_BYTE, dataPtr)
  # draw a quad over the whole screen
  glClear(GL_COLOR_BUFFER_BIT)
  glBegin(GL_QUADS)
  glTexCoord2d(0.0, 0.0)
  glVertex2d(-1.0, +1.0)
  glTexCoord2d(viewPort.w/float(w), 0.0)
  glVertex2d(+1.0, +1.0)
  glTexCoord2d(viewPort.w/float(w), viewPort.h/float(h))
  glVertex2d(+1.0, -1.0)
  glTexCoord2d(0.0, viewPort.h/float(h))
  glVertex2d(-1.0, -1.0)
  glEnd()
  glfw.SwapBuffers(window)

  keyboard.use()
  mouse.use()

  inc frameCount

proc closestPowerOf2(v: int): int =
  ## returns closets power of 2 ... 2,4,8,16... that is higher then v
  result = 2
  while true:
    if v < result:
      return
    result *= 2

proc resize() =
  var cwidth, cheight: cint
  GetWindowSize(window, addr cwidth, addr cheight)
  windowFrame.w = float(cwidth)
  windowFrame.h = float(cheight)

  GetFramebufferSize(window, addr cwidth, addr cheight)
  viewPort.w = float(cwidth)
  viewPort.h = float(cheight)
  dpi = viewPort.w / windowFrame.w

  glViewport(0, 0, cwidth, cheight)

  var
    w = closestPowerOf2(int viewPort.w)
    h = closestPowerOf2(int viewPort.h)
  if ctx == nil or w > ctx.width or h > ctx.height:
    # need to resize and re inint everything
    ctx = newImage(w, h, 4)

    # allocate a texture and bind it
    var dataPtr = addr ctx.data[0]
    glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGBA,
        GL_UNSIGNED_BYTE, dataPtr)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
    glEnable(GL_TEXTURE_2D)

proc onResize(handle: glfw.Window, w, h: int32) {.cdecl.} =
  resize()
  display()

proc onMouseButton(
  window: glfw.Window,
  button, action, modifiers: cint
) {.cdecl.} =
  if action == 0:
    mouse.down = false
    mouse.click = false
  else:
    mouse.click = true
    mouse.down = true
  # let button = button + 1
  # if button < buttonDown.len:
  #   if buttonDown[button] == false and setKey == true:
  #     buttonPress[button] = true
  #   buttonDown[button] = setKey
  redraw()

proc onMouseMove(window: glfw.Window, x, y: cdouble) {.cdecl.} =
  # this does not fire when mouse is not in the window
  mouse.pos = vec2(x, y) * dpi
  redraw()

proc `title=`*(win: uibase.Window, title: string) =
  if win.innerTitle != title:
    win.innerTitle = title
    window.SetWindowTitle(title)

proc `title`*(win: uibase.Window): string =
  win.innerTitle

proc startFidget*(draw: proc()) =
  ## Starts the flippy backend.
  drawMain = draw
  if glfw.Init() == 0:
    quit("Failed to Initialize GLFW")
  window = glfw.CreateWindow(
    1000,
    800,
    "Fidget glfw/cairo backend window.",
    nil,
    nil
  )
  glfw.MakeContextCurrent(window)

  loadExtensions()

  glfw.PollEvents()
  resize()

  discard SetCursorPosCallback(window, onMouseMove)
  discard SetMouseButtonCallback(window, onMouseButton)
  discard SetFramebufferSizeCallback(window, onResize)
  proc onCharCallback(window: glfw.Window, character: cuint) {.cdecl.} =
    keyboard.state = uibase.Press
    keyboard.keyString = $Rune(character)

    if keyboard.inputFocusId != "":
      keyboard.input[keyboard.textCursor..<keyboard.textCursor] = keyboard.keyString
      inc keyboard.textCursor

    redraw()
  discard SetCharCallback(window, onCharCallback)

  proc onKeyCallback(
    window: glfw.Window,
    key, scancode, action, modifiers: cint
  ) {.cdecl.} =
    if action == 1:
      keyboard.state = uibase.Down
    elif action == 0:
      keyboard.state = uibase.Up
    elif action == 2:
      keyboard.state = uibase.Repeat
    else:
      return
    keyboard.keyCode = key
    keyboard.scanCode = scancode
    keyboard.altKey = (modifiers and glfw.MOD_ALT) != 0
    keyboard.ctrlKey = (modifiers and glfw.MOD_CONTROL) != 0
    keyboard.shiftKey = (modifiers and glfw.MOD_SHIFT) != 0
    keyboard.superKey = (modifiers and glfw.MOD_SUPER) != 0

    if keyboard.inputFocusId != "":
      if keyboard.state in {uibase.Down, uibase.Repeat}:
        let key = keyboard.keyCode
        if key == KEY_BACKSPACE:
          if keyboard.textCursor != 0:
            dec keyboard.textCursor
            keyboard.input[keyboard.textCursor..keyboard.textCursor] = ""

        if key == KEY_DELETE:
          if keyboard.textCursor != keyboard.input.len:
            keyboard.input[keyboard.textCursor..keyboard.textCursor] = ""

        if key == KEY_ENTER:
          keyboard.input[keyboard.textCursor..<keyboard.textCursor] = "\n"
          inc keyboard.textCursor

        if key == KEY_LEFT:
          keyboard.textCursor = max(keyboard.textCursor - 1, 0)

        if key == KEY_RIGHT:
          keyboard.textCursor = min(keyboard.textCursor + 1, keyboard.input.len)

    redraw()
  discard SetKeyCallback(window, onKeyCallback)

  requestedFrame = true

  while glfw.WindowShouldClose(window) == 0:
    glfw.PollEvents()

    if requestedFrame:
      requestedFrame = false
      display()
    else:
      sleep(1)

    # reset one off events
    mouse.click = false
