import ../uibase, chroma, input, opengl, os, perf, staticglfw, times,
    typography/textboxes, unicode, vmath, flippy, strformat, std/monotimes,
    print, ../internal

var
  window*: staticglfw.Window
  dpi*: float32
  view*: Mat4
  proj*: Mat4
  frameCount*, tickCount*: int
  clearColor*: Vec4
  drawFrame*: proc()
  running*, focused*, minimized*: bool
  programStartTime* = epochTime()
  fpsTimeSeries = newTimeSeries()
  tpsTimeSeries = newTimeSeries()
  prevFrameTime* = programStartTime
  frameTime* = prevFrameTime
  dt*, fps*, tps*, avgFrameTime*: float64
  eventHappened*: bool
  multisampling*: int
  lastDraw: int64
  deltaDraw: int64 = 1_000_000_000 div 10
  avgDrawHz: float64
  lastTick: int64
  deltaTick: int64 = 1_000_000_000 div 240
  avgTickHz: float64

proc getTicks(): int64 =
  getMonoTime().ticks

proc updateWindowSize() =
  eventHappened = true

  var cwidth, cheight: cint
  window.getWindowSize(addr cwidth, addr cheight)
  windowSize.x = float32(cwidth)
  windowSize.y = float32(cheight)

  window.getFramebufferSize(addr cwidth, addr cheight)
  windowFrame.x = float32(cwidth)
  windowFrame.y = float32(cheight)

  minimized = windowSize == vec2(0, 0)
  pixelRatio = if windowSize.x > 0: windowFrame.x / windowSize.x else: 0

  glViewport(0, 0, cwidth, cheight)

  let
    monitor = getPrimaryMonitor()
    mode = monitor.getVideoMode()
  monitor.getMonitorPhysicalSize(addr cwidth, addr cheight)
  dpi = mode.width.float32 / (cwidth.float32 / 25.4)

proc onFocus(window: staticglfw.Window, state: cint) {.cdecl.} =
  focused = state == FOCUSED

proc onSetKey(
  window: staticglfw.Window, key, scancode, action, modifiers: cint
) {.cdecl.} =
  eventHappened = true
  let setKey = action != RELEASE
  keyboard.altKey = setKey and ((modifiers and MOD_ALT) != 0)
  keyboard.ctrlKey = setKey and
    ((modifiers and MOD_CONTROL) != 0 or (modifiers and MOD_SUPER) != 0)
  keyboard.shiftKey = setKey and ((modifiers and MOD_SHIFT) != 0)

  if keyboard.inputFocusIdPath != "":
    keyboard.state = KeyState.Press
    if not setKey:
      return

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
        textBox.pageDown(shift)
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

proc onScroll(window: staticglfw.Window, xoffset, yoffset: float64) {.cdecl.} =
  eventHappened = true
  if keyboard.inputFocusIdPath != "":
    textBox.scrollBy(-yoffset * 50)
  else:
    mouseWheelDelta += yoffset

proc onMouseButton(
  window: staticglfw.Window, button, action, modifiers: cint
) {.cdecl.} =
  eventHappened = true
  let
    setKey = action != 0
    button = button + 1
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

proc onMouseMove(window: staticglfw.Window, x, y: cdouble) {.cdecl.} =
  eventHappened = true

proc onSetCharCallback(window: staticglfw.Window, character: cuint) {.cdecl.} =
  eventHappened = true
  if keyboard.inputFocusIdPath != "":
    keyboard.state = KeyState.Press
    textBox.typeCharacter(Rune(character))
  else:
    keyboard.state = KeyState.Press
    # keyboard.altKey = event.altKey
    # keyboard.ctrlKey = event.ctrlKey
    # keyboard.shiftKey = event.shiftKey
    keyboard.keyString = Rune(character).toUTF8()

proc setWindowTitle*(title: string) =
  if window != nil:
    window.setWindowTitle(title)

proc preTick() =
  ## Does input and output operations.
  ## Runs at 240
  var x, y: float64
  window.getCursorPos(addr x, addr y)
  mousePos = vec2(x, y)
  mousePos *= pixelRatio
  mouseDelta = mousePos - mousePosPrev
  mousePosPrev = mousePos

