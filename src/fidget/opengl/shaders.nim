import opengl

proc getErrorLog(
  id: GLuint,
  lenProc: typeof(glGetShaderiv),
  strProc: typeof(glGetShaderInfoLog)
): string =
  ## Gets the error log from compiling or linking shaders.
  var length: GLint = 0
  lenProc(id, GL_INFO_LOG_LENGTH, length.addr)
  var log = newString(length.int)
  strProc(id, length, nil, log)
  return log

proc compileShaderFiles*(vertShaderSrc: string, fragShaderSrc: string): GLuint =
  ## Compiles the shader files and links them into a program, returning that id.
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
      echo getErrorLog(vertShader, glGetShaderiv, glGetShaderInfoLog)
      quit()

    fragShader = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragShader, 1, fragShaderArray, nil)
    glCompileShader(fragShader)
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, isCompiled.addr)

    if isCompiled == 0:
      echo fragShaderSrc
      echo "Fragment shader compilation failed:"
      echo getErrorLog(fragShader, glGetShaderiv, glGetShaderInfoLog)
      quit()

  # Attach shaders to a GL program
  var program = glCreateProgram()
  glAttachShader(program, vertShader)
  glAttachShader(program, fragShader)

  glLinkProgram(program)

  var isLinked: GLint
  glGetProgramiv(program, GL_LINK_STATUS, isLinked.addr)
  if isLinked == 0:
    echo "Linking shaders failed:"
    echo getErrorLog(program, glGetProgramiv, glGetProgramInfoLog)
    quit()

  return program
