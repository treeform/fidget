import ../uibase, chroma, input, opengl, os, perf, staticglfw, times,
    typography/textboxes, unicode, vmath, perf, ../internal

when defined(glDebugMessageCallback):
  import strformat, strutils

type
  MSAA* = enum
    msaaDisabled, msaa2x = 2, msaa4x = 4, msaa8x = 8

  MainLoopMode* = enum
    ## Only repaints on event
    ## Used for normal for desktop UI apps.
    RepaintOnEvent

    ## Repaints every frame (60hz or more based on display)
    ## Updates are done every matching frame time.
    ## Used for simple multimedia apps and games.
    RepaintOnFrame

    ## Repaints every frame (60hz or more based on display)
    ## But calls the tick function for keyboard and mouse updates at 240hz
    ## Used for low latency games.
    RepaintSplitUpdate

const
  deltaTick: int64 = 1_000_000_000 div 240

var
  window: staticglfw.Window
  loopMode: MainLoopMode
  dpi*: float32
  drawFrame*: proc()
  running*, focused*, minimized*: bool
  programStartTime* = epochTime()
  fpsTimeSeries = newTimeSeries()
  tpsTimeSeries = newTimeSeries()
  prevFrameTime* = programStartTime
  frameTime* = prevFrameTime
  dt*, fps*, tps*, avgFrameTime*: float64
  frameCount*, tickCount*: int
  lastDraw, lastTick: int64
  view*: Mat4
  proj*: Mat4

proc updateWindowSize() =
  requestedFrame = true

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

proc setWindowTitle*(title: string) =
  if window != nil:
    window.setWindowTitle(title)

proc preTick() =
  ## Does input and output operations.
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

  # Reset key and mouse press to default state
  for i in 0..<buttonPress.len:
    buttonPress[i] = false
    buttonRelease[i] = false

  tpsTimeSeries.addTime()
  tps = float64(tpsTimeSeries.num())

  inc tickCount
  lastTick += deltaTick

proc drawAndSwap() =
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

proc updateLoop*(poll = true) =
  if window.windowShouldClose() != 0:
    running = false
    return

  case loopMode:
    of RepaintOnEvent:
      if poll:
        pollEvents()
      if not requestedFrame or minimized:
        # Only repaint when necessary
        sleep(16)
        return
      preTick()
      if tickMain != nil:
        tickMain()
      drawAndSwap()
      postTick()
      requestedFrame = false

    of RepaintOnFrame:
      if poll:
        pollEvents()
      preTick()
      if tickMain != nil:
        tickMain()
      drawAndSwap()
      postTick()

    of RepaintSplitUpdate:
      while lastTick < getTicks():
        if poll:
          pollEvents()
        preTick()
        tickMain()
        postTick()
      drawAndSwap()

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

proc glGetInteger*(what: GLenum): int =
  var val: GLint
  glGetIntegerv(what, val.addr)
  return val.int

proc onResize(handle: staticglfw.Window, w, h: int32) {.cdecl.} =
  updateWindowSize()
  updateLoop(poll = false)

proc onFocus(window: staticglfw.Window, state: cint) {.cdecl.} =
  focused = state == FOCUSED

proc onSetKey(
  window: staticglfw.Window, key, scancode, action, modifiers: cint
) {.cdecl.} =
  requestedFrame = true
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
  requestedFrame = true
  if keyboard.inputFocusIdPath != "":
    textBox.scrollBy(-yoffset * 50)
  else:
    mouseWheelDelta += yoffset

proc onMouseButton(
  window: staticglfw.Window, button, action, modifiers: cint
) {.cdecl.} =
  requestedFrame = true
  let
    setKey = action != 0
    button = button + 1 # Fidget mouse buttons are +1 from staticglfw
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
  requestedFrame = true

proc onSetCharCallback(window: staticglfw.Window, character: cuint) {.cdecl.} =
  requestedFrame = true
  if keyboard.inputFocusIdPath != "":
    keyboard.state = KeyState.Press
    textBox.typeCharacter(Rune(character))
  else:
    keyboard.state = KeyState.Press
    # keyboard.altKey = event.altKey
    # keyboard.ctrlKey = event.ctrlKey
    # keyboard.shiftKey = event.shiftKey
    keyboard.keyString = Rune(character).toUTF8()

proc start*(openglVersion: (int, int), msaa: MSAA, mainLoopMode: MainLoopMode) =
  if init() == 0:
    quit("Failed to intialize GLFW.")

  running = true
  loopMode = mainLoopMode

  if msaa != msaaDisabled:
    windowHint(SAMPLES, msaa.cint)

  windowHint(OPENGL_FORWARD_COMPAT, GL_TRUE.cint)
  windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  windowHint(CONTEXT_VERSION_MAJOR, openglVersion[0].cint)
  windowHint(CONTEXT_VERSION_MINOR, openglVersion[1].cint)

  if fullscreen:
    let
      monitor = getPrimaryMonitor()
      mode = getVideoMode(monitor)
    window = createWindow(mode.width, mode.height, "", monitor, nil)
  else:
    window = createWindow(windowSize.x.cint, windowSize.y.cint, "", nil, nil)

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

  when defined(glDebugMessageCallback):
    let flags = glGetInteger(GL_CONTEXT_FLAGS)
    if (flags and GL_CONTEXT_FLAG_DEBUG_BIT.GLint) != 0:
      # Set up error logging
      proc printGlDebug(
        source, typ: GLenum,
        id: GLuint,
        severity: GLenum,
        length: GLsizei,
        message: ptr GLchar,
        userParam: pointer
      ) {.stdcall.} =
        echo &"source={toHex(source.uint32)} type={toHex(typ.uint32)} " &
          &"id={id} severity={toHex(severity.uint32)}: {$message}"
        if severity != GL_DEBUG_SEVERITY_NOTIFICATION:
          running = false

      glDebugMessageCallback(printGlDebug, nil)
      glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
      glEnable(GL_DEBUG_OUTPUT)

  echo getVersionString()
  echo "GL_VERSION:", cast[cstring](glGetString(GL_VERSION))
  echo "GL_SHADING_LANGUAGE_VERSION:",
    cast[cstring](glGetString(GL_SHADING_LANGUAGE_VERSION))

  discard window.setFramebufferSizeCallback(onResize)
  discard window.setWindowFocusCallback(onFocus)
  discard window.setKeyCallback(onSetKey)
  discard window.setScrollCallback(onScroll)
  discard window.setMouseButtonCallback(onMouseButton)
  discard window.setCursorPosCallback(onMouseMove)
  discard window.setCharCallback(onSetCharCallback)

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  lastDraw = getTicks()
  lastTick = lastDraw

  onFocus(window, FOCUSED)
  updateWindowSize()

proc captureMouse*() =
  setInputMode(window, CURSOR, CURSOR_DISABLED)

proc releaseMouse*() =
  setInputMode(window, CURSOR, CURSOR_NORMAL)

proc hideMouse*() =
  setInputMode(window, CURSOR, CURSOR_HIDDEN)
