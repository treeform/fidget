import buffers, chroma, flippy, opengl, os, shaders, strformat,
    tables, textures, times, vmath

const
  quadLimit = 10_921
  dir = "../fidget/src/fidget/opengl"
  atlasVert = (dir / "glsl/atlas.vert", staticRead("glsl/atlas.vert"))
  atlasFrag = (dir / "glsl/atlas.frag", staticRead("glsl/atlas.frag"))
  maskFrag = (dir / "glsl/mask.frag", staticRead("glsl/mask.frag"))

type
  Context* = ref object
    atlasShader, maskShader, activeShader: Shader
    atlasTexture, maskTexture: Texture
    positions: tuple[buffer: Buffer, data: seq[float32]]
    colors: tuple[buffer: Buffer, data: seq[uint8]]
    uvs: tuple[buffer: Buffer, data: seq[float32]]
    indices: tuple[buffer: Buffer, data: seq[uint16]]
    atlasSize: int   ## Size x size dimensions of the atlas
    atlasMargin: int ## Default margin between images
    quadCount: int   ## Number of quads drawn so far
    maxQuads: int    ## Max quads to draw before issuing an OpenGL call
    mat: Mat4        ## Current matrix
    mats: seq[Mat4]  ## Matrix stack
    entries*: Table[string, Rect] ## Mapping of image name to atlas UV position
    heights: seq[uint16]          ## Height map of the free space in the atlas
    proj: Mat4
    frameSize: Vec2 ## Dimensions of the window frame
    vertexArrayId, maskFramebufferId: GLuint

proc upload(ctx: Context) =
  ## When buffers change, uploads them to GPU.
  ctx.positions.buffer.count = ctx.quadCount * 4
  ctx.colors.buffer.count = ctx.quadCount * 4
  ctx.uvs.buffer.count = ctx.quadCount * 4
  ctx.indices.buffer.count = ctx.quadCount * 6
  bindBufferData(ctx.positions.buffer.addr, ctx.positions.data[0].addr)
  bindBufferData(ctx.colors.buffer.addr, ctx.colors.data[0].addr)
  bindBufferData(ctx.uvs.buffer.addr, ctx.uvs.data[0].addr)

proc newContext*(
  atlasSize = 1024,
  atlasMargin = 4,
  maxQuads = 1024,
): Context =
  ## Creates a new context.
  if maxQuads > quadLimit:
    raise newException(ValueError, &"Quads cannot exceed {quadLimit}")

  result = Context()
  result.atlasSize = atlasSize
  result.atlasMargin = atlasMargin
  result.maxQuads = maxQuads
  result.mat = mat4()
  result.mats = newSeq[Mat4]()

  result.heights = newSeq[uint16](atlasSize)
  let img = newImage("", atlasSize, atlasSize, 4)
  img.fill(rgba(255, 255, 255, 0))
  result.atlasTexture = img.initTexture()

  let defaultMask = newImage("", 4, 4, 4)
  defaultMask.fill(rgba(255, 255, 255, 255))

  result.maskTexture.width = defaultMask.width.int32
  result.maskTexture.height = defaultMask.height.int32
  result.maskTexture.componentType = GL_UNSIGNED_BYTE
  result.maskTexture.format = GL_RGBA
  result.maskTexture.internalFormat = GL_R8
  result.maskTexture.minFilter = minLinear
  result.maskTexture.magFilter = magLinear
  bindTextureData(result.maskTexture.addr, defaultMask.data[0].addr)

  result.atlasShader = newShader(atlasVert, atlasFrag)
  result.maskShader = newShader(atlasVert, maskFrag)

  result.positions.buffer.componentType = cGL_FLOAT
  result.positions.buffer.kind = bkVEC2
  result.positions.buffer.target = GL_ARRAY_BUFFER
  result.positions.data = newSeq[float32](
    result.positions.buffer.kind.componentCount() * maxQuads * 4
  )

  result.colors.buffer.componentType = GL_UNSIGNED_BYTE
  result.colors.buffer.kind = bkVEC4
  result.colors.buffer.target = GL_ARRAY_BUFFER
  result.colors.buffer.normalized = true
  result.colors.data = newSeq[uint8](
    result.colors.buffer.kind.componentCount() * maxQuads * 4
  )

  result.uvs.buffer.componentType = cGL_FLOAT
  result.uvs.buffer.kind = bkVEC2
  result.uvs.buffer.target = GL_ARRAY_BUFFER
  result.uvs.data = newSeq[float32](
    result.uvs.buffer.kind.componentCount() * maxQuads * 4
  )

  result.indices.buffer.componentType = GL_UNSIGNED_SHORT
  result.indices.buffer.kind = bkSCALAR
  result.indices.buffer.target = GL_ELEMENT_ARRAY_BUFFER
  result.indices.buffer.count = maxQuads * 6

  for i in 0 ..< maxQuads:
    let offset = i * 4
    result.indices.data.add([
      (offset + 3).uint16,
      (offset + 0).uint16,
      (offset + 1).uint16,
      (offset + 2).uint16,
      (offset + 3).uint16,
      (offset + 1).uint16,
    ])

  # Indices are only uploaded once
  bindBufferData(result.indices.buffer.addr, result.indices.data[0].addr)

  result.upload()

  result.activeShader = result.atlasShader

  glGenVertexArrays(1, result.vertexArrayId.addr)
  glBindVertexArray(result.vertexArrayId)

  result.activeShader.bindAttrib("vertexPos", result.positions.buffer)
  result.activeShader.bindAttrib("vertexColor", result.colors.buffer)
  result.activeShader.bindAttrib("vertexUv", result.uvs.buffer)

