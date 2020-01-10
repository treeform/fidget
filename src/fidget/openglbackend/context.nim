import tables, os, times, strformat
import vmath, chroma, flippy
import meshes, textures, shaders, slate
import opengl, base, print


type
  Context* = ref object
    entries*: ref Table[string, Rect] ## maping of image name to UV position in the texture

    mesh*: Mesh ## where the quads are drawn
    quadCount: int ## number of quads drawn so far
    maxQuads: int ## max quads to draw before issuing an openGL call and starting again.

    image*: Image ## Image of the atlas remove?
    texture*: Texture ## Texture of the atlas
    heights*: seq[uint16] ## Hight map of the free space in the atlas
    size*: int ## size x size dementions of the atlas
    margin*: int ## default margin between images
    shader*: GLuint
    mat*: Mat4 ## current matrix
    mats: seq[Mat4] ## matrix stack

    # mask
    maskImage*: Image ## Maskimage
    maskTexture*: Texture ## Mask texture
    maskFBO*: GLuint
    maskShader*: GLuint
    maskTextureId: GLuint


proc rect(x, y, w, h: int): Rect =
  ## integer rext to float rect
  rect(float32 x, float32 y, float32 w, float32 h)


proc translate*(ctx: Context, v: Vec2) =
  ## Translate the internal transform
  ctx.mat = ctx.mat * translate(vec3(v))


proc rotate*(ctx: Context, angle: float) =
  ## Rotates internal transform
  ctx.mat = ctx.mat * mat4(
    cos(angle),  sin(angle), 0, 0,
    -sin(angle), cos(angle), 0, 0,
    0,           0,          0, 0,
    0,           0,          0, 1
  )


proc scale*(ctx: Context, scale: float) =
  ## Rotates internal transform
  ctx.mat = ctx.mat * scaleMat(scale)


proc scale*(ctx: Context, scale: Vec2) =
  ## Rotates internal transform
  ctx.mat = ctx.mat * scaleMat(vec3(scale, 1))


proc saveTransform*(ctx: Context) =
  ## Pushes a transform onto the stack
  ctx.mats.add ctx.mat


proc restoreTransform*(ctx: Context) =
  ## Pushes a transform onto the stack
  ctx.mat = ctx.mats.pop()


proc clearTransform*(ctx: Context) =
  ## Clears transform and transform stack
  ctx.mat = mat4()
  ctx.mats.setLen(0)


proc fromScreen*(ctx: Context, windowFrame: Vec2, v: Vec2): Vec2 =
  ## Takes a point from screen and translates it to point inside the current transform
  (ctx.mat.inverse() * vec3(v.x, windowFrame.y - v.y, 0)).xy


proc toScreen*(ctx: Context, windowFrame: Vec2, v: Vec2): Vec2 =
  ## Takes a point from current transform and translates it to screen
  result = (ctx.mat * vec3(v, 1)).xy
  result.y = -result.y + windowFrame.y


when defined(ios) or defined(android):
  const
    atlastVertSrc = staticRead("atlas.es.vert")
    atlastFragSrc = staticRead("atlas.es.frag")
    maskVertSrc = staticRead("mask.es.vert")
    maskFragSrc = staticRead("mask.es.frag")
else:
  const
    atlastVertSrc = staticRead("atlas.vert")
    atlastFragSrc = staticRead("atlas.frag")
    maskVertSrc = staticRead("mask.vert")
    maskFragSrc = staticRead("mask.frag")


