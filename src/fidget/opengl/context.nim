import ../uibase, base, buffers, chroma, flippy, opengl, os, shaders, strformat,
    tables, textures, times, vmath

const
  dir = "../fidget/src/fidget/opengl"
  atlasVert = (dir / "glsl/atlas.vert", staticRead("glsl/atlas.vert"))
  atlasFrag = (dir / "glsl/atlas.frag", staticRead("glsl/atlas.frag"))
  maskFrag = (dir / "glsl/mask.frag", staticRead("glsl/mask.frag"))

type
  Context* = ref object
    entries*: ref Table[string, Rect] ## Mapping of image name to UV position in the texture

    quadCount: int        ## Number of quads drawn so far
    maxQuads: int         ## Max quads to draw before issuing an OpenGL call and starting again

    atlas*: Texture     ## Texture of the atlas
    heights*: seq[uint16] ## Height map of the free space in the atlas
    size*: int            ## Size x size dimensions of the atlas
    margin*: int          ## Default margin between images
    shader*: Shader
    mat*: Mat4            ## Current matrix
    mats: seq[Mat4]       ## Matrix stack

    # mask
    mask*: Texture ## Mask texture
    maskFBO*: GLuint
    maskShader*: Shader

    vao*: GLuint

    activeShader*: Shader

    positions: tuple[buffer: Buffer, data: seq[float32]]
    colors: tuple[buffer: Buffer, data: seq[uint8]]
    uvs: tuple[buffer: Buffer, data: seq[float32]]

proc upload*(ctx: Context) =
  ## When buffers change, uploads them to GPU.
  ctx.positions.buffer.count = ctx.quadCount * 6
  ctx.colors.buffer.count = ctx.quadCount * 6
  ctx.uvs.buffer.count = ctx.quadCount * 6
  bindBufferData(ctx.positions.buffer.addr, ctx.positions.data[0].addr)
  bindBufferData(ctx.colors.buffer.addr, ctx.colors.data[0].addr)
  bindBufferData(ctx.uvs.buffer.addr, ctx.uvs.data[0].addr)

proc drawBasic*(ctx: Context, max: int) =
  ## Draw the basic mesh.
  glUseProgram(ctx.activeShader.programId)

  # Bind the regular uniforms:
  if ctx.activeShader.hasUniform("windowFrame"):
    ctx.activeShader.setUniform("windowFrame", windowFrame.x, windowFrame.y)
  ctx.activeShader.setUniform("proj", proj)

  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, ctx.atlas.textureId)
  ctx.activeShader.setUniform("rgbaTex", 0)

  if ctx.activeShader.hasUniform("rgbaMask"):
    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, ctx.mask.textureId)
    ctx.activeShader.setUniform("rgbaMask", 1)

  ctx.activeShader.bindUniforms()

  glDrawArrays(GL_TRIANGLES, 0, GLsizei max)

  # Unbind
  glBindVertexArray(0)
  glUseProgram(0)

proc rect*(x, y, w, h: int): Rect =
  ## Integer Rect to float Rect.
  rect(float32 x, float32 y, float32 w, float32 h)

proc translate*(ctx: Context, v: Vec2) =
  ## Translate the internal transform.
  ctx.mat = ctx.mat * translate(vec3(v))

proc rotate*(ctx: Context, angle: float) =
  ## Rotates internal transform.
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

