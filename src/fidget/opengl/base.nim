import chroma, input, opengl, os, perf, staticglfw, typography/textboxes,
    unicode, vmath

import ../uibase
# if defined(ios) or defined(android):
#   {.fatal: "This module can only be used on desktop windows, macos or linux.".}

var
  window*: staticglfw.Window
  view*: Mat4
  proj*: Mat4
  frameCount* = 0
  clearColor*: Vec4

  drawFrame*: proc()
  running*: bool

  fpsTimeSeries = newTimeSeries()
  avgFrameTime*: float64
  fps*: float64 = 60
  eventHappend*: bool

  multisampling*: int

windowFrame = vec2(2000, 1000)

proc onResize() =
  eventHappend = true
  var cwidth, cheight: cint
  window.getWindowSize(addr cwidth, addr cheight)
  windowSize.x = float(cwidth)
  windowSize.y = float(cheight)

  window.getFramebufferSize(addr cwidth, addr cheight)
  windowFrame.x = float(cwidth)
  windowFrame.y = float(cheight)
  dpi = windowFrame.x / windowSize.x
  glViewport(0, 0, cwidth, cheight)

proc setWindowTitle*(title: string) =
  if window != nil:
    window.setWindowTitle(title)

proc tick*(poll = true) =
  perfMark("--- start frame")

  inc frameCount
  fpsTimeSeries.addTime()
  fps = float(fpsTimeSeries.num())
  avgFrameTime = float(fpsTimeSeries.avg())

  if poll:
    pollEvents()
  perfMark("PollEvents")

  if window.windowShouldClose() != 0:
    running = false

  if windowSize == vec2(0, 0):
    # window is minimized, don't do any drawing
    os.sleep(16)
    return

  if not repaintEveryFrame:
    if not eventHappend:
      # repaintEveryFrame is false
      # so only repain on evnets, event did not happen!
      os.sleep(16)
      return
    else:
      eventHappend = false

  block:
    var x, y: float64
    window.getCursorPos(addr x, addr y)
    mousePos = vec2(x, y)
    mousePos *= dpi
    mouseDelta = mousePos - mousePosPrev
    mousePosPrev = mousePos

  perfMark("pre user draw")

  assert drawFrame != nil
  drawFrame()

  perfMark("user draw")

  mouseWheelDelta = 0
  mouse.click = false
  mouse.rightClick = false

  if glGetError() != GL_NO_ERROR:
    echo "gl error: "

  # reset key and mouse press to default state
  for i in 0..<buttonPress.len:
    buttonPress[i] = false
    buttonRelease[i] = false

  perfMark("pre SwapBuffers")
  window.swapBuffers()
  perfMark("SwapBuffers")

  perfMark("--- end frame")
  prefDump = buttonDown[F10]

proc clearDepthBuffer*() =
  glClear(GL_DEPTH_BUFFER_BIT)

proc clearColorBuffer*(color: Color) =
  glClearColor(color.r, color.g, color.b, color.a)
  glClear(GL_COLOR_BUFFER_BIT)

proc useDepthBuffer*(on: bool) =
  if on:
    glDepthMask(GL_TRUE)
    glEnable(GL_DEPTH_TEST)
  else:
    glDepthMask(GL_FALSE)
    glDisable(GL_DEPTH_TEST)

proc exit*() =
  # cleanup GLFW
  window.destroyWindow()
  terminate()

proc glGetInteger(what: GLenum): int =
  var val: cint
  glGetIntegerv(what, addr val)
  return int val

