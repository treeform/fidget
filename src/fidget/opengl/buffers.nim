import fidget/opengl/accessors, opengl

type
  Buffer* = object
    data*: seq[uint8]
    count*: int
    componentType*: GLenum
    kind*: AccessorKind
    normalized*: bool
    bufferId*: GLuint

proc bindBufferData*(buffer: ptr Buffer, target: GLenum) =
  if buffer.bufferId == 0:
    # This buffer needs to be sent to the GPU

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
