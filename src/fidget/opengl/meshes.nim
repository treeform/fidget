import ../uibase, buffers, base, chroma, math, opengl, shaders, vmath

type
  VertBufferKind* = enum
    ## Type of a buffer - what data does it hold.
    Position, Color, Uv, Normal, BiNormal

  VertBuffer* = ref object
    ## Buffer and data holder.
    kind*: VertBufferKind
    stride*: int
    data*: seq[float32]
    vbo*: GLuint

  TexUniform* = object
    ## Texture uniform
    name*: string
    textureId*: GLuint

  Mesh* = ref object
    ## Main mesh object that has everything it needs to render.
    buffers*: seq[VertBuffer]
    textures*: seq[TexUniform]
    shader*: Shader
    mat*: Mat4

    # OpenGL data
    vao*: GLuint

proc newVertBuffer*(
    kind: VertBufferKind,
    stride: int = 0,
    size: int = 0): VertBuffer =
  ## Create a new vertex buffer.
  result = VertBuffer()
  result.kind = kind
  if stride == 0:
    case kind:
      of Position:
        result.stride = 3
      of Color:
        result.stride = 4
      of Uv:
        result.stride = 2
      of Normal:
        result.stride = 3
      of BiNormal:
        result.stride = 3
  else:
    result.stride = stride
  result.data = newSeq[float32](result.stride * size)
  glGenBuffers(1, addr result.vbo)

proc len*(buf: VertBuffer): int =
  ## Get the length of the buffer.
  buf.data.len div buf.stride

proc uploadBuf*(buf: VertBuffer, max: int) =
  ## Upload only a part of the buffer up to the max.
  ## Create for dynamic buffers that are sized bigger then the data hey hold.
  var len = buf.stride * max * 4
  glBindBuffer(GL_ARRAY_BUFFER, buf.vbo)
  glBufferData(GL_ARRAY_BUFFER, len, addr buf.data[0], GL_STATIC_DRAW)

proc uploadBuf*(buf: VertBuffer) =
  ## Upload a buffer to the GPU.
  ## Needed if you have updated the buffer and want to send new changes.
  if buf.len > 0:
    buf.uploadBuf(buf.len)

proc bindBuf*(buf: VertBuffer, mesh: Mesh) =
  ## Binds the buffer to the mesh and shader
  let uniformName = "vertex" & $buf.kind

  var bufferKind: BufferKind
  case buf.stride:
    of 1:
      bufferKind = bkSCALAR
    of 2:
      bufferKind = bkVEC2
    of 3:
      bufferKind = bkVEC3
    of 4:
      bufferKind = bkVEC4
    of 9:
      bufferKind = bkMAT3
    of 16:
      bufferKind = bkMAT4
    else:
      raise newException(Exception, "Unexpected stride")

  mesh.shader.bindAttrib(uniformName, buf.vbo, bufferKind, cGL_FLOAT)

proc newMesh*(): Mesh =
  ## Creates a empty new mesh.
  ## New vert buffers need to be added.
  result = Mesh()
  result.mat = identity()
  result.buffers = newSeq[VertBuffer]()
  result.textures = newSeq[TexUniform]()
  glGenVertexArrays(1, addr result.vao)

proc newBasicMesh*(): Mesh =
  ## Create a basic mesh, with only the position buffers.
  result = newMesh()
  result.buffers.add newVertBuffer(Position)

proc newColorMesh*(): Mesh =
  ## Create a basic mesh, with position and color buffers.
  result = newMesh()
  result.buffers.add newVertBuffer(Position)
  result.buffers.add newVertBuffer(Color)

proc newUvMesh*(): Mesh =
  ## Create a basic mesh, with position and uv buffers.
  result = newMesh()
  result.buffers.add newVertBuffer(Position)
  result.buffers.add newVertBuffer(Uv)

proc newUvColorMesh*(size: int = 0): Mesh =
  ## Create a basic mesh, with position, color and uv buffers.
  result = newMesh()
  result.buffers.add newVertBuffer(Position, size = size)
  result.buffers.add newVertBuffer(Uv, size = size)
  result.buffers.add newVertBuffer(Color, size = size)

proc loadTexture*(mesh: Mesh, name: string, textureId: GLuint) =
  ## Load the texture ad attach it to a uniform.
  var uniform = TexUniform()
  uniform.name = name
  uniform.textureId = textureId
  mesh.textures.add(uniform)

