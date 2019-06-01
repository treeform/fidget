import opengl
import vmath
import math
import random

import shaders
import textures
import base
import chroma

type

  FVec2* = object
    x, y: float32

  FVec3* = object
    x, y, z: float32

  FVec4* = object
    x, y, z, w: float32

  VertBufferKind* = enum
    Position, Color, Uv, Normal, BiNormal

  VertBuffer* = ref object
    kind*: VertBufferKind
    stride*: int
    data*: seq[float32]
    vbo*: GLuint

  UniformKind* = enum
    UniformVec3

  Uniform* = ref object
    name*: string
    kind*: UniformKind
    loc*: int
    vec3*: Vec3

  TexUniform* = object
    name*: string
    loc*: int
    texture*: Texture

  Mesh* = ref object
    name*: string
    buffers*: seq[VertBuffer]
    textures*: seq[TexUniform]
    uniforms*: seq[Uniform]
    kids*: seq[Mesh]
    shader*: GLuint
    mat*: Mat4

    # OpenGL data
    drawMode*: GLenum
    vao*: GLuint


proc newVertBuffer*(kind: VertBufferKind, stride: int = 0): VertBuffer =
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
  result.data = newSeq[float32]()
  glGenBuffers(1, addr result.vbo)


proc uploadBuf*(buf: var VertBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, buf.vbo)
  glBufferData(GL_ARRAY_BUFFER, buf.data.len * 4, addr buf.data[0], GL_STATIC_DRAW)


proc uploadBuf*(buf: var VertBuffer, max: int) =
  glBindBuffer(GL_ARRAY_BUFFER, buf.vbo)
  glBufferData(GL_ARRAY_BUFFER, buf.stride * max * 4, addr buf.data[0], GL_STATIC_DRAW)


proc bindBuf*(buf: var VertBuffer, index: int) =
  glBindBuffer(GL_ARRAY_BUFFER, buf.vbo)
  glVertexAttribPointer(GLuint index, GLint buf.stride, cGL_FLOAT, GL_FALSE, 0, nil)
  glEnableVertexAttribArray(GLuint index)


proc newMesh*(): Mesh =
  result = Mesh()
  result.mat = identity()
  result.buffers = newSeq[VertBuffer]()
  result.textures = newSeq[TexUniform]()
  result.uniforms = newSeq[Uniform]()
  result.drawMode = GL_TRIANGLES
  glGenVertexArrays(1, addr result.vao)


proc newBasicMesh*(): Mesh =
  result = newMesh()
  result.buffers.add newVertBuffer(Position)


proc newColorMesh*(): Mesh =
  result = newMesh()
  result.buffers.add newVertBuffer(Position)
  result.buffers.add newVertBuffer(Color)


proc newUvMesh*(): Mesh =
  result = newMesh()
  result.buffers.add newVertBuffer(Position)
  result.buffers.add newVertBuffer(Uv)


proc newUvColorMesh*(): Mesh =
  result = newMesh()
  result.buffers.add newVertBuffer(Position)
  result.buffers.add newVertBuffer(Uv)
  result.buffers.add newVertBuffer(Color)


proc loadShader*(mesh: var Mesh, vertFileName: string, fragFileName: string) =
  mesh.shader = compileShaderFiles(vertFileName, fragFileName)


proc loadTexture*(mesh: var Mesh, name: string, texture: Texture) =
  var uniform = TexUniform()
  uniform.name = name
  uniform.texture = texture
  uniform.loc = glGetUniformLocation(mesh.shader, name)
  assert uniform.loc != -1
  mesh.textures.add(uniform)


proc upload*(mesh: var Mesh) =
  ## When bufers change, uploads them to GPU
  for buf in mesh.buffers.mitems:
    buf.uploadBuf()

proc upload*(mesh: var Mesh, max: int) =
  ## When bufers change, uploads them to GPU
  for buf in mesh.buffers.mitems:
    buf.uploadBuf(max)


proc finalize*(mesh: var Mesh) =
  mesh.upload()
  glBindVertexArray(mesh.vao)
  for i, buf in mesh.buffers.mpairs:
    buf.bindBuf(i)


proc addVert*(buf: var VertBuffer, v: Vec2) =
  assert buf.stride == 2
  buf.data.add(v.x)
  buf.data.add(v.y)


proc addVert*(buf: var VertBuffer, v: Vec3) =
  assert buf.stride == 3
  buf.data.add(v.x)
  buf.data.add(v.y)
  buf.data.add(v.z)


