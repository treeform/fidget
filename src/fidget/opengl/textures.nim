import flippy, opengl

proc initTexture*(image: Image): GLuint =
  ## Create a texture object.
  var textureId: GLuint

  glGenTextures(1, textureId.addr)
  glBindTexture(GL_TEXTURE_2D, textureId)

  var format: GLenum
  if image.channels == 4:
    format = GL_RGBA
  elif image.channels == 3:
    format = GL_RGB
  else:
    raise newException(
      ValueError,
      "Texture init error for " & $image & ", invalid channels value"
    )

  glTexImage2D(
    target = GL_TEXTURE_2D,
    level = 0,
    internalFormat = GLint(GL_RGBA),
    width = image.width.GLsizei,
    height = image.width.GLsizei,
    border = 0,
    format = format,
    `type` = GL_UNSIGNED_BYTE,
    pixels = cast[pointer](image.data[0].addr)
  )

  glGenerateMipmap(GL_TEXTURE_2D)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

  return textureId

proc updateSubImage*(textureId: GLuint, x, y: int, image: Image, level: int) =
  ## Update a small part of a texture image.
  glBindTexture(GL_TEXTURE_2D, textureId)
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

proc updateSubImage*(textureId: GLuint, x, y: int, image: Image) =
  ## Update a small part of texture with a new image.
  var
    x = x
    y = y
    image = image
    level = 0

  while image.width > 1 and image.height > 1:
    updateSubImage(textureId, x, y, image, level)
    image = image.minifyBy2()
    x = x div 2
    y = y div 2
    inc(level)

proc textureBind*(textureId: GLuint, number: int) =
  ## Bind the texture to a number.
  glActiveTexture(GLenum(int(GL_TEXTURE0) + number))
  glBindTexture(GL_TEXTURE_2D, textureId)