proc newContext*(
  size = 1024,
  margin = 4,
  maxQuads = 1024,
): Context =
  ## Creates a new context.
  result = Context()
  result.entries = newTable[string, Rect]()
  result.size = size
  result.margin = margin
  result.maxQuads = maxQuads
  result.mat = mat4()
  result.mats = newSeq[Mat4]()

  result.heights = newSeq[uint16](size)
  let img = newImage("", size, size, 4)
  img.fill(rgba(255, 255, 255, 0))
  result.atlas = img.initTexture()

  let maskImage = newImage("", 1024, 1024, 4)
  maskImage.fill(rgba(255, 255, 255, 255))
  result.mask = maskImage.initTexture()

  result.shader = newShader(atlasVert, atlasFrag)
  result.maskShader = newShader(atlasVert, maskFrag)

  result.positions.buffer.componentType = cGL_FLOAT
  result.positions.buffer.kind = bkVEC2
  result.positions.buffer.target = GL_ARRAY_BUFFER
  result.positions.data = newSeq[float32](
    result.positions.buffer.kind.componentCount() * maxQuads * 6
  )

  result.colors.buffer.componentType = GL_UNSIGNED_BYTE
  result.colors.buffer.kind = bkVEC4
  result.colors.buffer.target = GL_ARRAY_BUFFER
  result.colors.buffer.normalized = true
  result.colors.data = newSeq[uint8](
    result.colors.buffer.kind.componentCount() * maxQuads * 6
  )

  result.uvs.buffer.componentType = cGL_FLOAT
  result.uvs.buffer.kind = bkVEC2
  result.uvs.buffer.target = GL_ARRAY_BUFFER
  result.uvs.data = newSeq[float32](
    result.uvs.buffer.kind.componentCount() * maxQuads * 6
  )

  result.activeShader = result.shader

  glGenVertexArrays(1, addr result.vao)
  result.upload()
  glBindVertexArray(result.vao)

  result.activeShader.bindAttrib("vertexPosition", result.positions.buffer)
  result.activeShader.bindAttrib("vertexColor", result.colors.buffer)
  result.activeShader.bindAttrib("vertexUv", result.uvs.buffer)

proc findEmptyRect(ctx: Context, width, height: int): Rect =
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
  updateSubImage(
    ctx.atlas,
    int(rect.x),
    int(rect.y),
    image
  )

proc putFlippy*(ctx: Context, path: string, flippy: Flippy) =
  let rect = ctx.findEmptyRect(flippy.width, flippy.height)
  ctx.entries[path] = rect / float(ctx.size)
  var
    x = int(rect.x)
    y = int(rect.y)
  for level, mip in flippy.mipmaps:
    updateSubImage(
      ctx.atlas,
      x,
      y,
      mip,
      level
    )
    x = x div 2
    y = y div 2

proc drawMesh*(ctx: Context) =
  ## Flips - draws current buffer and starts a new one.
  if ctx.quadCount > 0:
    ctx.upload()
    glBindVertexArray(ctx.vao)
    ctx.drawBasic(ctx.quadCount*6)
    ctx.quadCount = 0

proc checkBatch(ctx: Context) =
  if ctx.quadCount == ctx.maxQuads:
    # ctx is full dump the images in the ctx now and start a new batch
    ctx.drawMesh()

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
  let
    posQuad = [
      ctx.mat * vec2(at.x, to.y),
      ctx.mat * vec2(at.x, at.y),
      ctx.mat * vec2(to.x, at.y),
      ctx.mat * vec2(to.x, to.y),
    ]
    uvQuad = [
      vec2(uvAt.x, uvTo.y),
      vec2(uvAt.x, uvAt.y),
      vec2(uvTo.x, uvAt.y),
      vec2(uvTo.x, uvTo.y),
    ]

  assert ctx.quadCount < ctx.maxQuads

  let c = ctx.quadCount * 6
  ctx.positions.data.setVert2(c+0, posQuad[0])
  ctx.positions.data.setVert2(c+1, posQuad[2])
  ctx.positions.data.setVert2(c+2, posQuad[1])
  ctx.positions.data.setVert2(c+3, posQuad[2])
  ctx.positions.data.setVert2(c+4, posQuad[0])
  ctx.positions.data.setVert2(c+5, posQuad[3])

  ctx.uvs.data.setVert2(c+0, uvQuad[0])
  ctx.uvs.data.setVert2(c+1, uvQuad[2])
  ctx.uvs.data.setVert2(c+2, uvQuad[1])
  ctx.uvs.data.setVert2(c+3, uvQuad[2])
  ctx.uvs.data.setVert2(c+4, uvQuad[0])
  ctx.uvs.data.setVert2(c+5, uvQuad[3])

  let rgba = color.rgba()
  ctx.colors.data.setVertColor(c+0, rgba)
  ctx.colors.data.setVertColor(c+1, rgba)
  ctx.colors.data.setVertColor(c+2, rgba)
  ctx.colors.data.setVertColor(c+3, rgba)
  ctx.colors.data.setVertColor(c+4, rgba)
  ctx.colors.data.setVertColor(c+5, rgba)

  inc ctx.quadCount