proc postTick() =
  mouseWheelDelta = 0
  mouse.click = false
  mouse.rightClick = false

  # reset key and mouse press to default state
  for i in 0..<buttonPress.len:
    buttonPress[i] = false
    buttonRelease[i] = false

  tpsTimeSeries.addTime()
  tps = float64(tpsTimeSeries.num())

  inc tickCount
  lastTick += deltaTick

proc drawLoop() =
  ## Does drawing operations.
  inc frameCount
  fpsTimeSeries.addTime()
  fps = float64(fpsTimeSeries.num())
  avgFrameTime = fpsTimeSeries.avg()

  frameTime = epochTime()
  dt = frameTime - prevFrameTime
  prevFrameTime = frameTime

  assert drawFrame != nil
  drawFrame()
  var error: GLenum
  while (error = glGetError(); error != GL_NO_ERROR):
    echo "gl error: " & $error.uint32
  window.swapBuffers()
  #swapInterval(2)

proc updateLoop*(poll = true) =
  if window.windowShouldClose() != 0:
    running = false
    return

  case mainLoopMode:
    of CallbackHTML:
      raise newException(ValueError,
        "CallbackHTML not supported in non JS mode")

    of RepaintOnEvent:
      if poll:
        pollEvents()
      if not eventHappened or minimized:
        # so only repaint on events, event did not happen!
        sleep(16)
        return
      preTick()
      if tickMain != nil:
        tickMain()
      drawLoop()
      postTick()
      eventHappened = false

    of RepaintOnFrame:
      if poll:
        pollEvents()
      preTick()
      if tickMain != nil:
        tickMain()
      drawLoop()
      postTick()

    of RepaintSplitUpdate:
      while lastTick < getTicks():
        if poll:
          pollEvents()
        preTick()
        tickMain()
        postTick()
      drawLoop()

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
  ## Cleanup GLFW.
  terminate()

proc glGetInteger(what: GLenum): int =
  var val: cint
  glGetIntegerv(what, addr val)
  return val.int

proc start*(openglVersion: (int, int)) =
  if init() == 0:
    quit("Failed to intialize GLFW.")

  running = true

  if multisampling > 0:
    windowHint(SAMPLES, multisampling.cint)

  windowHint(cint OPENGL_FORWARD_COMPAT, cint GL_TRUE)
  windowHint(cint OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  windowHint(cint CONTEXT_VERSION_MAJOR, cint openglVersion[0])
  windowHint(cint CONTEXT_VERSION_MINOR, cint openglVersion[1])

  if fullscreen:
    let
      monitor = getPrimaryMonitor()
      mode = getVideoMode(monitor)
    window = createWindow(
      mode.width,
      mode.height,
      uibase.window.innerTitle,
      monitor,
      nil
    )
  else:
    window = createWindow(
      cint windowSize.x,
      cint windowSize.y,
      uibase.window.innerTitle,
      nil,
      nil
    )

  if window.isNil:
    quit("Failed to open window.")

  window.makeContextCurrent()

  # Load OpenGL
  when defined(ios) or defined(android):
    # TODO, something causes a crash
    # loadExtensions()
    discard
  else:
    loadExtensions()

  let flags = glGetInteger(GL_CONTEXT_FLAGS)
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
    updateWindowSize()
    updateLoop(poll = false)

  discard window.setFramebufferSizeCallback(onResize)
  discard window.setWindowFocusCallback(onFocus)
  discard window.setKeyCallback(onSetKey)
  discard window.setScrollCallback(onScroll)
  discard window.setMouseButtonCallback(onMouseButton)
  discard window.setCursorPosCallback(onMouseMove)
  discard window.setCharCallback(onSetCharCallback)

  # window.setInputMode(CURSOR, CURSOR_HIDDEN)

  # enable face culling
  # glEnable(GL_CULL_FACE)
  # glCullFace(GL_BACK)
  # glFrontFace(GL_CCW)

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  #glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA)

  lastDraw = getTicks()
  lastTick = getTicks()

  onFocus(window, FOCUSED)
  updateWindowSize()

proc captureMouse*() =
  setInputMode(window, CURSOR, CURSOR_DISABLED)

proc releaseMouse*() =
  setInputMode(window, CURSOR, CURSOR_NORMAL)

proc hideMouse*() =
  setInputMode(window, CURSOR, CURSOR_HIDDEN)
