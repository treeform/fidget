include system/timers
import unicode
import chroma, opengl, glfw3, vmath, print, input, perf
import ../uibase

var
  window*: glfw3.Window
  view*: Mat4
  proj*: Mat4
  windowSize*: Vec2
  windowFrame*: Vec2
  dpi*: float
  frameCount* = 0
  clearColor*: Vec4

  drawFrame*: proc()
  running*: bool

  fpsTimeSeries = newTimeSeries()
  avgFrameTime*: float64
  fps*: float64 = 60


proc onResize() =
  var cwidth, cheight: cint
  GetWindowSize(window, addr cwidth, addr cheight)
  windowSize.x = float(cwidth)
  windowSize.y = float(cheight)

  GetFramebufferSize(window, addr cwidth, addr cheight)
  windowFrame.x = float(cwidth)
  windowFrame.y = float(cheight)
  dpi = windowFrame.x / windowSize.x
  glViewport(0, 0, cwidth, cheight)


proc setWindowTitle*(title: string) =
  window.SetWindowTitle(title)


proc tick*() =
  perfMark("--- start frame")

  inc frameCount
  fpsTimeSeries.addTime()
  fps = float(fpsTimeSeries.num())
  avgFrameTime = float(fpsTimeSeries.avg())

  PollEvents()
  perfMark("PollEvents")

  if glfw3.WindowShouldClose(window) != 0:
    running = false

  block:
    var x, y: float64
    GetCursorPos(window, addr x, addr y)
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
    buttonUp[i] = false

  perfMark("pre SwapBuffers")
  SwapBuffers(window)
  perfMark("SwapBuffers")

  perfMark("--- end frame")
  prefDump = buttonDown[F10]


proc clearDepthBuffer*() =
  glClear(GL_DEPTH_BUFFER_BIT)

proc clearColorBuffer*(color: Color) =
  glCLearColor(color.r, color.g, color.b, color.a)
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
  DestroyWindow(window)
  Terminate()


proc glGetInteger(what: GLenum): int =
  var val: cint
  glGetIntegerv(what, addr val)
  return int val

proc start*() =

  perfMark("start base")

  # init libraries
  if Init() == 0:
    quit("Failed to intialize GLFW.")

  perfMark("init glfw")

  running = true

  #WindowHint(SAMPLES, 32)

  glfw3.WindowHint(cint OPENGL_FORWARD_COMPAT, cint GL_TRUE)
  glfw3.WindowHint(cint OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  glfw3.WindowHint(cint CONTEXT_VERSION_MAJOR, 4)
  glfw3.WindowHint(cint CONTEXT_VERSION_MINOR, 1)

  # Open a window
  perfMark("start open window")
  #window = CreateWindow(1920, 1080, windowTitle, nil, nil)
  window = CreateWindow(2000, 1000, uibase.window.innerTitle, nil, nil)
  perfMark("open window")

  if window.isNil:
    quit("Failed to open GLFW window.")

  MakeContextCurrent(window)
  #FocusWindow(window)

  view = mat4()
  view.pos = vec3(0.0, 0.0, -10.0)
  proj = perspective(160, 800.0/800.0, 0.0001, 100.0)

  # Load opengl
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
        echo "source=" & repr(source) & " type=" & repr(typ) & " id=" & repr(id) & " severity=" & repr(severity) & ": " & $message
        if severity != GL_DEBUG_SEVERITY_NOTIFICATION:
          running = false
      glDebugMessageCallback(printGlDebug, nil)
      glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
      glEnable(GL_DEBUG_OUTPUT)

  # Print some info
  echo GetVersionString()
  echo "GL_VERSION:", cast[cstring](glGetString(GL_VERSION))
  echo "GL_SHADING_LANGUAGE_VERSION:", cast[cstring](glGetString(GL_SHADING_LANGUAGE_VERSION))

  proc onResize(handle: glfw3.Window, w, h: int32) {.cdecl.} =
    onResize()
    tick()
  discard SetFramebufferSizeCallback(window, onResize)
  onResize()

  # proc onRefresh(handle: glfw3.Window) {.cdecl.} =
  #   onResize()
  # discard SetWindowRefreshCallback(window, onRefresh)

  proc onSetKey(window: glfw3.Window; key: cint; scancode: cint; action: cint; modifiers: cint) {.cdecl.} =
    var setKey = action != 0
    if typingMode and setKey:
      case cast[Button](key):
        of ENTER:
          typingRunes.add(Rune(10))
        of BACKSPACE:
          if typingRunes.len > 0:
            typingRunes.setLen(typingRunes.len-1)
        else:
          discard
      typingText = $typingRunes
    elif key < buttonDown.len:
      if buttonDown[key] == false and setKey:
        buttonToggle[key] = not buttonToggle[key]
        buttonPress[key] = true
      if buttonDown[key] == false and setKey == false:
        buttonUp[key] = true
      buttonDown[key] = setKey
      keyboard.altKey = setKey and ((modifiers and MOD_ALT) != 0)
      keyboard.ctrlKey = setKey and ((modifiers and MOD_CONTROL) != 0 or (modifiers and MOD_SUPER) != 0)
      keyboard.shiftKey = setKey and ((modifiers and MOD_SHIFT) != 0)

  discard SetKeyCallback(window, onSetKey)

  proc onScroll(window: glfw3.Window, xoffset: float64, yoffset: float64) {.cdecl.} =
    mouseWheelDelta += yoffset
  discard SetScrollCallback(window, onScroll)

  proc onMouseButton(window: glfw3.Window; button: cint; action: cint; modifiers: cint) {.cdecl.} =
    var setKey = action != 0
    let button = button + 1
    if button == 1 and setKey:
      mouse.click = true
    if button == 2 and setKey:
      mouse.rightClick = true
    if button < buttonDown.len:
      if buttonDown[button] == false and setKey == true:
        buttonPress[button] = true
      buttonDown[button] = setKey
    if buttonDown[button] == false and setKey == false:
      buttonUp[button] = true
  discard SetMouseButtonCallback(window, onMouseButton)

  proc onSetCharCallback(window: glfw3.Window; character: cuint) {.cdecl.} =
    if typingMode:
      print character
      typingRunes.add Rune(character)
      print typingText
      typingText = $typingRunes

    keyboard.state = KeyState.Press
    # keyboard.altKey = event.altKey
    # keyboard.ctrlKey = event.ctrlKey
    # keyboard.shiftKey = event.shiftKey
    keyboard.keyString = Rune(character).toUTF8()

  discard SetCharCallback(window, onSetCharCallback)

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