proc start*() =

  perfMark("start base")

  # init libraries
  if init() == 0:
    quit("Failed to intialize GLFW.")

  perfMark("init glfw")

  running = true

  if multisampling > 0:
    windowHint(SAMPLES, multisampling.cint)

  windowHint(cint OPENGL_FORWARD_COMPAT, cint GL_TRUE)
  windowHint(cint OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  windowHint(cint CONTEXT_VERSION_MAJOR, 4)
  windowHint(cint CONTEXT_VERSION_MINOR, 1)

  # Open a window

  # var monitor = GetPrimaryMonitor()
  # var mode = GetVideoMode(monitor)
  # window = CreateWindow(mode.width, mode.height, uibase.window.innerTitle, monitor, nil)

  perf "open window":
    window = createWindow(cint windowFrame.x, cint windowFrame.y,
        uibase.window.innerTitle, nil, nil)

  if window.isNil:
    quit("Failed to open GLFW window.")

  perf "makeContextCurrent":
    window.makeContextCurrent()
    #window.focusWindow()

  # Load opengl
  when defined(ios) or defined(android):
    # TODO, some thing causes a crash
    #loadExtensions()
    discard
  else:
    perf "loadExtensions":
      loadExtensions()

  # var flags: GLint
  # glGetIntegerv(GL_CONTEXT_FLAGS, addr flags)
  var flags = glGetInteger(GL_CONTEXT_FLAGS)
  if (flags and cast[GLint](GL_CONTEXT_FLAG_DEBUG_BIT)) != 0:
    when defined(glDebugMessageCallback):
      # set up error reporting
      proc printGlDebug(
          source: GLenum,
          typ: GLenum,
          id: GLuint,
          severity: GLenum,
          length: GLsizei,
          message: ptr GLchar,
          userParam: pointer) {.stdcall.} =
        echo "source=" & repr(source) & " type=" & repr(typ) & " id=" & repr(
            id) & " severity=" & repr(severity) & ": " & $message
        if severity != GL_DEBUG_SEVERITY_NOTIFICATION:
          running = false
      glDebugMessageCallback(printGlDebug, nil)
      glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
      glEnable(GL_DEBUG_OUTPUT)

  # Print some info
  echo getVersionString()
  echo "GL_VERSION:", cast[cstring](glGetString(GL_VERSION))
  echo "GL_SHADING_LANGUAGE_VERSION:", cast[cstring](glGetString(GL_SHADING_LANGUAGE_VERSION))

  proc onResize(handle: staticglfw.Window, w, h: int32) {.cdecl.} =
    onResize()
    tick(poll = false)

  discard window.setFramebufferSizeCallback(onResize)
  onResize()

  # proc onRefresh(handle: glfw3.Window) {.cdecl.} =
  #   onResize()
  # discard SetWindowRefreshCallback(window, onRefresh)

  proc onSetKey(window: staticglfw.Window; key: cint; scancode: cint;
      action: cint; modifiers: cint) {.cdecl.} =
    eventHappend = true
    var setKey = action != RELEASE
    keyboard.altKey = setKey and ((modifiers and MOD_ALT) != 0)
    keyboard.ctrlKey = setKey and ((modifiers and MOD_CONTROL) != 0 or (
        modifiers and MOD_SUPER) != 0)
    keyboard.shiftKey = setKey and ((modifiers and MOD_SHIFT) != 0)
    if keyboard.inputFocusIdPath != "":
      keyboard.state = KeyState.Press
      if not setKey: return
      let
        ctrl = keyboard.ctrlKey
        shift = keyboard.shiftKey
      case cast[Button](key):
        of LEFT:
          if ctrl:
            textBox.leftWord(shift)
          else:
            textBox.left(shift)
        of RIGHT:
          if ctrl:
            textBox.rightWord(shift)
          else:
            textBox.right(shift)
        of Button.UP:
          textBox.up(shift)
        of Button.DOWN:
          textBox.down(shift)
        of Button.HOME:
          textBox.startOfLine(shift)
        of Button.END:
          textBox.endOfLine(shift)
        of Button.PAGE_UP:
          textBox.pageUp(shift)
        of Button.PAGE_DOWN:
          textBox.pageDOwn(shift)
        of ENTER:
          #TODO: keyboard.multiline:
          textBox.typeCharacter(Rune(10))
        of BACKSPACE:
          textBox.backspace(shift)
        of DELETE:
          textBox.delete(shift)
        of LETTER_C: # copy
          if ctrl:
            base.window.setClipboardString(textBox.copy())
        of LETTER_V: # paste
          if ctrl:
            textBox.paste($base.window.getClipboardString())
        of LETTER_X: # cut
          if ctrl:
            base.window.setClipboardString(textBox.cut())
        of LETTER_A: # select all
          if ctrl:
            textBox.selectAll()
        else:
          discard
    elif key < buttonDown.len and key >= 0:
      if buttonDown[key] == false and setKey:
        buttonToggle[key] = not buttonToggle[key]
        buttonPress[key] = true
      if buttonDown[key] == true and setKey == false:
        buttonRelease[key] = true
      buttonDown[key] = setKey

  discard window.setKeyCallback(onSetKey)

  proc onScroll(window: staticglfw.Window, xoffset: float64,
      yoffset: float64) {.cdecl.} =
    eventHappend = true
    if keyboard.inputFocusIdPath != "":
      textBox.scrollBy(-yoffset * 50)
    else:
      mouseWheelDelta += yoffset
  discard window.setScrollCallback(onScroll)

  proc onMouseButton(window: staticglfw.Window; button: cint; action: cint;
      modifiers: cint) {.cdecl.} =
    eventHappend = true
    var setKey = action != 0
    let button = button + 1
    mouse.down = setKey
    if button == 1 and setKey:
      mouse.click = true
    if button == 2 and setKey:
      mouse.rightClick = true
    if button < buttonDown.len:
      if buttonDown[button] == false and setKey == true:
        buttonPress[button] = true
      buttonDown[button] = setKey
    if buttonDown[button] == false and setKey == false:
      buttonRelease[button] = true
  discard window.setMouseButtonCallback(onMouseButton)

  proc onMouseMove(window: staticglfw.Window; x, y: cdouble) {.cdecl.} =
    eventHappend = true
  discard window.setCursorPosCallback(onMouseMove)

  proc onSetCharCallback(window: staticglfw.Window; character: cuint) {.cdecl.} =
    eventHappend = true
    if keyboard.inputFocusIdPath != "":
      keyboard.state = KeyState.Press
      textBox.typeCharacter(Rune(character))
    else:
      keyboard.state = KeyState.Press
      # keyboard.altKey = event.altKey
      # keyboard.ctrlKey = event.ctrlKey
      # keyboard.shiftKey = event.shiftKey
      keyboard.keyString = Rune(character).toUTF8()

  discard window.setCharCallback(onSetCharCallback)

  # this does not fire when mouse is not in the window
  # proc onMouseMove(window: glfw3.Window; x: cdouble; y: cdouble) {.cdecl.} =
  #   mousePos.x = x
  #   mousePos.y = y
  # discard SetCursorPosCallback(window, onMouseMove)

  #SetInputMode(window, CURSOR, CURSOR_HIDDEN)

  # enable face culling
  # glEnable(GL_CULL_FACE)
  # glCullFace(GL_BACK)
  # glFrontFace(GL_CCW)

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  #glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA)

  perfMark("end start base")


proc captureMouse*() =
  setInputMode(window, CURSOR, CURSOR_DISABLED)

proc releaseMouse*() =
  setInputMode(window, CURSOR, CURSOR_NORMAL)

proc hideMouse*() =
  setInputMode(window, CURSOR, CURSOR_HIDDEN)
