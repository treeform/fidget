include system/timers
import chroma, glfm, input, opengl, perf, print, sequtils, typography/textboxes,
    unicode, vmath

import ../uibase
var
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

proc tick*(poll = true) =
  perfMark("--- start frame")

  inc frameCount
  fpsTimeSeries.addTime()
  fps = float(fpsTimeSeries.num())
  avgFrameTime = float(fpsTimeSeries.avg())

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
  discard

proc glGetInteger(what: GLenum): int =
  var val: cint
  glGetIntegerv(what, addr val)
  return int val

proc start*() =
  running = true

proc setWindowTitle*(title: string) =
  discard

proc readAssetFile*(filename: string): string =
  let size = int glfmReadFileSize(filename)
  result = newString(size)
  discard glfmReadFileBuffer(filename, result)

type
  ExampleApp* = object
    program*: GLuint
    vertexBuffer*: GLuint
    lastTouchX*: cdouble
    lastTouchY*: cdouble
    offsetX*: cdouble
    offsetY*: cdouble

var app: ExampleApp

proc compileShader*(`type`: GLenum; shaderString: string): GLuint =
  var shader: GLuint = glCreateShader(`type`)
  var shaderTextArr = [cstring(shaderString)]
  echo "glShaderSource..."
  glShaderSource(shader, 1, cast[cstringArray](shaderTextArr.addr), nil)
  echo "glCompileShader..."
  glCompileShader(shader)
  #free(shaderString)
  #  Check compile status

  var status: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, addr(status))
  if status == GLint(GL_FALSE):
    echo "So... Couldn't compile shader"
    var logLength: GLint
    echo "glGetShaderiv GL_INFO_LOG_LENGTH"
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, addr(logLength))
    echo "Log lengh ", logLength
    if logLength > 0:
      var log = newStringOfCap(logLength)
      glGetShaderInfoLog(shader, logLength, addr(logLength), log)
      echo("Shader log: ", log)
    glDeleteShader(shader)
    shader = 0
  return shader

var firstFrame = true
proc onFrame*(display: ptr GLFMDisplay; frameTime: cdouble) {.exportc.} =
  # display screen going from black to white

  if firstFrame:
    firstFrame = false
    # Load opengl
    # loadExtensions()

    # Print some info
    echo "GL_VERSION:", cast[cstring](glGetString(GL_VERSION))
    echo "GL_SHADING_LANGUAGE_VERSION:", cast[cstring](glGetString(GL_SHADING_LANGUAGE_VERSION))
    echo "GL_MAX_TEXTURE_SIZE:", glGetInteger(GL_MAX_TEXTURE_SIZE)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    setupFidget()

    # echo "setup"
    # var vertShader: GLuint = compileShader(GL_VERTEX_SHADER, readAssetFile("simple.vert"))
    # var fragShader: GLuint = compileShader(GL_FRAGMENT_SHADER, readAssetFile("simple.frag"))
    # if vertShader == 0 or fragShader == 0:
    #   glfmSetMainLoopFunc(display, nil)
    #   return
    # app.program = glCreateProgram()
    # glAttachShader(app.program, vertShader)
    # glAttachShader(app.program, fragShader)
    # glBindAttribLocation(app.program, 0, "a_position")
    # glBindAttribLocation(app.program, 1, "a_color")
    # glLinkProgram(app.program)
    # glDeleteShader(vertShader)
    # glDeleteShader(fragShader)
    # echo "setup done"

  var cwidth, cheight: cint
  glfmGetDisplaySize(display, addr cwidth, addr cheight)
  windowSize.x = float(cwidth)
  windowSize.y = float(cheight)

  #GetFramebufferSize(window, addr cwidth, addr cheight)
  windowFrame.x = float(cwidth)
  windowFrame.y = float(cheight)
  dpi = windowFrame.x / windowSize.x
  #glViewport(0, 0, cwidth, cheight)

  glViewport(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y)
  glClearColor(1.0, 0.0, 0.0, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)

  # glUseProgram(app.program)
  # if app.vertexBuffer == 0:
  #   glGenBuffers(1, addr(app.vertexBuffer))
  # glBindBuffer(GL_ARRAY_BUFFER, app.vertexBuffer)
  # var stride: GLsizei = sizeof(GLfloat) * 6
  # glEnableVertexAttribArray(0)
  # glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, stride, cast[pointer](0))
  # glEnableVertexAttribArray(1)
  # glVertexAttribPointer(1, 3, cGL_FLOAT, GL_FALSE, stride, cast[pointer](sizeof(GLfloat) * 3))

  # var vertices = @[
  #   app.offsetX.float32 + 0.0.float32, app.offsetY.float32 + 0.5, 0.0, 1.0, 0.0, 0.0,
  #   app.offsetX.float32 - 0.5.float32, app.offsetY.float32 - 0.5, 0.0, 0.0, 1.0, 0.0,
  #   app.offsetX.float32 + 0.5.float32, app.offsetY.float32 - 0.5, 0.0, 0.0, 0.0, 1.0] ##  x,y,z, r,g,b

  # glBufferData(GL_ARRAY_BUFFER, vertices.len*4, addr(vertices[0]), GL_STATIC_DRAW)
  # glDrawArrays(GL_TRIANGLES, 0, 3)

  drawFrame()

  echo "done frame"

proc NimMain() {.importc.}
proc glfmMain*(display: ptr GLFMDisplay) {.exportc.} =
  glfmSetDisplayConfig(
    display,
    GLFMRenderingAPIOpenGLES2,
    GLFMColorFormatRGBA8888,
    GLFMDepthFormatNone,
    GLFMStencilFormatNone,
    GLFMMultisampleNone
  )
  glfmSetMainLoopFunc(display, onFrame)

  NimMain()

  # test reading a file
  echo readAssetFile("data.txt")
