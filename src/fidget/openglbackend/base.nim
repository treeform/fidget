include system/timers
import unicode, sequtils
import chroma, opengl, vmath, print, input, perf, typography/textboxes
import glfw

import ../uibase

# if defined(ios) or defined(android):
#   {.fatal: "This module can only be used on desktop windows, macos or linux.".}

var
  window*: glfw.Window
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

windowFrame = vec2(2000, 1000)

proc onResize() =
  var (cwidth, cheight) = window.size
  windowSize.x = float(cwidth)
  windowSize.y = float(cheight)

  (cwidth, cheight) = window.framebufferSize
  windowFrame.x = float(cwidth)
  windowFrame.y = float(cheight)
  dpi = windowFrame.x / windowSize.x
  glViewport(0, 0, cwidth, cheight)


proc setWindowTitle*(title: string) =
  if window != nil:
    window.title = title


proc tick*(poll=true) =
  perfMark("--- start frame")

  inc frameCount
  fpsTimeSeries.addTime()
  fps = float(fpsTimeSeries.num())
  avgFrameTime = float(fpsTimeSeries.avg())

  if poll:
    pollEvents()
  perfMark("PollEvents")

  if window.shouldClose:
    running = false

  if windowSize == vec2(0, 0):
    # window is minimized, don't do any drawing
    return

  block:
    var (x, y) = window.cursorPos
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
  window.swapBuffers()
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
  window.destroy()
  glfw.terminate()


proc glGetInteger(what: GLenum): int =
  var val: cint
  glGetIntegerv(what, addr val)
  return int val

proc start*() =

  perfMark("start base")

  # init libraries
  glfw.initialize()

  perfMark("init glfw")

  running = true

  #WindowHint(SAMPLES, 32)

  # glfw.windowHint(cint OPENGL_FORWARD_COMPAT, cint GL_TRUE)
  # glfw.windowHint(cint OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  # glfw.windowHint(cint CONTEXT_VERSION_MAJOR, 4)
  # glfw.windowHint(cint CONTEXT_VERSION_MINOR, 1)

  # Open a window
  perfMark("start open window")


  # var monitor = GetPrimaryMonitor()
  # var mode = GetVideoMode(monitor)
  # window = CreateWindow(mode.width, mode.height, uibase.window.innerTitle, monitor, nil)

  let cfg = OpenglWindowConfig(
    size: (cint windowFrame.x, cint windowFrame.y),
    title: uibase.window.innerTitle,
    forwardCompat: true,
    profile: opCoreProfile,
    version: glv41
  )

  window = newWindow(cfg) #cint windowFrame.x, cint windowFrame.y, uibase.window.innerTitle, nil, nil)
  perfMark("open window")

  if window.isNil:
    quit("Failed to open GLFW window.")

  window.makeContextCurrent()
  #FocusWindow(window)

  # view = mat4()
  # view.pos = vec3(0.0, 0.0, -10.0)
  # proj = perspective(160, 800.0/800.0, 0.0001, 100.0)

  # Load opengl
  when defined(ios) or defined(android):
    # TODO, some thing causes a crash
    #loadExtensions()
    discard
  else:
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
  echo "GFLW_VERSION:", versionString()
  echo "GL_VERSION:", cast[cstring](glGetString(GL_VERSION))
  echo "GL_SHADING_LANGUAGE_VERSION:", cast[cstring](glGetString(GL_SHADING_LANGUAGE_VERSION))

  window.framebufferSizeCb = proc(window: glfw.Window, res: tuple[w, h: int32]) {.closure.} =
    onResize()
    tick(poll = false)

  #discard SetFramebufferSizeCallback(window, onResize)
  #onResize()

  # proc onRefresh(handle: glfw.Window) {.cdecl.} =
  #   onResize()
  # discard SetWindowRefreshCallback(window, onRefresh)

  window.keyCb = proc(
      window: glfw.Window,
      key: Key,
      scanCode: int32,
      action: KeyAction,
      modKeys: set[ModifierKey]
    ) {.closure.} =
    let setKey = action != kaUp
    let keyScanCode = scanCode(key)
    keyboard.altKey = setKey and mkAlt in modKeys
    keyboard.ctrlKey = setKey and (mkCtrl in modKeys or mkSuper in modKeys)
    keyboard.shiftKey = setKey and mkShift in modKeys
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
            base.window.clipboardString = textBox.copy()
        of LETTER_V: # paste
          if ctrl:
            textBox.paste($base.window.clipboardString)
        of LETTER_X: # cut
          if ctrl:
            base.window.clipboardString = textBox.cut()
        of LETTER_A: # select all
          if ctrl:
            textBox.selectAll()
        else:
          discard
    elif keyScanCode < buttonDown.len:
      if buttonDown[keyScanCode] == false and setKey:
        buttonToggle[keyScanCode] = not buttonToggle[keyScanCode]
        buttonPress[keyScanCode] = true
      if buttonDown[keyScanCode] == false and setKey == false:
        buttonUp[keyScanCode] = true
      buttonDown[keyScanCode] = setKey

  window.scrollCb = proc(window: glfw.Window, offset: tuple[x, y: float64]) {.closure.} =
    if keyboard.inputFocusIdPath != "":
      textBox.scrollBy(-offset[1] * 50)
    else:
      mouseWheelDelta += offset[1]

  window.mouseButtonCb = proc(window: glfw.Window, button: MouseButton, pressed: bool,
    modKeys: set[ModifierKey]) {.closure.} =
    var setKey = pressed
    let buttonCode = ord(button)
    let button = buttonCode + 1
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
      buttonUp[button] = true

  window.charCb = proc(window: glfw.Window, codePoint: Rune) {.closure.} =
    if keyboard.inputFocusIdPath != "":
      keyboard.state = KeyState.Press
      textBox.typeCharacter(codePoint)
    else:
      keyboard.state = KeyState.Press
      # keyboard.altKey = event.altKey
      # keyboard.ctrlKey = event.ctrlKey
      # keyboard.shiftKey = event.shiftKey
      keyboard.keyString = codePoint.toUTF8()


  # this does not fire when mouse is not in the window
  # proc onMouseMove(window: glfw.Window; x: cdouble; y: cdouble) {.cdecl.} =
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
