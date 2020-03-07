import opengl, flippy

type
  TextureKind* = enum
    Texture2D, CubeMap

  Texture* = object
    kind*: TextureKind
    id*: GLuint

proc initTexture*(image: Image): Texture =
  var texture = Texture()
  texture.kind = Texture2D

  glGenTextures(1, texture.id.addr)
  glBindTexture(GL_TEXTURE_2D, texture.id)

  var
    target: GLenum = GL_TEXTURE_2D
    level: GLint = 0
    internalformat = GLint(GL_RGBA)
    width: GLsizei = GLsizei image.width
    height: GLsizei = GLsizei image.height
    border: GLint = 0
    format: GLenum = GL_RGBA
    `type`: GLenum = GL_UNSIGNED_BYTE

  if image.channels == 4:
    format = GL_RGBA
  elif image.channels == 3:
    format = GL_RGB
  else:
    quit("image " & $image & " not supported")

  if image.format != 0:
    assert false
    var internalformat = cast[GLenum](image.format)
    glCompressedTexImage2D(
      target,
      level,
      internalformat,
      width,
      height,
      border,
      GLsizei image.data.len,
      cast[pointer](image.data[0].addr)
    )
  else:
    glTexImage2D(
      target,
      level,
      internalformat,
      width,
      height,
      border,
      format,
      `type`,
      cast[pointer](image.data[0].addr)
    )

  glGenerateMipmap(GL_TEXTURE_2D)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

  return texture

proc updateSubImage*(texture: Texture, x, y: int, image: Image, level: int) =
  glBindTexture(GL_TEXTURE_2D, texture.id)
  glTexSubImage2D(
    GL_TEXTURE_2D,
    level = GLint(level),
    xoffset = GLint(x),
    yoffset = GLint(y),
    width = GLsizei(image.width),
    height = GLsizei(image.height),
    format = GL_RGBA,
    `type` = GL_UNSIGNED_BYTE,
    pixels = cast[pointer](image.data[0].addr)
  )

proc updateSubImage*(texture: Texture, x, y: int, image: Image) =
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

proc textureBind*(texture: Texture, number: int) =
  glActiveTexture(GLenum(int(GL_TEXTURE0) + number))

  case texture.kind:
    of CubeMap:
      glBindTexture(GL_TEXTURE_CUBE_MAP, texture.id)
    of Texture2D:
      glBindTexture(GL_TEXTURE_2D, texture.id)
