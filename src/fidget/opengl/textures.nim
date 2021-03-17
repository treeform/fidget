import buffers, pixie, opengl

type
  MinFilter* = enum
    minDefault,
    minNearest = GL_NEAREST,
    minLinear = GL_LINEAR,
    minNearestMipmapNearest = GL_NEAREST_MIPMAP_NEAREST,
    minLinearMipmapNearest = GL_LINEAR_MIPMAP_NEAREST,
    minNearestMipmapLinear = GL_NEAREST_MIPMAP_LINEAR,
    minLinearMipmapLinear = GL_LINEAR_MIPMAP_LINEAR

  MagFilter* = enum
    magDefault,
    magNearest = GL_NEAREST,
    magLinear = GL_LINEAR

  Wrap* = enum
    wDefault,
    wRepeat = GL_REPEAT,
    wClampToEdge = GL_CLAMP_TO_EDGE,
    wMirroredRepeat = GL_MIRRORED_REPEAT

  Texture* = object
    width*, height*: int32
    componentType*, format*, internalFormat*: GLenum
    minFilter*: MinFilter
    magFilter*: MagFilter
    wrapS*, wrapT*: Wrap
    genMipmap*: bool
    textureId*: GLuint

proc bindTextureBufferData*(
  texture: ptr Texture, buffer: ptr Buffer, data: pointer
) =
  bindBufferData(buffer, data)

  if texture.textureId == 0:
    glGenTextures(1, texture.textureId.addr)

  glBindTexture(GL_TEXTURE_BUFFER, texture.textureId)
  glTexBuffer(
    GL_TEXTURE_BUFFER,
    texture.internalFormat,
    buffer.bufferId
  )

proc bindTextureData*(texture: ptr Texture, data: pointer) =
  if texture.textureId == 0:
    glGenTextures(1, texture.textureId.addr)

  glBindTexture(GL_TEXTURE_2D, texture.textureId)
  glTexImage2D(
    target = GL_TEXTURE_2D,
    level = 0,
    internalFormat = texture.internalFormat.GLint,
    width = texture.width,
    height = texture.height,
    border = 0,
    format = texture.format,
    `type` = texture.componentType,
    pixels = data
  )

  if texture.magFilter != magDefault:
    glTexParameteri(
      GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, texture.magFilter.GLint
    )
  if texture.minFilter != minDefault:
    glTexParameteri(
      GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, texture.minFilter.GLint
    )
  if texture.wrapS != wDefault:
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, texture.wrapS.GLint)
  if texture.wrapT != wDefault:
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, texture.wrapT.GLint)

  if texture.genMipmap:
    glGenerateMipmap(GL_TEXTURE_2D)

func getFormat(image: Image): GLenum =
  result = GL_RGBA

proc initTexture*(image: Image): Texture =
  result.width = image.width.GLint
  result.height = image.height.GLint
  result.componentType = GL_UNSIGNED_BYTE
  result.format = image.getFormat()
  result.internalFormat = GL_RGBA8
  result.genMipmap = true
  result.minFilter = minLinearMipmapLinear
  result.magFilter = magLinear
  var data = newSeq[ColorRGBA](image.width * image.height)
  for i in 0 ..< data.len:
    data[i] = image.data[i]
  bindTextureData(result.addr, data[0].addr)

proc updateSubImage*(texture: Texture, x, y: int, image: Image, level: int) =
  ## Update a small part of a texture image.
  var data = newSeq[ColorRGBA](image.width * image.height)
  for i in 0 ..< data.len:
    data[i] = image.data[i]
  glBindTexture(GL_TEXTURE_2D, texture.textureId)
  glTexSubImage2D(
    GL_TEXTURE_2D,
    level = level.GLint,
    xoffset = x.GLint,
    yoffset = y.GLint,
    width = image.width.GLint,
    height = image.height.GLint,
    format = image.getFormat(),
    `type` = GL_UNSIGNED_BYTE,
    pixels = data[0].addr
  )

proc updateSubImage*(texture: Texture, x, y: int, image: Image) =
  ## Update a small part of texture with a new image.
  var
    x = x
    y = y
    image = image
    level = 0

  while image.width > 1 and image.height > 1:
    texture.updateSubImage(x, y, image, level)
    image = image.minifyBy2()
    x = x div 2
    y = y div 2
    inc(level)