proc findEmptyRect(ctx: Context, width, height: int): Rect =
  var imgWidth = width + ctx.atlasMargin * 2
  var imgHeight = height + ctx.atlasMargin * 2

  var lowest = ctx.atlasSize
  var at = 0
  for i in 0..ctx.atlasSize - 1:
    var v = int(ctx.heights[i])
    if v < lowest:
      # found low point, is it consecutive?
      var fit = true
      for j in 0 .. imgWidth:
        if i + j >= ctx.atlasSize:
          fit = false
          break
        if int(ctx.heights[i + j]) > v:
          fit = false
          break
      if fit:
        # found!
        lowest = v
        at = i

  if lowest + imgHeight > ctx.atlasSize:
    raise newException(Exception, "Context Atlas is full")

  for j in at..at + imgWidth - 1:
    ctx.heights[j] = uint16(lowest + imgHeight + ctx.atlasMargin * 2)

  var rect = rect(
    float32(at + ctx.atlasMargin),
    float32(lowest + ctx.atlasMargin),
    float32(width),
    float32(height),
  )

  return rect

proc putImage*(ctx: Context, path: string, image: Image) =
  let rect = ctx.findEmptyRect(image.width, image.height)
  ctx.entries[path] = rect / float(ctx.atlasSize)
  updateSubImage(
    ctx.atlasTexture,
    int(rect.x),
    int(rect.y),
    image
  )

proc putFlippy*(ctx: Context, path: string, flippy: Flippy) =
  let rect = ctx.findEmptyRect(flippy.width, flippy.height)
  ctx.entries[path] = rect / float(ctx.atlasSize)
  var
    x = int(rect.x)
    y = int(rect.y)
  for level, mip in flippy.mipmaps:
    updateSubImage(
      ctx.atlasTexture,
      x,
      y,
      mip,
      level
    )
    x = x div 2
    y = y div 2

proc draw(ctx: Context) =
  ## Flips - draws current buffer and starts a new one.
  if ctx.quadCount == 0:
    return

  ctx.upload()

  glUseProgram(ctx.activeShader.programId)
  glBindVertexArray(ctx.vertexArrayId)

  if ctx.activeShader.hasUniform("windowFrame"):
    ctx.activeShader.setUniform("windowFrame", ctx.frameSize.x, ctx.frameSize.y)
  ctx.activeShader.setUniform("proj", ctx.proj)

  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, ctx.atlasTexture.textureId)
  ctx.activeShader.setUniform("atlasTex", 0)

  if ctx.activeShader.hasUniform("maskTex"):
    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, ctx.maskTexture.textureId)
    ctx.activeShader.setUniform("maskTex", 1)

  ctx.activeShader.bindUniforms()

  glBindBuffer(
    GL_ELEMENT_ARRAY_BUFFER,
    ctx.indices.buffer.bufferId
  )
  glDrawElements(
    GL_TRIANGLES,
    ctx.indices.buffer.count.GLint,
    ctx.indices.buffer.componentType,
    nil
  )

  ctx.quadCount = 0

proc checkBatch(ctx: Context) =
  if ctx.quadCount == ctx.maxQuads:
    # ctx is full dump the images in the ctx now and start a new batch
    ctx.draw()

proc setVert2(buf: var seq[float32], i: int, v: Vec2) =
  ## Set a vertex in the buffer.
  buf[i * 2 + 0] = v.x
  buf[i * 2 + 1] = v.y

proc setVertColor(buf: var seq[uint8], i: int, color: ColorRGBA) =
  ## Set a color in the buffer.
  buf[i * 4 + 0] = color.r
  buf[i * 4 + 1] = color.g
  buf[i * 4 + 2] = color.b
  buf[i * 4 + 3] = color.a