proc newContext*(
    size = 1024,
    margin = 4,
    maxQuads = 1024,
  ): Context =
  ## Creates a new context
  var ctx = Context()
  ctx.entries = newTable[string, Rect]()
  ctx.size = size
  ctx.margin = margin
  ctx.maxQuads = maxQuads
  ctx.mat = mat4()
  ctx.mats = newSeq[Mat4]()

  ctx.heights = newSeq[uint16](size)
  ctx.image = newImage("", size, size, 4)
  ctx.image.fill(rgba(255, 255, 255, 0))
  ctx.texture = ctx.image.texture()

  ctx.mesh = newUvColorMesh(size=maxQuads*2*3)

  ctx.mesh.loadShader(atlastVertSrc, atlastFragSrc)
  ctx.mesh.loadTexture("rgbaTex", ctx.texture)
  ctx.mesh.finalize()

  ctx.maskImage = newImage("", 1024, 1024, 4)
  ctx.maskImage.fill(rgba(255, 255, 255, 255))
  ctx.maskTexture = ctx.maskImage.texture()

  ctx.shader = compileShaderFiles(atlastVertSrc, atlastFragSrc)
  ctx.maskShader = compileShaderFiles(maskVertSrc, maskFragSrc)

  #ctx.mesh.loadShader(atlastVertSrc, atlastFragSrc)
  ctx.mesh.shader = ctx.shader
  ctx.mesh.loadTexture("rgbaTex", ctx.texture)
  ctx.mesh.loadTexture("rgbaMask", ctx.maskTexture)
  ctx.mesh.finalize()
  return ctx


proc findEmptyRect*(ctx: Context, width, height: int): Rect =
  var imgWidth = width + ctx.margin * 2
  var imgHeight = height + ctx.margin * 2

  var lowest = ctx.size
  var at = 0
  for i in 0..ctx.size - 1:
    var v = int(ctx.heights[i])
    if v < lowest:
      # found low point, is it consecutive?
      var fit = true
      for j in 0 .. imgWidth:
        if i + j >= ctx.size:
          fit = false
          break
        if int(ctx.heights[i + j]) > v:
          fit = false
          break
      if fit:
          # found!
          lowest = v
          at = i

  if lowest + imgHeight > ctx.size:
    raise newException(Exception, "Context Atlas is full")

  for j in at..at + imgWidth - 1:
    ctx.heights[j] = uint16(lowest + imgHeight + ctx.margin * 2)

  var rect = rect(
    float32(at + ctx.margin),
    float32(lowest + ctx.margin),
    float32(width),
    float32(height),
  )

  return rect


proc putImage*(ctx: Context, path: string, image: Image) =
  let rect = ctx.findEmptyRect(image.width, image.height)
  ctx.entries[path] = rect / float(ctx.size)
  ctx.texture.updateSubImage(
    int(rect.x),
    int(rect.y),
    image
  )


proc putSlate*(ctx: Context, path: string, slate: SlateImage) =
  let rect = ctx.findEmptyRect(slate.width, slate.height)
  ctx.entries[path] = rect / float(ctx.size)
  var
    x = int(rect.x)
    y = int(rect.y)
  for level, mip in slate.mipmaps:
    ctx.texture.updateSubImage(
      x,
      y,
      mip,
      level
    )
    x = x div 2
    y = y div 2


proc checkBatch*(ctx: Context) =
  if ctx.quadCount == ctx.maxQuads:
    # ctx is full dump the images in the ctx now and start a new batch
    ctx.mesh.upload(ctx.quadCount*6)
    ctx.mesh.drawBasic(ctx.mesh.mat, ctx.quadCount*6)
    ctx.quadCount = 0


