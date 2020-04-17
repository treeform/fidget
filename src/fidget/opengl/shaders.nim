import buffers, opengl, os, strformat, strutils, vmath

type
  ShaderAttrib = object
    name: string
    location: GLint

  Uniform = object
    name: string
    componentType: GLenum
    kind: BufferKind
    values: array[16, float32]
    location: GLint

  Shader* = ref object
    paths: seq[string]
    programId*: GLuint
    attribs*: seq[ShaderAttrib]
    uniforms*: seq[Uniform]

proc getErrorLog*(
  id: GLuint,
  path: string,
  lenProc: typeof(glGetShaderiv),
  strProc: typeof(glGetShaderInfoLog)
): string =
  ## Gets the error log from compiling or linking shaders.
  var length: GLint = 0
  lenProc(id, GL_INFO_LOG_LENGTH, length.addr)
  var log = newString(length.int)
  strProc(id, length, nil, log)
  if log.startsWith("Compute info"):
    log = log[25..^1]
  let
    clickable = &"{path}({log[2..log.find(')')]}"
  result = &"{clickable}: {log}"

proc compileComputeShader*(compute: (string, string)): GLuint =
  ## Compiles the compute shader and returns the program id.
  var computeShader: GLuint

  block:
    var computeShaderArray = allocCStringArray([compute[1]])
    defer: dealloc(computeShaderArray)

    var isCompiled: GLint

    computeShader = glCreateShader(GL_COMPUTE_SHADER)
    glShaderSource(computeShader, 1, computeShaderArray, nil)
    glCompileShader(computeShader)
    glGetShaderiv(computeShader, GL_COMPILE_STATUS, isCompiled.addr)

    if isCompiled == 0:
      echo "Compute shader compilation failed:"
      echo getErrorLog(
        computeShader, compute[0], glGetShaderiv, glGetShaderInfoLog
      )
      quit()

  result = glCreateProgram()
  glAttachShader(result, computeShader)

  glLinkProgram(result)

  var isLinked: GLint
  glGetProgramiv(result, GL_LINK_STATUS, isLinked.addr)
  if isLinked == 0:
    echo "Linking compute shader failed:"
    echo getErrorLog(
      result, compute[0], glGetProgramiv, glGetProgramInfoLog
    )
    quit()

proc compileComputeShader*(path: string): GLuint =
  ## Compiles the compute shader and returns the program id.
  compileComputeShader((path, readFile(path)))

proc compileShaderFiles*(vert, frag: (string, string)): GLuint =
  ## Compiles the shader files and links them into a program, returning that id.
  var vertShader, fragShader: GLuint

  # Compile the shaders
  block shaders:
    var vertShaderArray = allocCStringArray([vert[1]])
    var fragShaderArray = allocCStringArray([frag[1]])

    defer:
      dealloc(vertShaderArray)
      dealloc(fragShaderArray)

    var isCompiled: GLint

    vertShader = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertShader, 1, vertShaderArray, nil)
    glCompileShader(vertShader)
    glGetShaderiv(vertShader, GL_COMPILE_STATUS, isCompiled.addr)

    if isCompiled == 0:
      echo "Vertex shader compilation failed:"
      echo getErrorLog(
        vertShader, vert[0], glGetShaderiv, glGetShaderInfoLog
      )
      quit()

    fragShader = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragShader, 1, fragShaderArray, nil)
    glCompileShader(fragShader)
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, isCompiled.addr)

    if isCompiled == 0:
      echo "Fragment shader compilation failed:"
      echo getErrorLog(
        fragShader, frag[0], glGetShaderiv, glGetShaderInfoLog
      )
      quit()

  # Attach shaders to a GL program
  result = glCreateProgram()
  glAttachShader(result, vertShader)
  glAttachShader(result, fragShader)

  glLinkProgram(result)

  var isLinked: GLint
  glGetProgramiv(result, GL_LINK_STATUS, isLinked.addr)
  if isLinked == 0:
    echo "Linking shaders failed:"
    echo getErrorLog(result, "", glGetProgramiv, glGetProgramInfoLog)
    quit()

proc compileShaderFiles*(vertPath, fragPath: string): GLuint =
  ## Compiles the shader files and links them into a program, returning that id.
  compileShaderFiles(
    (vertPath, readFile(vertPath)),
    (fragPath, readFile(fragPath))
  )

