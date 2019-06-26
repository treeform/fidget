import tables, ospaths, os, times, strformat
import vmath, chroma, flippy
import base, meshs, textures, slate

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

    mat*: Mat4 ## current matrix
    mats: seq[Mat4] ## matrix stack


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

const
  atlastVertSrc = staticRead("atlas.vert")
  atlastFragSrc = staticRead("atlas.frag")

proc newContext*(
    size = 1024,
    margin = 4,
    maxQuads = 1024,
  ): Context =
  ## Creates a new context
  result = Context()
  result.entries = newTable[string, Rect]()
  result.size = size
  result.margin = margin
  result.maxQuads = maxQuads
  result.mat = mat4()
  result.mats = newSeq[Mat4]()

  result.heights = newSeq[uint16](size)
  result.image = newImage("", size, size, 4)
  result.image.fill(rgba(255, 255, 255, 0))
  result.texture = result.image.texture()

  result.mesh = newUvColorMesh()
  for i in 0..<result.maxQuads:
    result.mesh.addQuad(
      vec3(0, 0, 0), vec2(0, 0), color(0,0,0,0),
      vec3(0, 0, 0), vec2(0, 0), color(0,0,0,0),
      vec3(0, 0, 0), vec2(0, 0), color(0,0,0,0),
      vec3(0, 0, 0), vec2(0, 0), color(0,0,0,0),
    )
  result.mesh.loadShader(atlastVertSrc, atlastFragSrc)
  result.mesh.loadTexture("rgbaTex", result.texture)
  result.mesh.finalize()



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


proc drawSprite*(ctx: Context, imagePath: string, pos: Vec2 = vec2(0, 0), scale=1.0, color=color(1,1,1,1)) =
  ## Draws image the Game way pos at center
  let rect = ctx.getOrLoadImageRect(imagePath)
  let wh = rect.wh * float32(ctx.size) * scale
  ctx.drawUvRect(pos - wh/2, pos + wh/2, rect.xy, rect.xy + rect.wh, color)


proc fillRect*(ctx: Context, rect: Rect, color: Color) =
  let imgKey = "rect"
  if imgKey notin ctx.entries:
    var image = newImage(32, 32, 4)
    image.fill(rgba(255, 255, 255, 255))
    ctx.putImage(imgKey, image)
  let uvRect = ctx.entries[imgKey]
  let wh = rect.wh * float32(ctx.size)
  let halfPixel = vec2(1, 1) / float32(ctx.size) / 2
  ctx.drawUvRect(rect.xy, rect.xy + rect.wh, uvRect.xy + halfPixel, uvRect.xy + uvRect.wh - halfPixel, color)


proc flip*(ctx: Context) =
  ## Flips - draws current buffer and starts a new one.
  ctx.mesh.upload(ctx.quadCount*6)
  ctx.mesh.drawBasic(ctx.mesh.mat, ctx.quadCount*6)
  ctx.quadCount = 0