proc drawUvRect*(
    ctx: Context,
    at: Vec2,
    to: Vec2,
    uvAt: Vec2,
    uvTo: Vec2,
    color: Color
  ) =
  ## Adds an image rect with a path to an ctx
  ctx.checkBatch()
  var
    posBuf = ctx.mesh.getBuf(Position)
    uvBuf = ctx.mesh.getBuf(Uv)
    colorBuf = ctx.mesh.getBuf(VertBufferKind.Color)

  let
    posQuad = [
      ctx.mat * vec3(at.x, to.y, 0.0),
      ctx.mat * vec3(at.x, at.y, 0.0),
      ctx.mat * vec3(to.x, at.y, 0.0),
      ctx.mat * vec3(to.x, to.y, 0.0),
    ]
    uvQuad = [
      vec2(uvAt.x , uvTo.y),
      vec2(uvAt.x , uvAt.y),
      vec2(uvTo.x , uvAt.y),
      vec2(uvTo.x , uvTo.y),
    ]

  assert ctx.quadCount < ctx.maxQuads

  let c = ctx.quadCount * 6
  posBuf.setVert3(c+0, posQuad[0])
  posBuf.setVert3(c+1, posQuad[2])
  posBuf.setVert3(c+2, posQuad[1])
  posBuf.setVert3(c+3, posQuad[2])
  posBuf.setVert3(c+4, posQuad[0])
  posBuf.setVert3(c+5, posQuad[3])

  uvBuf.setVert2(c+0, uvQuad[0])
  uvBuf.setVert2(c+1, uvQuad[2])
  uvBuf.setVert2(c+2, uvQuad[1])
  uvBuf.setVert2(c+3, uvQuad[2])
  uvBuf.setVert2(c+4, uvQuad[0])
  uvBuf.setVert2(c+5, uvQuad[3])

  colorBuf.setVertColor(c+0, color)
  colorBuf.setVertColor(c+1, color)
  colorBuf.setVertColor(c+2, color)
  colorBuf.setVertColor(c+3, color)
  colorBuf.setVertColor(c+4, color)
  colorBuf.setVertColor(c+5, color)

  inc ctx.quadCount


proc drawUvRect*(
    ctx: Context,
    rect: Rect,
    uvRect: Rect,
    color: Color
  ) =
  ctx.drawUvRect(rect.xy, rect.xy + rect.wh, uvRect.xy, uvRect.xy + uvRect.wh, color)


proc getOrLoadImageRect*(ctx: Context, imagePath: string): Rect =
  if imagePath notin ctx.entries:
    # need to load imagePath
    # check to see if approparte .slate file is around
    echo "[load] ", imagePath
    if not fileExists(imagePath):
      #quit(&"Image '{imagePath}' not found")
      raise newException(Exception, &"Image '{imagePath}' not found")
    let
      slateImagePath = imagePath.changeFileExt(".slate")
    if not existsFile(slateImagePath):
      # no slate file generate new one
      pngToSlate(imagePath, slateImagePath)
    else:
      let
        mtSlate = getLastModificationTime(slateImagePath).toUnix
        mtImage = getLastModificationTime(imagePath).toUnix
      if mtSlate < mtImage:
        # slate file too old, regenerate
        pngToSlate(imagePath, slateImagePath)
    var slate = loadSlate(slateImagePath)
    ctx.putSlate(imagePath, slate)
  return ctx.entries[imagePath]


proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0), color=color(1,1,1,1)) =
  ## Draws image the UI way - pos at top-left
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(pos, pos + wh, rect.xy, rect.xy + rect.wh, color)


proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0), size = vec2(0, 0), color=color(1,1,1,1)) =
  ## Draws image the UI way - pos at top-left
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(pos, pos + size, rect.xy, rect.xy + rect.wh, color)


proc drawSprite*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0), scale=1.0, color=color(1,1,1,1)) =
  ## Draws image the Game way pos at center
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.size) * scale
  ctx.drawUvRect(pos - wh/2, pos + wh/2, rect.xy, rect.xy + rect.wh, color)