proc drawUvRect*(
    ctx: Context,
    rect: Rect,
    uvRect: Rect,
    color: Color
  ) =
  ctx.drawUvRect(rect.xy, rect.xy + rect.wh, uvRect.xy, uvRect.xy + uvRect.wh, color)

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
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(pos, pos + wh, rect.xy, rect.xy + rect.wh, color)

proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    size = vec2(0, 0), color = color(1, 1, 1, 1)) =
  ## Draws image the UI way - pos at top-left.
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(pos, pos + size, rect.xy, rect.xy + rect.wh, color)

proc drawImage*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    scale = 1.0, color = color(1, 1, 1, 1)) =
  ## Draws image the UI way - pos at top-left.
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.size) * scale
  ctx.drawUvRect(pos, pos + wh, rect.xy, rect.xy + rect.wh, color)

proc drawSprite*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0),
    scale = 1.0, color = color(1, 1, 1, 1)) =
  ## Draws image the game way - pos at center.
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
  let wh = rect.wh * float32(ctx.size)
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
  let wh = rect.wh * float32(ctx.size)
  ctx.drawUvRect(rect.xy, rect.xy + vec2(float32 w, float32 h), uvRect.xy,
      uvRect.xy + uvRect.wh, color)

proc clearMask*(ctx: Context) =
  ## Sets mask off (actually fills the mask with white).
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

    ctx.mask.width = (int32 windowFrame.x)
    ctx.mask.height = (int32 windowFrame.y)

    glBindTexture(GL_TEXTURE_2D, ctx.mask.textureId)
    glTexImage2D(GL_TEXTURE_2D, 0, GLint GL_RGBA, ctx.mask.width,
      ctx.mask.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
        ctx.mask.textureId, 0)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
      quit("Some thing wrong with frame buffer. 2")

  glBindFramebuffer(GL_FRAMEBUFFER, ctx.maskFBO)
  glViewport(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y)

  if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
    quit("Some thing wrong with frame buffer. 2")

  glClearColor(0, 0, 0, 0.0)
  glClear(GL_COLOR_BUFFER_BIT)

  ctx.activeShader = ctx.maskShader

proc endMask*(ctx: Context) =
  ## Stops drawing into the mask.
  ctx.drawMesh()

  # var image = newImage("debug.png", int windowFrame.x, int windowFrame.y, 4)
  # glReadPixels(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y, GL_RGBA, GL_UNSIGNED_BYTE, addr image.data[0])
  # image.save()
  # if true: quit()

  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glViewport(0, 0, GLsizei windowFrame.x, GLsizei windowFrame.y)

  ctx.activeShader = ctx.shader

proc startFrame*(ctx: Context, screenSize: Vec2) =
  ## Starts a new frame.
  if (ctx.mask.width != int screenSize.x) or
    (ctx.mask.height != int screenSize.y):
    ctx.mask.width = (int32 windowFrame.x)
    ctx.mask.height = (int32 windowFrame.y)
    glBindTexture(GL_TEXTURE_2D, ctx.mask.textureId)
    glTexImage2D(GL_TEXTURE_2D, 0, GLint GL_RGBA, GLsizei ctx.mask.width,
        GLsizei ctx.mask.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
    ctx.clearMask()

proc endFrame*(ctx: Context) =
  ## Ends a frame.
  ctx.drawMesh()
