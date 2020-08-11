import opengl

type
  BufferKind* = enum
    bkSCALAR, bkVEC2, bkVEC3, bkVEC4, bkMAT2, bkMAT3, bkMAT4

  Buffer* = object
    count*: int
    target*, componentType*: GLenum
    kind*: BufferKind
    normalized*: bool
    bufferId*: GLuint

func size*(componentType: GLenum): Positive =
  case componentType:
    of cGL_BYTE, cGL_UNSIGNED_BYTE:
      1
    of cGL_SHORT, cGL_UNSIGNED_SHORT:
      2
    of cGL_INT, GL_UNSIGNED_INT, cGL_FLOAT:
      4
    else:
      raise newException(Exception, "Unexpected componentType")

func componentCount*(bufferKind: BufferKind): Positive =
  case bufferKind:
    of bkSCALAR:
      1
    of bkVEC2:
      2
    of bkVEC3:
      3
    of bkVEC4, bkMAT2:
      4
    of bkMAT3:
      9
    of bkMAT4:
      16

proc bindBufferData*(buffer: ptr Buffer, data: pointer) =
  if buffer.bufferId == 0:
    glGenBuffers(1, buffer.bufferId.addr)

  let byteLength = buffer.count *
    buffer.kind.componentCount() *
    buffer.componentType.size()

  glBindBuffer(buffer.target, buffer.bufferId)
  glBufferData(
    buffer.target,
    byteLength,
    data,
    GL_STATIC_DRAW
  )