func `*`(m: Mat4, v: Vec2): Vec2 =
  (m * vec3(v, 0.0)).xy

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

  assert ctx.quadCount < ctx.maxQuads

  let
    posQuad = [
      ctx.mat * vec2(at.x, to.y),
      ctx.mat * vec2(to.x, to.y),
      ctx.mat * vec2(to.x, at.y),
      ctx.mat * vec2(at.x, at.y),
    ]
    uvQuad = [
      vec2(uvAt.x, uvTo.y),
      vec2(uvTo.x, uvTo.y),
      vec2(uvTo.x, uvAt.y),
      vec2(uvAt.x, uvAt.y),
    ]

  let offset = ctx.quadCount * 4
  ctx.positions.data.setVert2(offset + 0, posQuad[0])
  ctx.positions.data.setVert2(offset + 1, posQuad[1])
  ctx.positions.data.setVert2(offset + 2, posQuad[2])
  ctx.positions.data.setVert2(offset + 3, posQuad[3])

  ctx.uvs.data.setVert2(offset + 0, uvQuad[0])
  ctx.uvs.data.setVert2(offset + 1, uvQuad[1])
  ctx.uvs.data.setVert2(offset + 2, uvQuad[2])
  ctx.uvs.data.setVert2(offset + 3, uvQuad[3])

  let rgba = color.rgba()
  ctx.colors.data.setVertColor(offset + 0, rgba)
  ctx.colors.data.setVertColor(offset + 1, rgba)
  ctx.colors.data.setVertColor(offset + 2, rgba)
  ctx.colors.data.setVertColor(offset + 3, rgba)

  inc ctx.quadCount

proc drawUvRect*(
  ctx: Context,
  rect: Rect,
  uvRect: Rect,
  color: Color
) =
  ctx.drawUvRect(
    rect.xy,
    rect.xy + rect.wh,
    uvRect.xy,
    uvRect.xy + uvRect.wh,
    color
  )

proc getOrLoadImageRect(ctx: Context, imagePath: string): Rect =
  if imagePath notin ctx.entries:
    # need to load imagePath
    # check to see if approparte .flippy file is around
    echo "[load] ", imagePath
    if not fileExists(imagePath):
      #quit(&"Image '{imagePath}' not found")
      raise newException(Exception, &"Image '{imagePath}' not found")
    let
      flippyImagePath = imagePath.changeFileExt(".flippy")
    if not existsFile(flippyImagePath):
      # No Flippy file generate new one
      pngToFlippy(imagePath, flippyImagePath)
    else:
      let
        mtFlippy = getLastModificationTime(flippyImagePath).toUnix
        mtImage = getLastModificationTime(imagePath).toUnix
      if mtFlippy < mtImage:
        # Flippy file too old, regenerate
        pngToFlippy(imagePath, flippyImagePath)
    var flippy = loadFlippy(flippyImagePath)
    ctx.putFlippy(imagePath, flippy)
  return ctx.entries[imagePath]

proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    color = color(1, 1, 1, 1)) =
  ## Draws image the UI way - pos at top-left.
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.atlasSize)
  ctx.drawUvRect(pos, pos + wh, rect.xy, rect.xy + rect.wh, color)

proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    size = vec2(0, 0), color = color(1, 1, 1, 1)) =
  ## Draws image the UI way - pos at top-left.
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.atlasSize)
  ctx.drawUvRect(pos, pos + size, rect.xy, rect.xy + rect.wh, color)

proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    scale = 1.0, color = color(1, 1, 1, 1)) =
  ## Draws image the UI way - pos at top-left.
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.atlasSize) * scale
  ctx.drawUvRect(pos, pos + wh, rect.xy, rect.xy + rect.wh, color)

proc drawSprite*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    scale = 1.0, color = color(1, 1, 1, 1)) =
  ## Draws image the game way - pos at center.
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.atlasSize) * scale
  ctx.drawUvRect(pos - wh/2, pos + wh/2, rect.xy, rect.xy + rect.wh, color)