proc fillRect*(ctx: Context, rect: Rect, color: Color) =
  let imgKey = "rect"
  if imgKey notin ctx.entries:
    var image = newImage(4, 4, 4)
    image.fill(rgba(255, 255, 255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(rect.xy, rect.xy + rect.wh, uvRect.xy + uvRect.wh/2, uvRect.xy + uvRect.wh/2, color)

proc fillRoundedRect*(ctx: Context, rect: Rect, color: Color, radius: float) =
  # TODO: Make this a 9 patch
  let
    imgKey = "roundedRect:" & $rect.wh & ":" & $radius
    w = int ceil(rect.w)
    h = int ceil(rect.h)
  if imgKey notin ctx.entries:
    var image = newImage(w, h, 4)
    image.fill(rgba(255, 255, 255, 0))
    image.fillRoundedRect(rect(0,0, rect.w, rect.h), radius, rgba(255, 255, 255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(rect.xy, rect.xy + vec2(float32 w, float32 h), uvRect.xy, uvRect.xy + uvRect.wh, color)

proc strokeRoundedRect*(ctx: Context, rect: Rect, color: Color, weight: float, radius: float) =
  # TODO: Make this a 9 patch
  let
    imgKey = "roundedRect:" & $rect.wh & ":" & $radius & ":" & $weight
    w = int ceil(rect.w)
    h = int ceil(rect.h)
  if imgKey notin ctx.entries:
    var image = newImage(w, h, 4)
    image.fill(rgba(255, 255, 255, 0))
    image.strokeRoundedRect(rect(0,0, rect.w, rect.h), radius, weight, rgba(255, 255, 255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(rect.xy, rect.xy + vec2(float32 w, float32 h), uvRect.xy, uvRect.xy + uvRect.wh, color)

proc drawMesh*(ctx: Context) =
  ## Flips - draws current buffer and starts a new one.
  if ctx.quadCount > 0:
    ctx.mesh.upload(ctx.quadCount*6)
    ctx.mesh.drawBasic(ctx.mesh.mat, ctx.quadCount*6)
    ctx.quadCount = 0


proc clearMask*(ctx: Context) =
  ## Sets mask off (acutally fills the mask with white)
  ctx.drawMesh()

  if ctx.maskFBO != 0:
    glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFBO)

    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)

    glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc beginMask*(ctx: Context) =
  ## Starts drawing into a mask.
  ctx.drawMesh()

  if ctx.maskFBO == 0:
    glGenFramebuffers(1, addr ctx.maskFBO)
    glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFBO)

    glGenTextures(1, addr ctx.maskTextureId)
    ctx.maskTexture.id = ctx.maskTextureId

    ctx.maskImage = Image()
    ctx.maskImage.width = (int windowFrame.x)
    ctx.maskImage.height = (int windowFrame.y)

    glBindTexture(GL_TEXTURE_2D, ctx.maskTextureId)
    glTexImage2D(GL_TEXTURE_2D, 0, GLint GL_RGBA, GLsizei ctx.maskImage.width, GLsizei ctx.maskImage.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ctx.maskTextureId, 0)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
      quit("Some thing wrong with frame buffer. 2")

  glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFBO)
  glViewport(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y)

  if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
    quit("Some thing wrong with frame buffer. 2")

  glClearColor(0, 0, 0, 0.0)
  glClear(GL_COLOR_BUFFER_BIT)

  ctx.mesh.shader = ctx.maskShader
  ctx.mesh.textures.setLen(0)
  ctx.mesh.loadTexture("rgbaTex", ctx.texture)


proc endMask*(ctx: Context) =
  ## Stops drawing into the mask.
  ctx.drawMesh()

  # var image = newImage("debug.png", int windowFrame.x, int windowFrame.y, 4)
  # glReadPixels(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y, GL_RGBA, GL_UNSIGNED_BYTE, addr image.data[0])
  # image.save()
  # if true: quit()

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glViewport(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y)

  ctx.mesh.shader = ctx.shader
  ctx.mesh.textures.setLen(0)
  ctx.mesh.loadTexture("rgbaTex", ctx.texture)
  ctx.mesh.loadTexture("rgbaMask", ctx.maskTexture)


proc startFrame*(ctx: Context, screenSize: Vec2) =
  ## Starts a new frame.
  if ctx.maskImage == nil or (ctx.maskImage.width != int screenSize.x) or
    (ctx.maskImage.height != int screenSize.y):
    ctx.maskImage.width = (int windowFrame.x)
    ctx.maskImage.height = (int windowFrame.y)
    glBindTexture(GL_TEXTURE_2D, ctx.maskTextureId)
    glTexImage2D(GL_TEXTURE_2D, 0, GLint GL_RGBA, GLsizei ctx.maskImage.width, GLsizei ctx.maskImage.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
    ctx.clearMask()


proc endFrame*(ctx: Context) =
  ## Ends a frame.
  ctx.drawMesh()

