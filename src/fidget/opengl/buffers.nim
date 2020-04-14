import opengl

type
  BufferKind* = enum
    bkSCALAR, bkVEC2, bkVEC3, bkVEC4, bkMAT2, bkMAT3, bkMAT4

  Buffer* = object
    data*: seq[uint8]
    count*: int
    componentType*: GLenum
    kind*: BufferKind
    normalized*: bool
    bufferId*: GLuint

func size*(componentType: GLenum): Positive =
  case componentType:
    of cGL_BYTE, cGL_UNSIGNED_BYTE:
      1
    of cGL_SHORT, cGL_UNSIGNED_SHORT:
      2
    of GL_UNSIGNED_INT, cGL_FLOAT:
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

proc bindBufferData*(buffer: ptr Buffer, target: GLenum) =
  if buffer.bufferId != 0:
    # This buffer has already been created
    return

  if len(buffer.data) == 0:
    # Empty, skip
    return

  let byteLength = buffer.count *
    buffer.kind.componentCount() *
    buffer.componentType.size()

  glGenBuffers(1, buffer.bufferId.addr)
  glBindBuffer(target, buffer.bufferId)

  glBufferData(
    target,
    byteLength,
    buffer.data[0].addr,
    GL_STATIC_DRAW
  )