proc upload*(mesh: Mesh) =
  ## When buffers change, uploads them to GPU.
  for buf in mesh.buffers.mitems:
    buf.uploadBuf()

proc upload*(mesh: Mesh, max: int) =
  ## When buffers change, uploads them to GPU.
  for buf in mesh.buffers.mitems:
    buf.uploadBuf(max)

proc finalize*(mesh: Mesh) =
  ## Calls this to upload all the data nad uniforms.
  mesh.upload()
  glBindVertexArray(mesh.vao)
  for buf in mesh.buffers:
    buf.bindBuf(mesh)

proc getVert2*(buf: VertBuffer, i: int): Vec2 =
  ## Get a vertex from the buffer.
  assert buf.stride == 2
  result.x = buf.data[i * 2 + 0]
  result.y = buf.data[i * 2 + 1]

proc setVert2*(buf: VertBuffer, i: int, v: Vec2) =
  ## Set a vertex in the buffer.
  assert buf.stride == 2
  buf.data[i * 2 + 0] = v.x
  buf.data[i * 2 + 1] = v.y

proc getVert3*(buf: VertBuffer, i: int): Vec3 =
  ## Get a vertex from the buffer.
  assert buf.stride == 3
  result.x = buf.data[i * 3 + 0]
  result.y = buf.data[i * 3 + 1]
  result.z = buf.data[i * 3 + 2]

proc setVert3*(buf: VertBuffer, i: int, v: Vec3) =
  ## Set a vertex in the buffer.
  assert buf.stride == 3
  buf.data[i * 3 + 0] = v.x
  buf.data[i * 3 + 1] = v.y
  buf.data[i * 3 + 2] = v.z

proc getVertColor*(buf: VertBuffer, i: int): Color =
  ## Get a color from the buffer.
  assert buf.stride == 4
  result.r = buf.data[i * 4 + 0]
  result.g = buf.data[i * 4 + 1]
  result.b = buf.data[i * 4 + 2]
  result.a = buf.data[i * 4 + 3]

proc setVertColor*(buf: VertBuffer, i: int, color: Color) =
  ## Set a color in the buffer.
  assert buf.stride == 4
  buf.data[i * 4 + 0] = color.r
  buf.data[i * 4 + 1] = color.g
  buf.data[i * 4 + 2] = color.b
  buf.data[i * 4 + 3] = color.a

proc numVerts*(mesh: Mesh): int =
  ## Return number of vertexes in the mesh.
  if mesh.buffers.len > 0:
    return mesh.buffers[0].len
  return 0

proc numTri*(mesh: Mesh): int =
  ## Return number of triangles in the mesh.
  return mesh.numVerts() div 3

proc getBuf*(mesh: Mesh, kind: VertBufferKind): VertBuffer =
  ## Gets a buffer of a given type.
  for buf in mesh.buffers:
    if buf.kind == kind:
      return buf

proc drawBasic*(mesh: Mesh, mat: Mat4, max: int) =
  ## Draw the basic mesh.
  glUseProgram(mesh.shader.programId)

  # Bind the regular uniforms:
  if mesh.shader.hasUniform("windowFrame"):
    mesh.shader.setUniform("windowFrame", windowFrame.x, windowFrame.y)
  # mesh.shader.setUniform("model", mat)
  # mesh.shader.setUniform("view", view)
  mesh.shader.setUniform("proj", proj)
  # mesh.shader.setUniform("superTrans", proj * view *  mat)

  # Do the drawing
  glBindVertexArray(mesh.vao)

  for i, uniform in mesh.textures:
    glActiveTexture(GLenum(int(GL_TEXTURE0) + i))
    glBindTexture(GL_TEXTURE_2D, uniform.textureId)
    mesh.shader.setUniform(uniform.name, i.int32)

  mesh.shader.bindUniforms()

  glDrawArrays(GL_TRIANGLES, 0, GLsizei max)

  # Unbind
  glBindVertexArray(0)
  glUseProgram(0)

proc draw*(mesh: Mesh) =
  ## Draw the mesh.
  if mesh.numVerts > 0:
    mesh.drawBasic(mesh.mat, mesh.numVerts)
