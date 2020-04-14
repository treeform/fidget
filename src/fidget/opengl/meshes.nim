import ../uibase, chroma, math, opengl, shaders, strformat, textures, vmath

when defined(ios) or defined(android):
  import basemobile as base
else:
  import base as base

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
    loc*: int
    texture*: Texture

  Mesh* = ref object
    ## Main mesh object that has everything it needs to render.
    name*: string
    buffers*: seq[VertBuffer]
    textures*: seq[TexUniform]
    kids*: seq[Mesh]
    shader*: Shader
    mat*: Mat4

    # OpenGL data
    drawMode*: GLenum
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

proc bindBuf*(buf: VertBuffer, mesh: Mesh, index: int) =
  ## Binds the buffer to the mesh and shader
  let uniformName = "vertex" & $buf.kind
  let loc = glGetAttribLocation(mesh.shader.programId, uniformName).GLuint
  glBindBuffer(GL_ARRAY_BUFFER, buf.vbo)
  glVertexAttribPointer(loc, buf.stride.GLint, cGL_FLOAT, GL_FALSE, 0, nil)
  glEnableVertexAttribArray(GLuint index)

proc newMesh*(): Mesh =
  ## Creates a empty new mesh.
  ## New vert buffers need to be added.
  result = Mesh()
  result.mat = identity()
  result.buffers = newSeq[VertBuffer]()
  result.textures = newSeq[TexUniform]()
  result.drawMode = GL_TRIANGLES
  when defined(android):
    glGenVertexArraysOES(1, addr result.vao)
  else:
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

proc loadTexture*(mesh: Mesh, name: string, texture: Texture) =
  ## Load the texture ad attach it to a uniform.
  var uniform = TexUniform()
  uniform.name = name
  uniform.texture = texture
  uniform.loc = glGetUniformLocation(mesh.shader.programId, name)
  if uniform.loc == -1:
    echo &"can't find uniform {name} in mesh.shader.name"
    quit()
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
  when defined(android):
    glBindVertexArrayOES(mesh.vao)
  else:
    glBindVertexArray(mesh.vao)
  for i, buf in mesh.buffers.mpairs:
    buf.bindBuf(mesh, i)

proc addVert*(buf: VertBuffer, v: Vec2) =
  ## Add a vertex to the buffer.
  assert buf.stride == 2
  buf.data.add(v.x)
  buf.data.add(v.y)

proc addVert*(buf: VertBuffer, v: Vec3) =
  ## Add a vertex to the buffer.
  assert buf.stride == 3
  buf.data.add(v.x)
  buf.data.add(v.y)
  buf.data.add(v.z)

proc addVert*(buf: VertBuffer, v: Vec4) =
  ## Add a vertex to the buffer.
  assert buf.stride == 4
  buf.data.add(v.x)
  buf.data.add(v.y)
  buf.data.add(v.z)
  buf.data.add(v.w)

proc addVert*(buf: VertBuffer, v: Color) =
  ## Add a vertex to the buffer.
  assert buf.stride == 4
  buf.data.add(v.r)
  buf.data.add(v.g)
  buf.data.add(v.b)
  buf.data.add(v.a)

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

proc addVert*(mesh: Mesh, v: Vec3) =
  ## Add vertex to the mesh.
  var buf = mesh.getBuf(Position)
  buf.addVert(v)

proc addVert*(mesh: Mesh, pos: Vec3, color: Vec4) =
  ## Add vertex to the mesh.
  var posBuf = mesh.getBuf(Position)
  posBuf.addVert(pos)
  var colorBuf = mesh.getBuf(Color)
  colorBuf.addVert(color)

proc addVert*(mesh: Mesh, pos: Vec3, uv: Vec2) =
  ## Add vertex to the mesh.
  var posBuf = mesh.getBuf(Position)
  posBuf.addVert(pos)
  var uvBuf = mesh.getBuf(Uv)
  uvBuf.addVert(uv)

proc addVert*(mesh: Mesh, pos: Vec3, uv: Vec2, color: Color) =
  ## Add vertex to the mesh.
  mesh.getBuf(Position).addVert(pos)
  mesh.getBuf(Uv).addVert(uv)
  mesh.getBuf(Color).addVert(color)

proc addVert*(mesh: Mesh, pos: Vec3, color: Vec4, normal: Vec3) =
  ## Add vertex to the mesh.
  mesh.getBuf(Position).addVert(pos)
  mesh.getBuf(Color).addVert(color)
  mesh.getBuf(Normal).addVert(normal)

proc addQuad*(mesh: Mesh, a, b, c, d: Vec3) =
  ## Add quad to the mesh.
  mesh.addVert(a)
  mesh.addVert(c)
  mesh.addVert(b)
  mesh.addVert(c)
  mesh.addVert(a)
  mesh.addVert(d)