proc readAttribsAndUniforms(shader: Shader) =
  block attributes:
    var activeAttribCount: GLint
    glGetProgramiv(
      shader.programId,
      GL_ACTIVE_ATTRIBUTES,
      activeAttribCount.addr
    )

    for i in 0 ..< activeAttribCount:
      var
        buf = newString(64)
        length, size: GLint
        kind: GLenum
      glGetActiveAttrib(
        shader.programId,
        i.GLuint,
        len(buf).GLint,
        length.addr,
        size.addr,
        kind.addr,
        buf[0].addr
      )
      buf.setLen(length)

      let location = glGetAttribLocation(shader.programId, buf)
      shader.attribs.add(ShaderAttrib(name: move(buf), location: location))

  block uniforms:
    var activeUniformCount: GLint
    glGetProgramiv(
      shader.programId,
      GL_ACTIVE_UNIFORMS,
      activeUniformCount.addr
    )

    for i in 0 ..< activeUniformCount:
      var
        buf = newString(64)
        length, size: GLint
        kind: GLenum
      glGetActiveUniform(
        shader.programId,
        i.GLuint,
        len(buf).GLint,
        length.addr,
        size.addr,
        kind.addr,
        buf[0].addr
      )
      buf.setLen(length)

      if buf.endsWith("[0]"):
        # Skip arrays, these are part of UBOs and done a different way
        continue

      let location = glGetUniformLocation(shader.programId, buf)
      shader.uniforms.add(Uniform(name: move(buf), location: location))

proc newShader*(compute: (string, string)): Shader =
  result = Shader()
  result.paths = @[compute[0]]
  result.programId = compileComputeShader(compute)
  result.readAttribsAndUniforms()

proc newShader*(computePath: string): Shader =
  let
    dir = getCurrentDir()
    computePathFull = dir / computePath
  newShader((computePathFull, readFile(computePath)))

template newShaderStatic*(computePath: string): Shader =
  ## Creates a new shader but also statically reads computePath
  ## so it is compiled into the binary.
  const
    computeCode = staticRead(computePath)
    dir = currentSourcePath()
  let
    computePathFull = dir.parentDir() / computePath
  newShader((computePathFull, computeCode))

proc newShader*(vert, frag: (string, string)): Shader =
  result = Shader()
  result.paths = @[vert[0], frag[0]]
  result.programId = compileShaderFiles(vert, frag)
  result.readAttribsAndUniforms()

proc newShader*(vertPath, fragPath: string): Shader =
  let
    vertCode = readFile(vertPath)
    fragCode = readFile(fragPath)
    dir = getCurrentDir()
    vertPathFull = dir / vertPath
    fragPathFull = dir / fragPath
  newShader((vertPathFull, vertCode), (fragPathFull, fragCode))

template newShaderStatic*(vertPath, fragPath: string): Shader =
  ## Creates a new shader but also statically reads vertPath and fragPath
  ## so they are compiled into the binary.
  const
    vertCode = staticRead(vertPath)
    fragCode = staticRead(fragPath)
    dir = currentSourcePath()
  let
    vertPathFull = dir.parentDir() / vertPath
    fragPathFull = dir.parentDir() / fragPath
  newShader((vertPathFull, vertCode), (fragPathFull, fragCode))


proc hasUniform*(shader: Shader, name: string): bool =
  for uniform in shader.uniforms:
    if uniform.name == name:
      return true
  return false

proc setUniform(
  shader: Shader,
  name: string,
  componentType: GLenum,
  kind: BufferKind,
  values: array[16, float32]
) =
  for uniform in shader.uniforms.mitems:
    if uniform.name == name:
      uniform.componentType = componentType
      uniform.kind = kind
      uniform.values = values
      return

  echo &"Ignoring setUniform for \"{name}\", not active"

proc raiseUniformVarargsException(name: string, count: int) =
  raise newException(
    Exception,
    &"{count} varargs is more than the maximum of 4 for \"{name}\""
  )

proc raiseUniformComponentTypeException(
  name: string,
  componentType: GLenum
) =
  let hex = toHex(componentType.uint32)
  raise newException(
    Exception,
    &"Uniform \"{name}\" is of unexpected component type {hex}"
  )

proc raiseUniformKindException(name: string, kind: BufferKind) =
  raise newException(
    Exception,
    &"Uniform \"{name}\" is of unexpected kind {kind}"
  )

