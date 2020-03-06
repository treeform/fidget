import opengl


proc getShaderLog(shader: GLuint): string =
  var length: GLint = 0
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, length.addr)
  var log = newString(length.int)
  glGetShaderInfoLog(shader, length, nil, log)
  return log

proc compileShaderFiles*(vertShaderSrc: string, fragShaderSrc: string): GLuint =
  var vertShaderArray = allocCStringArray([vertShaderSrc])
  var fragShaderArray = allocCStringArray([fragShaderSrc])

  defer:
    dealloc(vertShaderArray)
    dealloc(fragShaderArray)

  # Status variables
  var isCompiled: GLint
  var isLinked: GLint

  # Compile shaders
  # Vertex
  var vertShader = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(vertShader, 1, vertShaderArray, nil)
  glCompileShader(vertShader)
  glGetShaderiv(vertShader, GL_COMPILE_STATUS, isCompiled.addr)

  # Check vertex compilation status
  if isCompiled == 0:
    echo vertShaderSrc
    echo "Vertex Shader wasn't compiled.  Reason:"
    echo getShaderLog(vertShader)
    quit()

    # Cleanup
    # dealloc(logStr)
  #else:
    #echo "Vertex Shader compiled successfully."

  # Fragment
  var fragShader = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragShader, 1, fragShaderArray, nil)
  glCompileShader(fragShader)
  glGetShaderiv(fragShader, GL_COMPILE_STATUS, isCompiled.addr)

  # Check Fragment compilation status
  if isCompiled == 0:
    echo fragShaderSrc
    echo "Fragment Shader wasn't compiled.  Reason:"
    echo getShaderLog(fragShader)
    quit()

    # Cleanup
    # dealloc(logStr)
  #else:
    #echo "Fragment Shader compiled successfully."

  # Attach to a GL program
  var shaderProgram = glCreateProgram()
  glAttachShader(shaderProgram, vertShader);
  glAttachShader(shaderProgram, fragShader);

  # insert locations
  glBindAttribLocation(shaderProgram, 0, "vertexPos");
  glBindAttribLocation(shaderProgram, 0, "vertexClr");

  glLinkProgram(shaderProgram);

  # Check for shader linking errors
  glGetProgramiv(shaderProgram, GL_LINK_STATUS, isLinked.addr)
  if isLinked == 0:
    echo "Wasn't able to link shaders.  Reason:"

    # Get the log size
    var logSize: GLint
    glGetProgramiv(shaderProgram, GL_INFO_LOG_LENGTH, logSize.addr)

    # Get the log itself
    var
      logStr = cast[ptr GLchar](alloc(logSize))
      logLen: GLsizei

    glGetProgramInfoLog(shaderProgram, logSize.GLsizei, logLen.addr, logStr)

    # Print the log
    quit $logStr

    # cleanup
    # dealloc(logStr)
  #else:
    #echo "Shader Program ready!"

  return shaderProgram


#glDeleteProgram(shaderProgram)
#glDeleteShader(vertShader)
#glDeleteShader(fragShader)