proc addVert*(buf: var VertBuffer, v: Vec4) =
  assert buf.stride == 4
  buf.data.add(v.x)
  buf.data.add(v.y)
  buf.data.add(v.z)
  buf.data.add(v.w)

proc addVert*(buf: var VertBuffer, v: Color) =
  assert buf.stride == 4
  buf.data.add(v.r)
  buf.data.add(v.g)
  buf.data.add(v.b)
  buf.data.add(v.a)

proc len*(buf: VertBuffer): int =
  buf.data.len div buf.stride


proc getVert2*(buf: VertBuffer, i: int): Vec2 =
  assert buf.stride == 2
  result.x = buf.data[i * 2 + 0]
  result.y = buf.data[i * 2 + 1]


proc setVert2*(buf: var VertBuffer, i: int, v: Vec2) =
  assert buf.stride == 2
  buf.data[i * 2 + 0] = v.x
  buf.data[i * 2 + 1] = v.y


proc getVert3*(buf: VertBuffer, i: int): Vec3 =
  assert buf.stride == 3
  result.x = buf.data[i * 3 + 0]
  result.y = buf.data[i * 3 + 1]
  result.z = buf.data[i * 3 + 2]


proc setVert3*(buf: var VertBuffer, i: int, v: Vec3) =
  assert buf.stride == 3
  buf.data[i * 3 + 0] = v.x
  buf.data[i * 3 + 1] = v.y
  buf.data[i * 3 + 2] = v.z

proc getVertColor*(buf: VertBuffer, i: int): Color =
  assert buf.stride == 4
  result.r = buf.data[i * 4 + 0]
  result.g = buf.data[i * 4 + 1]
  result.b = buf.data[i * 4 + 2]
  result.a = buf.data[i * 4 + 3]


proc setVertColor*(buf: var VertBuffer, i: int, color: Color) =
  assert buf.stride == 4
  buf.data[i * 4 + 0] = color.r
  buf.data[i * 4 + 1] = color.g
  buf.data[i * 4 + 2] = color.b
  buf.data[i * 4 + 3] = color.a


proc numVerts*(mesh: Mesh): int =
  if mesh.buffers.len > 0:
    return mesh.buffers[0].data.len div mesh.buffers[0].stride
  return 0


proc getBuf*(mesh: var Mesh, kind: VertBufferKind): var VertBuffer =
  for buf in mesh.buffers.mitems:
    if buf.kind == kind:
      return buf


proc addVert*(mesh: var Mesh, v: Vec3) =
  var buf = mesh.getBuf(Position)
  buf.addVert(v)


proc addVert*(mesh: var Mesh, pos: Vec3, color: Vec4) =
  var posBuf = mesh.getBuf(Position)
  posBuf.addVert(pos)
  var colorBuf = mesh.getBuf(Color)
  colorBuf.addVert(color)


proc addVert*(mesh: var Mesh, pos: Vec3, uv: Vec2) =
  var posBuf = mesh.getBuf(Position)
  posBuf.addVert(pos)
  var uvBuf = mesh.getBuf(Uv)
  uvBuf.addVert(uv)


proc addVert*(mesh: var Mesh, pos: Vec3, uv: Vec2, color: Color) =
  mesh.getBuf(Position).addVert(pos)
  mesh.getBuf(Uv).addVert(uv)
  mesh.getBuf(Color).addVert(color)


proc addQuad*(mesh: var Mesh, a, b, c, d: Vec3) =
  mesh.addVert(a)
  mesh.addVert(c)
  mesh.addVert(b)
  mesh.addVert(c)
  mesh.addVert(a)
  mesh.addVert(d)


proc addQuad*(mesh: var Mesh, a: Vec3, ac: Vec4, b: Vec3, bc: Vec4, c: Vec3, cc: Vec4, d: Vec3, dc: Vec4) =
  mesh.addVert(a, ac)
  mesh.addVert(c, cc)
  mesh.addVert(b, bc)
  mesh.addVert(c, cc)
  mesh.addVert(a, ac)
  mesh.addVert(d, dc)


proc addQuad*(mesh: var Mesh, a: Vec3, ac: Vec2, b: Vec3, bc: Vec2, c: Vec3, cc: Vec2, d: Vec3, dc: Vec2) =
  mesh.addVert(a, ac)
  mesh.addVert(c, cc)
  mesh.addVert(b, bc)
  mesh.addVert(c, cc)
  mesh.addVert(a, ac)
  mesh.addVert(d, dc)


