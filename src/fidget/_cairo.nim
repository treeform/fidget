## Cairo backend uses Cairo and glfw3 libarires to provide graphics and input

import chroma, glfw3 as glfw, math, opengl, os, print, quickcairo, random,
    times, common, unicode, vmath

when defined(Windows):
  import windows
  proc GetWin32Window*(window: glfw.Window): pointer {.cdecl,
      importc: "glfwGetWin32Window", dynlib: "glfw3.dll".}
else:
  const GlfwLib = "libglfw.so.3"

var
  surface: Surface
  ctx: quickcairo.Context
  frameCount = 0
  window: glfw.Window
  dpi*: float = 1.0
  windowFrame: Box
  viewPort: Box

proc setSource(ctx: quickcairo.Context, color: Color) =
  ctx.setSource(
    color.r,
    color.g,
    color.b,
    color.a
  )

proc rectangle(ctx: quickcairo.Context, box: Box) =
  ctx.rectangle(
    floor box.x,
    floor box.y,
    floor box.w,
    floor box.h
  )

proc draw*(group: Group) =
  ## Redraws the whole screen
  if group.fill.a > 0:

    if group.kind == "text":
      if group.text.len > 0 or (group.editableText and group.placeholder.len > 0):
        var text = group.text
        if group.editableText:

          if group.text.len == 0 and group.placeholder.len > 0:
            text = group.placeholder

          if mouse.click and mouse.pos.inside(current.screenBox):
            echo "gain focus"
            keyboard.inputFocusId = group.id
            keyboard.input = group.text
            mouse.use()

          if mouse.click and not mouse.pos.inside(current.screenBox):
            echo "loose focus"
            if keyboard.inputFocusId == group.id:
              keyboard.inputFocusId = ""

        ctx.selectFontFace(group.textStyle.fontFamily, FONT_SLANT.normal,
            FONT_WEIGHT.normal)
        ctx.setFontSize(group.textStyle.fontSize)
        ctx.setSource(group.fill)
        var extents = TextExtents()
        ctx.textExtents(text, extents)

        var fontExtents = FontExtents()
        ctx.fontExtents(fontExtents)
        let capHeight = fontExtents.ascent - fontExtents.descent
        print fontExtents
        var x, y: float

        case group.textStyle.textAlignHorizontal:
          of -1:
            x = group.screenBox.x
          of 0:
            x = group.screenBox.x + group.screenBox.w/2 - float(extents.width)/2
          of 1:
            x = group.screenBox.x + group.screenBox.w - extents.width
          else:
            x = 0
        case group.textStyle.textAlignVertical:
          of -1:
            y = group.screenBox.y + fontExtents.ascent
          of 0:
            y = group.screenBox.y + group.screenBox.h/2 + float(capHeight)/2
          of 1:
            y = group.screenBox.y + group.screenBox.h - fontExtents.descent
          else:
            y = 0
        ctx.moveTo(x, y)
        ctx.showText(text)

        ctx.rectangle(Box(x: x, y: y, w: 4, h: 4))
        ctx.setSource(color(1, 0, 0, 1))
        ctx.stroke()

    else:
      ctx.rectangle(group.screenBox)
      ctx.setSource(group.fill)
      ctx.fill()

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

  ctx.rectangle(root.box)
  ctx.setSource(color(1, 1, 1, 1))
  ctx.fill()

  drawMain()

  # update texture with new pixels from surface
  let
    dataPtr = surface.imageSurfaceGetData()
    w = surface.width
    h = surface.height

  when defined(windows):
    # draw image serface onto window
    var hwnd = cast[HWND](GetWin32Window(window))
    var dc = GetDC(hwnd)
    var info = BITMAPINFO()
    info.bmiHeader.biBitCount = 32
    info.bmiHeader.biWidth = int32 w
    info.bmiHeader.biHeight = int32 h
    info.bmiHeader.biPlanes = 1
    info.bmiHeader.biSize = DWORD sizeof(BITMAPINFOHEADER)
    info.bmiHeader.biSizeImage = int32(w * h * 4)
    info.bmiHeader.biCompression = BI_RGB
    discard StretchDIBits(dc, 0, int32 h - 1, int32 w, int32 -h, 0, 0, int32 w,
        int32 h, dataPtr, info, DIB_RGB_COLORS, SRCCOPY)
    discard ReleaseDC(hwnd, dc)
  else:
    # openGL way
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_BGRA,
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

  when defined(windows):
    discard
  else:
    glViewport(0, 0, cwidth, cheight)

  var
    w = closestPowerOf2(int viewPort.w)
    h = closestPowerOf2(int viewPort.h)
  if surface == nil or w > surface.width or h > surface.height:
    # need to resize and re inint everything
    surface = imageSurfaceCreate(FORMAT.rgb24, w, h)
    ctx = surface.newContext()

    # allocate a texture and bind it
    var dataPtr = surface.imageSurfaceGetData()
    when defined(windows):
      discard
    else:
      glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_BGRA,
          GL_UNSIGNED_BYTE, dataPtr)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
      glEnable(GL_TEXTURE_2D)

proc onResize(handle: glfw.Window, w, h: int32) {.cdecl.} =
  resize()
  display()

proc onMouseButton(window: glfw.Window, button: cint, action: cint,
    modifiers: cint) {.cdecl.} =
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

proc onMouseMove(window: glfw.Window, x: cdouble, y: cdouble) {.cdecl.} =
  # this does not fire when mouse is not in the window
  mouse.pos = vec2(x, y) * dpi
  redraw()

proc `title=`*(win: common.Window, title: string) =
  if win.innerTitle != title:
    win.innerTitle = title
    window.SetWindowTitle(title)

proc `title`*(win: common.Window): string =
  win.innerTitle

proc startFidget*(draw: proc()) =
  ## Starts cairo backend.
  drawMain = draw
  if glfw.Init() == 0:
    quit("Failed to Initialize GLFW")
  window = glfw.CreateWindow(1000, 800, "Fidget glfw/cairo backend window.",
      nil, nil)
  glfw.MakeContextCurrent(window)

  when defined(windows):
    discard
  else:
    loadExtensions()

  glfw.PollEvents()
  resize()

  discard SetCursorPosCallback(window, onMouseMove)
  discard SetMouseButtonCallback(window, onMouseButton)
  discard SetFramebufferSizeCallback(window, onResize)
  proc onCharCallback(window: glfw.Window, character: cuint) {.cdecl.} =
    keyboard.state = common.Press
    keyboard.keyString = $Rune(character)
    echo "keyboard.keyString", repr(keyboard.keyString)
    keyboard.input.add keyboard.keyString
    echo keyboard.input
    redraw()
  discard SetCharCallback(window, onCharCallback)

  proc onKeyCallback(
    window: glfw.Window,
    key: cint,
    scancode: cint,
    action: cint,
    modifiers: cint
  ) {.cdecl.} =
    echo "keyboard.key ", key, " action ", action
    #keyboard.input.add keyboard.keyString
    #echo keyboard.input
    if keyboard.inputFocusId != "" and action != 0:
      if key == KEY_BACKSPACE:
        keyboard.state = common.Press
        keyboard.keyString = ""
        if keyboard.input.len > 0:
          keyboard.input.setLen(keyboard.input.len - 1)
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