proc setUniform*(
  shader: Shader,
  name: string,
  args: varargs[int32]
) =
  var values: array[16, float32]
  for i in 0 ..< min(len(args), 16):
    values[i] = args[i].float32

  var kind: BufferKind
  case len(args):
    of 1:
      kind = bkSCALAR
    of 2:
      kind = bkVEC2
    of 3:
      kind = bkVEC3
    of 4:
      kind = bkVEC4
    else:
      raiseUniformVarargsException(name, len(args))

  shader.setUniform(name, cGL_INT, kind, values)

proc setUniform*(
  shader: Shader,
  name: string,
  args: varargs[float32]
) =
  var values: array[16, float32]
  for i in 0 ..< min(len(args), 16):
    values[i] = args[i]

  var kind: BufferKind
  case len(args):
    of 1:
      kind = bkSCALAR
    of 2:
      kind = bkVEC2
    of 3:
      kind = bkVEC3
    of 4:
      kind = bkVEC4
    else:
      raiseUniformVarargsException(name, len(args))

  shader.setUniform(name, cGL_FLOAT, kind, values)

proc setUniform*(
  shader: Shader,
  name: string,
  v: Vec3
) =
  var values: array[16, float32]
  values[0] = v.x
  values[1] = v.y
  values[2] = v.z
  shader.setUniform(name, cGL_FLOAT, bkVEC3, values)

proc setUniform*(
  shader: Shader,
  name: string,
  v: Vec4
) =
  var values: array[16, float32]
  values[0] = v.x
  values[1] = v.y
  values[2] = v.z
  values[3] = v.w
  shader.setUniform(name, cGL_FLOAT, bkVEC4, values)

proc setUniform*(
  shader: Shader,
  name: string,
  m: Mat4
) =
  shader.setUniform(name, cGL_FLOAT, bkMAT4, m)

proc bindUniforms*(shader: Shader) =
  for uniform in shader.uniforms.mitems:
    if uniform.componentType == 0.GLenum:
      continue

    if uniform.componentType != cGL_INT and uniform.componentType != cGL_FLOAT:
      raiseUniformComponentTypeException(uniform.name, uniform.componentType)

    case uniform.kind:
      of bkSCALAR:
        if uniform.componentType == cGL_INT:
          glUniform1i(uniform.location, uniform.values[0].GLint)
        else:
          glUniform1f(uniform.location, uniform.values[0])
      of bkVEC2:
        if uniform.componentType == cGL_INT:
          glUniform2i(
            uniform.location,
            uniform.values[0].GLint,
            uniform.values[1].GLint)
        else:
          glUniform2f(
            uniform.location,
            uniform.values[0],
            uniform.values[1]
          )
      of bkVEC3:
        if uniform.componentType == cGL_INT:
          glUniform3i(
            uniform.location,
            uniform.values[0].GLint,
            uniform.values[1].GLint,
            uniform.values[2].GLint
          )
        else:
          glUniform3f(
            uniform.location,
            uniform.values[0],
            uniform.values[1],
            uniform.values[2]
          )
      of bkVEC4:
        if uniform.componentType == cGL_INT:
          glUniform4i(
            uniform.location,
            uniform.values[0].GLint,
            uniform.values[1].GLint,
            uniform.values[2].GLint,
            uniform.values[3].GLint
          )
        else:
          glUniform4f(
            uniform.location,
            uniform.values[0],
            uniform.values[1],
            uniform.values[2],
            uniform.values[3]
          )
      of bkMAT4:
        glUniformMatrix4fv(
          uniform.location,
          1,
          GL_FALSE,
          uniform.values[0].addr
        )
      else:
        raiseUniformKindException(uniform.name, uniform.kind)

proc bindAttrib*(
  shader: Shader,
  name: string,
  buffer: Buffer
) =
  glBindBuffer(buffer.target, buffer.bufferId)

  for attrib in shader.attribs:
    if name == attrib.name:
      if buffer.normalized or buffer.kind != bkSCALAR:
        glVertexAttribPointer(
          attrib.location.GLuint,
          buffer.kind.componentCount().GLint,
          buffer.componentType,
          if buffer.normalized: GL_TRUE else: GL_FALSE,
          0,
          nil
        )
      else:
        glVertexAttribIPointer(
          attrib.location.GLuint,
          buffer.kind.componentCount().GLint,
          buffer.componentType,
          0,
          nil
        )

      glEnableVertexAttribArray(attrib.location.GLuint)
      return

  echo &"Attribute \"{name}\" not found in shader {shader.paths}"
