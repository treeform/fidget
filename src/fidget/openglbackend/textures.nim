import os, streams, tables, strutils, times
import opengl, print, vmath, flippy

type
  TextureKind* = enum
    Texsture2d, CubeMap

  Texture* = ref object
    kind*: TextureKind
    id*: GLuint


proc texture*(image: Image): Texture =
  var texture = Texture()
  texture.kind = Texsture2d
  glGenTextures(1, texture.id.addr)
  glBindTexture(GL_TEXTURE_2D, texture.id)

  var target: GLenum = GL_TEXTURE_2D
  var level: GLint = 0
  var internalformat = GLint(GL_RGBA)
  var width: GLsizei = GLsizei image.width
  var height: GLsizei = GLsizei image.height
  var border: GLint = 0
  var format: GLenum = GL_RGBA
  var `type`: GLenum = GL_UNSIGNED_BYTE

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
  when defined(ios) or defined(android):
    glBindTexture(GL_TEXTURE_2D, texture.id)
    glTexSubImage2D(
      GL_TEXTURE_2D,
      level = GLint(level),
      xoffset = GLint(x),
      yoffset = GLint(y),
      width = GLsizei(image.width),
      height = GLsizei(image.height),
      format = GLenum GL_RGBA,
      `type` = GLenum GL_UNSIGNED_BYTE,
      pixels = cast[pointer](image.data[0].addr)
    )
  else:
    glTextureSubImage2D(
      texture = texture.id,
      level = GLint(level),
      xoffset = GLint(x),
      yoffset = GLint(y),
      width = GLsizei(image.width),
      height = GLsizei(image.height),
      format = GLenum GL_RGBA,
      `type` = GLenum GL_UNSIGNED_BYTE,
      pixels = cast[pointer](image.data[0].addr)
    )

proc updateSubImage*(texture: Texture, x, y: int, image: Image) =
  var
    x = x
    y = y
    level = 0
  # image.alphaBleed()
  var image = image
  while image.width > 1 and image.height > 1:
    texture.updateSubImage(x, y, image, level)
    image = image.minifyBy2()
    x = x div 2
    y = y div 2
    inc level
    break


proc textureBind*(texture:Texture, number:int) =
  glActiveTexture(GLenum(int(GL_TEXTURE0) + number))
  if texture.kind == CubeMap:
    glBindTexture(GL_TEXTURE_CUBE_MAP, texture.id)
  if texture.kind == Texsture2d:
    glBindTexture(GL_TEXTURE_2D, texture.id)