proc addQuad*(mesh: var Mesh,
    a: Vec3, auv: Vec2, ac: Color,
    b: Vec3, buv: Vec2, bc: Color,
    c: Vec3, cuv: Vec2, cc: Color,
    d: Vec3, duv: Vec2, dc: Color
  ) =
  mesh.addVert(a, auv, ac)
  mesh.addVert(c, cuv, cc)
  mesh.addVert(b, buv, bc)
  mesh.addVert(c, cuv, cc)
  mesh.addVert(a, auv, ac)
  mesh.addVert(d, duv, dc)

proc genNormals*(mesh: var Mesh) =
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


proc addUniform*(mesh: var Mesh, name: string, v: Vec3) =
  var uniform = Uniform()
  uniform.name = name
  uniform.vec3 = v
  uniform.loc = glGetUniformLocation(mesh.shader, name)
  if uniform.loc == -1:
    echo "could not find uniform", name
    quit()
  mesh.uniforms.add(uniform)


proc updateUniform*(mesh: var Mesh, name: string, v: Vec3) =
  for uniform in mesh.uniforms.mitems:
    if uniform.name == name:
      uniform.vec3 = v
  for kid in mesh.kids.mitems:
    kid.updateUniform(name, v)


proc uniformBind*(mesh: Mesh, uniform: Uniform) =
  glUniform3f(GLint uniform.loc, uniform.vec3.x, uniform.vec3.y, uniform.vec3.z)


proc find*(mesh: var Mesh, name: string): Mesh =
  if mesh.name == name:
    return mesh
  for kid in mesh.kids.mitems:
    var found = kid.find(name)
    if found != nil:
      return found


proc drawBasic*(mesh: var Mesh, mat: Mat4, max: int) =
    glUseProgram(mesh.shader)

    var uniModel = glGetUniformLocation(mesh.shader, "model")
    if uniModel > -1:
      var arr = mat.toFloat32()
      glUniformMatrix4fv(uniModel, GLsizei 1, GL_FALSE, cast[ptr GLfloat](arr[0].addr))

    var uniView = glGetUniformLocation(mesh.shader, "view")
    if uniView > -1:
      var arr = view.toFloat32()
      glUniformMatrix4fv(uniView, GLsizei 1, GL_FALSE, cast[ptr GLfloat](arr[0].addr))

    var uniProj = glGetUniformLocation(mesh.shader, "proj")
    if uniProj > -1:
      var arr = proj.toFloat32()
      glUniformMatrix4fv(uniProj, GLsizei 1, GL_FALSE, cast[ptr GLfloat](arr[0].addr))

    var uniSuperTrans = glGetUniformLocation(mesh.shader, "superTrans")
    if uniSuperTrans > -1:
      var superTrans = proj * view * mat
      var arr = superTrans.toFloat32()
      glUniformMatrix4fv(uniSuperTrans, GLsizei 1, GL_FALSE, cast[ptr GLfloat](arr[0].addr))

    # Do the drawing
    glBindVertexArray(mesh.vao)

    for uniform in mesh.uniforms:
      mesh.uniformBind(uniform)

    for i, uniform in mesh.textures:
      uniform.texture.textureBind(i)
      glUniform1i(GLint uniform.loc, GLint i)

    glDrawArrays(mesh.drawMode, 0, GLsizei max)
    #if mesh.drawMode == Lines:
    #  glDrawArrays(GL_LINES, 0, GLsizei mesh.numVerts)

    # Unbind
    glBindVertexArray(0)
    glUseProgram(0)


proc draw*(mesh: var Mesh, parentMat: Mat4) =
  var thisMat = parentMat * mesh.mat
  if mesh.numVerts > 0:
    mesh.drawBasic(thisMat, mesh.numVerts)

  for kid in mesh.kids.mitems:
    kid.draw(thisMat)


proc draw*(mesh: var Mesh) =
  if mesh.numVerts > 0:
    mesh.drawBasic(mesh.mat, mesh.numVerts)

  for kid in mesh.kids.mitems:
    kid.draw(mesh.mat)


proc printMeshTree*(mesh: Mesh, indent=0) =
  var space = ""
  for i in 0..<indent:
    space &= "  "
  echo space, mesh.name, " [", $mesh.numVerts, "] ", mesh.mat.pos
  for kid in mesh.kids:
    printMeshTree(kid, indent + 1)