proc fillRect*(ctx: Context, rect: Rect, color: Color) =
  let imgKey = "rect"
  if imgKey notin ctx.entries:
    var image = newImage(4, 4, 4)
    image.fill(rgba(255, 255, 255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.atlasSize)
  ctx.drawUvRect(rect.xy, rect.xy + rect.wh, uvRect.xy + uvRect.wh/2,
      uvRect.xy + uvRect.wh/2, color)

proc fillRoundedRect*(ctx: Context, rect: Rect, color: Color, radius: float) =
  # TODO: Make this a 9 patch
  let
    imgKey = "roundedRect:" & $rect.wh & ":" & $radius
    w = int ceil(rect.w)
    h = int ceil(rect.h)
  if imgKey notin ctx.entries:
    var image = newImage(w, h, 4)
    image.fill(rgba(255, 255, 255, 0))
    image.fillRoundedRect(rect(0, 0, rect.w, rect.h), radius, rgba(255, 255,
        255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.atlasSize)
  ctx.drawUvRect(rect.xy, rect.xy + vec2(float32 w, float32 h), uvRect.xy,
      uvRect.xy + uvRect.wh, color)

proc strokeRoundedRect*(ctx: Context, rect: Rect, color: Color, weight: float,
    radius: float) =
  # TODO: Make this a 9 patch
  let
    imgKey = "roundedRect:" & $rect.wh & ":" & $radius & ":" & $weight
    w = int ceil(rect.w)
    h = int ceil(rect.h)
  if imgKey notin ctx.entries:
    var image = newImage(w, h, 4)
    image.fill(rgba(255, 255, 255, 0))
    image.strokeRoundedRect(rect(0, 0, rect.w, rect.h), radius, weight, rgba(
        255, 255, 255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.atlasSize)
  ctx.drawUvRect(rect.xy, rect.xy + vec2(float32 w, float32 h), uvRect.xy,
      uvRect.xy + uvRect.wh, color)

proc clearMask*(ctx: Context) =
  ## Sets mask off (actually fills the mask with white).
  ctx.draw()

  if ctx.maskFramebufferId != 0:
    glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFramebufferId)

    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)

    glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc beginMask*(ctx: Context) =
  ## Starts drawing into a mask.
  ctx.draw()

  if ctx.maskFramebufferId == 0:
    glGenFramebuffers(1, ctx.maskFramebufferId.addr)
    glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFramebufferId)

    bindTextureData(ctx.maskTexture.addr, nil)

    glFramebufferTexture2D(
      GL_FRAMEBUFFER,
      GL_COLOR_ATTACHMENT0,
      GL_TEXTURE_2D,
      ctx.maskTexture.textureId,
      0
    )

  glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFramebufferId)

  if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
    quit("Something wrong with frame buffer.")

  glClearColor(0, 0, 0, 0.0)
  glClear(GL_COLOR_BUFFER_BIT)

  ctx.activeShader = ctx.maskShader

proc endMask*(ctx: Context) =
  ## Stops drawing into the mask.
  ctx.draw()

  # var image = newImage("debug.png", int windowFrame.x, int windowFrame.y, 4)
  # glReadPixels(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y, GL_RGBA, GL_UNSIGNED_BYTE, addr image.data[0])
  # image.save()
  # if true: quit()

  glBindFramebuffer(GL_FRAMEBUFFER, 0)

  ctx.activeShader = ctx.atlasShader

proc startFrame*(ctx: Context, frameSize: Vec2, proj: Mat4) =
  ## Starts a new frame.
  ctx.proj = proj

  if ctx.maskTexture.width != frameSize.x.int32 or
    ctx.maskTexture.height != frameSize.y.int32:
    ctx.frameSize = frameSize
    ctx.maskTexture.width = frameSize.x.int32
    ctx.maskTexture.height = frameSize.y.int32
    bindTextureData(ctx.maskTexture.addr, nil)
    ctx.clearMask()

proc endFrame*(ctx: Context) =
  ## Ends a frame.
  ctx.draw()

proc translate*(ctx: Context, v: Vec2) =
  ## Translate the internal transform.
  ctx.mat = ctx.mat * translate(vec3(v))

proc rotate*(ctx: Context, angle: float) =
  ## Rotates the internal transform.
  ctx.mat = ctx.mat * rotateZ(angle).mat4()

proc scale*(ctx: Context, scale: float) =
  ## Scales the internal transform.
  ctx.mat = ctx.mat * scaleMat(scale)

proc scale*(ctx: Context, scale: Vec2) =
  ## Scales the internal transform.
  ctx.mat = ctx.mat * scaleMat(vec3(scale, 1))

proc saveTransform*(ctx: Context) =
  ## Pushes a transform onto the stack.
  ctx.mats.add ctx.mat

proc restoreTransform*(ctx: Context) =
  ## Pops a transform off the stack.
  ctx.mat = ctx.mats.pop()

proc clearTransform*(ctx: Context) =
  ## Clears transform and transform stack.
  ctx.mat = mat4()
  ctx.mats.setLen(0)

proc fromScreen*(ctx: Context, windowFrame: Vec2, v: Vec2): Vec2 =
  ## Takes a point from screen and translates it to point inside the current transform.
  (ctx.mat.inverse() * vec3(v.x, windowFrame.y - v.y, 0)).xy

proc toScreen*(ctx: Context, windowFrame: Vec2, v: Vec2): Vec2 =
  ## Takes a point from current transform and translates it to screen.
  result = (ctx.mat * vec3(v, 1)).xy
  result.y = -result.y + windowFrame.y
