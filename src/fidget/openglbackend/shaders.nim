import opengl


proc getShaderLog(shader: GLuint): string =
  var length: GLint = 0
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, length.addr)
  var log = newString(length.int)
  glGetShaderInfoLog(shader, length, nil, log)
  return log

proc compileShaderFiles*(vertShaderSrc: string, fragShaderSrc: string): GLuint =
  var vertShader, fragShader: GLuint

  # Compile the shaders
  block shaders:
    var vertShaderArray = allocCStringArray([vertShaderSrc])
    var fragShaderArray = allocCStringArray([fragShaderSrc])

    defer:
      dealloc(vertShaderArray)
      dealloc(fragShaderArray)

    var isCompiled: GLint

    vertShader = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertShader, 1, vertShaderArray, nil)
    glCompileShader(vertShader)
    glGetShaderiv(vertShader, GL_COMPILE_STATUS, isCompiled.addr)

    if isCompiled == 0:
      echo vertShaderSrc
      echo "Vertex shader compilation failed:"
      echo getShaderLog(vertShader)
      quit()

    fragShader = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragShader, 1, fragShaderArray, nil)
    glCompileShader(fragShader)
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, isCompiled.addr)

    if isCompiled == 0:
      echo fragShaderSrc
      echo "Fragment shader compilation failed:"
      echo getShaderLog(fragShader)
      quit()

  # Attach shaders to a GL program
  var program = glCreateProgram()
  glAttachShader(program, vertShader);
  glAttachShader(program, fragShader);

  glLinkProgram(program);

  var isLinked: GLint
  glGetProgramiv(program, GL_LINK_STATUS, isLinked.addr)
  if isLinked == 0:
    echo "Linking shaders failed:"

    var length: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, length.addr)
    var log = newString(length.int)
    glGetProgramInfoLog(program, length, nil, log)
    echo log
    quit()

  return program