proc addQuad*(mesh: Mesh,
    a: Vec3, ac: Vec4,
    b: Vec3, bc: Vec4,
    c: Vec3, cc: Vec4,
    d: Vec3, dc: Vec4
  ) =
  ## Add quad to the mesh.
  mesh.addVert(a, ac)
  mesh.addVert(c, cc)
  mesh.addVert(b, bc)
  mesh.addVert(c, cc)
  mesh.addVert(a, ac)
  mesh.addVert(d, dc)

proc addQuad*(mesh: Mesh,
    a: Vec3, ac: Vec2,
    b: Vec3, bc: Vec2,
    c: Vec3, cc: Vec2,
    d: Vec3, dc: Vec2
  ) =
  ## Add quad to the mesh.
  mesh.addVert(a, ac)
  mesh.addVert(c, cc)
  mesh.addVert(b, bc)
  mesh.addVert(c, cc)
  mesh.addVert(a, ac)
  mesh.addVert(d, dc)

proc addQuad*(mesh: Mesh,
    a: Vec3, ac: Vec4, an: Vec3,
    b: Vec3, bc: Vec4, bn: Vec3,
    c: Vec3, cc: Vec4, cn: Vec3,
    d: Vec3, dc: Vec4, dn: Vec3
  ) =
  ## Add quad to the mesh.
  mesh.addVert(a, ac, an)
  mesh.addVert(c, cc, cn)
  mesh.addVert(b, bc, bn)
  mesh.addVert(c, cc, cn)
  mesh.addVert(a, ac, an)
  mesh.addVert(d, dc, dn)

proc addQuad*(mesh: Mesh,
    a: Vec3, auv: Vec2, ac: Color,
    b: Vec3, buv: Vec2, bc: Color,
    c: Vec3, cuv: Vec2, cc: Color,
    d: Vec3, duv: Vec2, dc: Color
  ) =
  ## Add quad to the mesh.
  mesh.addVert(a, auv, ac)
  mesh.addVert(c, cuv, cc)
  mesh.addVert(b, buv, bc)
  mesh.addVert(c, cuv, cc)
  mesh.addVert(a, auv, ac)
  mesh.addVert(d, duv, dc)

proc genNormals*(mesh: Mesh) =
  ## Generate normals based on the position buffer.
  var normBuf = newVertBuffer(Normal)
  mesh.buffers.add(normBuf)

  let posBuf = mesh.getBuf(Position)
  var i = 0
  while i * 3 < posBuf.data.len:
    let
      a = posBuf.getVert3(i + 0)
      b = posBuf.getVert3(i + 1)
      c = posBuf.getVert3(i + 2)
      norm = cross(b - a, c - a).normalize()
    normBuf.addVert(norm)
    normBuf.addVert(norm)
    normBuf.addVert(norm)
    i += 3

proc find*(mesh: Mesh, name: string): Mesh =
  ## Find a node the the mesh kids.
  if mesh.name == name:
    return mesh
  for kid in mesh.kids.mitems:
    var found = kid.find(name)
    if found != nil:
      return found

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
  when defined(android):
    glBindVertexArrayOES(mesh.vao)
  else:
    glBindVertexArray(mesh.vao)

  mesh.shader.bindUniforms()

  for i, uniform in mesh.textures:
    uniform.texture.textureBind(i)
    glUniform1i(GLint uniform.loc, GLint i)

  glDrawArrays(mesh.drawMode, 0, GLsizei max)

  # Unbind
  when defined(android):
    glBindVertexArrayOES(0)
  else:
    glBindVertexArray(0)
  glUseProgram(0)

proc draw*(mesh: Mesh, parentMat: Mat4) =
  ## Draw the mesh with a parent mat.
  var thisMat = parentMat * mesh.mat
  if mesh.numVerts > 0:
    mesh.drawBasic(thisMat, mesh.numVerts)

  for kid in mesh.kids.mitems:
    kid.draw(thisMat)

proc draw*(mesh: Mesh) =
  ## Draw the mesh.
  if mesh.numVerts > 0:
    mesh.drawBasic(mesh.mat, mesh.numVerts)

  for kid in mesh.kids.mitems:
    kid.draw(mesh.mat)

proc printMeshTree*(mesh: Mesh, indent = 0) =
  ## Print the mesh and its subtree.
  var space = ""
  for i in 0..<indent:
    space &= "  "
  echo space, mesh.name, " [", $mesh.numVerts, "] ", mesh.mat.pos
  for kid in mesh.kids:
    printMeshTree(kid, indent + 1)
