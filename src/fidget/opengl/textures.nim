import flippy, opengl

type
  TextureKind* = enum
    ## Texture type.
    Texture2D, CubeMap

  Texture* = object
    ## Texture object.
    kind*: TextureKind
    id*: GLuint

proc initTexture*(image: Image): Texture =
  ## Create a texture object.
  var texture = Texture()
  texture.kind = Texture2D

  glGenTextures(1, texture.id.addr)
  glBindTexture(GL_TEXTURE_2D, texture.id)

  var
    target = GL_TEXTURE_2D
    level = 0.GLint
    internalFormat = GLint(GL_RGBA)
    width = image.width.GLsizei
    height = image.height.GLsizei
    border = 0.GLint
    format = GL_RGBA.GLenum
    `type` = GL_UNSIGNED_BYTE.GLenum

  if image.channels == 4:
    format = GL_RGBA
  elif image.channels == 3:
    format = GL_RGB
  else:
    quit("image " & $image & " not supported")

  glTexImage2D(
    target,
    level,
    internalFormat,
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
  ## Update a small part of a texture image.
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

proc textureBind*(texture: Texture, number: int) =
  ## Bind the texture to a number.
  glActiveTexture(GLenum(int(GL_TEXTURE0) + number))

  case texture.kind:
    of CubeMap:
      glBindTexture(GL_TEXTURE_CUBE_MAP, texture.id)
    of Texture2D:
      glBindTexture(GL_TEXTURE_2D, texture.id)
