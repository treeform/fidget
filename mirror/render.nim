
import flippy, flippy/paths, chroma, chroma/blends, math, vmath, schema, print, typography, bumpy

const
  white = rgba(255, 255, 255, 255)
  clear = rgba(0, 0, 0, 0)

var
  mainCtx*: Image
  ctx*: Image
  fillMaskCtx: Image
  strokeMaskCtx: Image
  effectsCtx: Image
  maskStack: seq[Image]
  nodeStack: seq[Node]
  parentNode: Node
  framePos*: Vec2

# proc frameFills(node: Node) =
#   if node.fills.len > 0:
#     for fill in node.fills:
#       mainCtx.fillRect(
#         rect(
#           node.absoluteBoundingBox.x + framePos.x,
#           node.absoluteBoundingBox.y + framePos.y,
#           node.absoluteBoundingBox.width,
#           node.absoluteBoundingBox.height,
#         ),
#         fill.color.rgba
#       )

proc drawNode*(node: Node)

proc drawChildren(node: Node) =
  parentNode = node
  nodeStack.add(node)

  # Is there a mask?
  var haveMask = false
  for child in node.children:
    if child.isMask:
      haveMask = true

  if haveMask:
    var tmpCtx = ctx
    ctx = newImage(tmpCtx.width, tmpCtx.height, 4)

    # Draw masked children first:
    for child in node.children:
      if child.isMask:
        drawNode(child)

    maskStack.add(ctx)
    ctx = tmpCtx

  # Draw regular children:
  for child in node.children:
    if not child.isMask:
      drawNode(child)

  if haveMask:
    discard maskStack.pop()

  discard nodeStack.pop()
  if nodeStack.len > 0:
    parentNode = nodeStack[^1]

proc gradientPut(effectsCtx: Image, x, y: int, a: float32, fill: Paint) =
  var
    index = -1
  for i, stop in fill.gradientStops:
    if stop.position < a:
      index = i
    if stop.position > a:
      break
  var color: Color
  if index == -1:
    # first stop solid
    color = fill.gradientStops[0].color
  elif index + 1 >= fill.gradientStops.len:
    # last stop solid
    color = fill.gradientStops[index].color
  else:
    let
      gs1 = fill.gradientStops[index]
      gs2 = fill.gradientStops[index+1]
    color = mix(
      gs1.color,
      gs2.color,
      (a - gs1.position) / (gs2.position - gs1.position)
    )
  effectsCtx.putRgbaUnsafe(x, y, color.rgba)

proc applyPaint(maskCtx: Image, fill: Paint, node: Node, orgPos: Vec2) =
  let pos = node.absoluteBoundingBox.xy + orgPos

  proc toImageSpace(handle: Vec2): Vec2 =
    vec2(
      handle.x * node.absoluteBoundingBox.width + pos.x,
      handle.y * node.absoluteBoundingBox.height + pos.y,
    )

  proc toLineSpace(at, to, point: Vec2): float32 =
    let
      d = to - at
      det = d.x*d.x + d.y*d.y
    return (d.y*(point.y-at.y)+d.x*(point.x-at.x))/det

  effectsCtx.fill(clear)

  if fill.`type` == "IMAGE":
    var image = loadImage("images/" & fill.imageRef)

    if fill.scaleMode == "FILL":
      let
        ratioW = image.width.float32 / node.absoluteBoundingBox.width
        ratioH = image.height.float32 / node.absoluteBoundingBox.height
        scale = min(ratioW, ratioH)
      image = image.resize(int(image.width.float32 / scale), int(image.height.float32 / scale))
      let center = node.absoluteBoundingBox.wh
      let topRight = pos + center/2 - vec2(image.width/2, image.height/2)
      effectsCtx.blit(image, topRight)

    elif fill.scaleMode == "FIT":
      let
        ratioW = image.width.float32 / node.absoluteBoundingBox.width
        ratioH = image.height.float32 / node.absoluteBoundingBox.height
        scale = max(ratioW, ratioH)
      image = image.resize(int(image.width.float32 / scale), int(image.height.float32 / scale))
      let center = node.absoluteBoundingBox.wh
      let topRight = pos + center/2 - vec2(image.width/2, image.height/2)
      effectsCtx.blit(image, topRight)

    elif fill.scaleMode == "STRETCH": # Figma ui calls this "crop".
      var mat: Mat4
      mat[ 0] = fill.imageTransform[0][0]
      mat[ 1] = fill.imageTransform[0][1]
      mat[ 2] = 0
      mat[ 3] = 0
      mat[ 4] = fill.imageTransform[1][0]
      mat[ 5] = fill.imageTransform[1][1]
      mat[ 6] = 0
      mat[ 7] = 0
      mat[ 8] = 0
      mat[ 9] = 0
      mat[10] = 1
      mat[11] = 0
      mat[12] = fill.imageTransform[0][2]
      mat[13] = fill.imageTransform[1][2]
      mat[14] = 0
      mat[15] = 1
      mat = mat.inverse()
      mat[12] = pos.x + mat[12] * node.absoluteBoundingBox.width
      mat[13] = pos.y + mat[13] * node.absoluteBoundingBox.height
      let
        ratioW = image.width.float32 / node.absoluteBoundingBox.width
        ratioH = image.height.float32 / node.absoluteBoundingBox.height
        scale = min(ratioW, ratioH)
      # TODO: Don't scale the image, just scale the matrix.
      image = image.resize(int(image.width.float32 / scale), int(image.height.float32 / scale))
      effectsCtx.blitWithAlpha(image, mat)

    elif fill.scaleMode == "TILE":
      image = image.resize(
        int(image.width.float32 * fill.scalingFactor),
        int(image.height.float32 * fill.scalingFactor))
      var x = 0.0
      while x < node.absoluteBoundingBox.width:
        var y = 0.0
        while y < node.absoluteBoundingBox.height:
          effectsCtx.blit(image, pos + vec2(x, y))
          y += image.height.float32
        x += image.width.float32

  elif fill.`type` == "GRADIENT_LINEAR":
    let
      at = fill.gradientHandlePositions[0].toImageSpace()
      to = fill.gradientHandlePositions[1].toImageSpace()
    for y in 0 ..< effectsCtx.height:
      for x in 0 ..< effectsCtx.width:
        let xy = vec2(x.float32, y.float32)
        let a = toLineSpace(at, to, xy)
        effectsCtx.gradientPut(x, y, a, fill)

  elif fill.`type` == "GRADIENT_RADIAL":
    let
      at = fill.gradientHandlePositions[0].toImageSpace()
      to = fill.gradientHandlePositions[1].toImageSpace()
      distance = dist(at, to)
    for y in 0 ..< effectsCtx.height:
      for x in 0 ..< effectsCtx.width:
        let xy = vec2(x.float32, y.float32)
        let a = (at - xy).length() / distance
        effectsCtx.gradientPut(x, y, a, fill)

  elif fill.`type` == "GRADIENT_ANGULAR":
    let
      at = fill.gradientHandlePositions[0].toImageSpace()
      to = fill.gradientHandlePositions[1].toImageSpace()
      gradientAngle = normalize(to - at).angle().fixAngle()
    for y in 0 ..< effectsCtx.height:
      for x in 0 ..< effectsCtx.width:
        let
          xy = vec2(x.float32, y.float32)
          angle = normalize(xy - at).angle()
          a = (angle + gradientAngle + PI/2).fixAngle() / 2 / PI + 0.5
        effectsCtx.gradientPut(x, y, a, fill)

  elif fill.`type` == "GRADIENT_DIAMOND":
    # TODO: implement GRADIENT_DIAMOND, now will just do GRADIENT_RADIAL
    let
      at = fill.gradientHandlePositions[0].toImageSpace()
      to = fill.gradientHandlePositions[1].toImageSpace()
      distance = dist(at, to)
    for y in 0 ..< effectsCtx.height:
      for x in 0 ..< effectsCtx.width:
        let xy = vec2(x.float32, y.float32)
        let a = (at - xy).length() / distance
        effectsCtx.gradientPut(x, y, a, fill)

  elif fill.`type` == "SOLID":
    effectsCtx.fill(fill.color.rgba)

  # TODO: Fix masking.
  #if maskStack.len > 0:
  #  maskCtx.blitMaskStack(maskStack)

  #effectsCtx.save("nodes/" & node.name & ".effectsCtx.png")
  #maskCtx.save("nodes/" & node.name & "maskCtx.png")

  ctx.blitMasked(effectsCtx, maskCtx)

proc applyDropShadowEffect(effect: Effect, node: Node) =
  ## Draws the drop shadow.
  var shadowCtx = fillMaskCtx.blur(effect.radius)
  shadowCtx.colorAlpha(effect.color)
  # Draw it back.
  var maskingCtx = newImage(ctx.width, ctx.height, 4)
  maskingCtx.fill(white)
  if maskStack.len > 0:
    maskingCtx.blitMaskStack(maskStack)
  ctx.blitMasked(shadowCtx, maskingCtx)

proc applyInnerShadowEffect(effect: Effect, node: Node) =
  ## Draws the inner shadow.
  var shadowCtx = fillMaskCtx.copy()
  shadowCtx.invertColor()
  shadowCtx = shadowCtx.blur(effect.radius)
  shadowCtx.colorAlpha(effect.color)
  # Draw it back.
  var maskingCtx = fillMaskCtx.copy()
  if maskStack.len > 0:
    maskingCtx.blitMaskStack(maskStack)
  ctx.blitMasked(shadowCtx, maskingCtx)

proc roundRect(path: Path, x, y, w, h, nw, ne, se, sw: float32) =
  path.moveTo(x+nw, y)
  path.arcTo(x+w, y,   x+w, y+h, ne)
  path.arcTo(x+w, y+h, x,   y+h, se)
  path.arcTo(x,   y+h, x,   y,   sw)
  path.arcTo(x,   y,   x+w, y,   nw)
  path.closePath()

proc roundRectRev(path: Path, x, y, w, h, nw, ne, se, sw: float32) =
  path.moveTo(x+w+ne, y)

  path.arcTo(x,   y,   x,   y+h,   nw)
  path.arcTo(x,   y+h, x+w, y+h,   sw)
  path.arcTo(x+w, y+h, x+w, y, se)
  path.arcTo(x+w, y,   x,   y, ne)

  path.closePath()

proc checkDirty(node: Node) =
  ## Makes sure if children are dirty, parents are dirty too!
  for c in node.children:
    checkDirty(c)
    if c.dirty == true:
      node.dirty = true

proc drawCompleteFrame*(node: Node): Image =
  ## Draws full frame that is ready to be displayed.
  if mainCtx == nil:
    mainCtx = newImage(
      node.absoluteBoundingBox.width.int,
      node.absoluteBoundingBox.height.int,
      4)
    fillMaskCtx = newImage(mainCtx.width, mainCtx.height, 4)
    strokeMaskCtx = newImage(mainCtx.width, mainCtx.height, 4)
    effectsCtx = newImage(mainCtx.width, mainCtx.height, 4)
  else:
    mainCtx.fill(clear)
    fillMaskCtx.fill(clear)
    effectsCtx.fill(clear)

  framePos = vec2(
    -node.absoluteBoundingBox.x,
    -node.absoluteBoundingBox.y
  )
  checkDirty(node)
  drawNode(node)

  assert mainCtx != nil
  assert node.pixels != nil

  mainCtx.blitWithBlendMode(
    node.pixels, parseBlendMode(node.blendMode), vec2(0, 0))

  return mainCtx

proc `and`(a, b: Rect): Rect =
  ## Take a and b bounding Rectangles and return a bounding rectangle that
  ## overlaps them both.
  result.x = min(a.x, b.x)
  result.y = min(a.y, b.y)
  result.w = max(a.x + a.w, b.x + b.w) - result.x
  result.h = max(a.y + a.h, b.y + b.h) - result.y

proc computePixelBox*(node: Node) =
  ## Computes pixel bounds.
  ## Takes into account width, height and shadow extent, and children.
  node.pixelBox.xy = node.absoluteBoundingBox.xy + framePos
  node.pixelBox.wh = node.absoluteBoundingBox.wh

  # Take drop shadow into account:
  var s = 0.0
  for effect in node.effects:
    if effect.`type` == "DROP_SHADOW":
      s = max(s, effect.radius + effect.spread)
  node.pixelBox.xy = node.pixelBox.xy + vec2(s, s)
  node.pixelBox.wh = node.pixelBox.wh + vec2(s, s)

  # Take children into account:
  for child in node.children:
    child.computePixelBox()
    node.pixelBox = node.pixelBox and child.pixelBox

proc drawNode*(node: Node) =
  ## Draws a node.
  ## Note: Must be called inside drawCompleteFrame.

  if node.pixels != nil and node.dirty == false:
    # Nothing to do, node.pixels contains the cached version.
    return

  node.computePixelBox()

  # Make sure node.pixels is there and is the right size:
  let
    w = ceil(node.pixelBox.w).int
    h = ceil(node.pixelBox.w).int
  if node.pixels == nil or node.pixels.width != w or node.pixels.height != h:
    node.pixels = newImage(w, h, 4)
  else:
    node.pixels.fill(clear)

  # TODO: make sure we need the supporting images.
  fillMaskCtx = newImage(w, h, 4)
  strokeMaskCtx = newImage(w, h, 4)
  effectsCtx = newImage(w, h, 4)
  ctx = node.pixels
  var orgPos = framePos - node.pixelBox.xy

  case node.`type`
  of "DOCUMENT", "CANVAS":
    quit(node.`type` & " can't be drawn.")

  # of "FRAME", "GROUP", "COMPONENT", "INSTANCE":
  #   parentNode = node
  #   frameFills(node)
  #   drawChildren(node)
  #   return

  of "RECTANGLE", "FRAME", "GROUP", "COMPONENT", "INSTANCE":
    if node.fills.len > 0:
      fillMaskCtx.fill(clear)
      if node.cornerRadius > 0:
        # Rectangle with common corners.
        var path = newPath()
        path.roundRect(
          x = node.absoluteBoundingBox.x + orgPos.x,
          y = node.absoluteBoundingBox.y + orgPos.y,
          w = node.absoluteBoundingBox.width,
          h = node.absoluteBoundingBox.height,
          nw = node.cornerRadius,
          ne = node.cornerRadius,
          se = node.cornerRadius,
          sw = node.cornerRadius
        )
        fillMaskCtx.fillPolygon(
          path,
          white
        )
      elif node.rectangleCornerRadii.len == 4:
        # Rectangle with different corners.
        var path = newPath()
        path.roundRect(
          x = node.absoluteBoundingBox.x + orgPos.x,
          y = node.absoluteBoundingBox.y + orgPos.y,
          w = node.absoluteBoundingBox.width,
          h = node.absoluteBoundingBox.height,
          nw = node.rectangleCornerRadii[0],
          ne = node.rectangleCornerRadii[1],
          se = node.rectangleCornerRadii[2],
          sw = node.rectangleCornerRadii[3],
        )
        fillMaskCtx.fillPolygon(
          path,
          white
        )
      else:
        # Basic rectangle.
        fillMaskCtx.fillRect(
          rect(
            node.absoluteBoundingBox.x + orgPos.x,
            node.absoluteBoundingBox.y + orgPos.y,
            node.absoluteBoundingBox.width,
            node.absoluteBoundingBox.height,
          ),
          white
        )

    if node.strokes.len > 0:
      strokeMaskCtx.fill(clear)
      let
        x = node.absoluteBoundingBox.x + orgPos.x
        y = node.absoluteBoundingBox.y + orgPos.y
        w = node.absoluteBoundingBox.width
        h = node.absoluteBoundingBox.height
      var
        inner = 0.0
        outer = 0.0
        path: Path
      if node.strokeAlign == "INSIDE":
        inner = node.strokeWeight
      elif node.strokeAlign == "OUTSIDE":
        outer = node.strokeWeight
      elif node.strokeAlign == "CENTER":
        inner = node.strokeWeight / 2
        outer = node.strokeWeight / 2
      else:
        quit("invalid strokeWeight")

      if node.cornerRadius > 0:
        # Rectangle with common corners.
        let
          x = node.absoluteBoundingBox.x + orgPos.x
          y = node.absoluteBoundingBox.y + orgPos.y
          w = node.absoluteBoundingBox.width
          h = node.absoluteBoundingBox.height
          r = node.cornerRadius
        path = newPath()
        path.roundRect(x-outer,y-outer,w+outer*2,h+outer*2,r+outer,r+outer,r+outer,r+outer)
        path.roundRectRev(x+inner,y+inner,w-inner*2,h-inner*2,r-inner,r-inner,r-inner,r-inner)

      elif node.rectangleCornerRadii.len == 4:
        # Rectangle with different corners.
        path = newPath()
        let
          x = node.absoluteBoundingBox.x + orgPos.x
          y = node.absoluteBoundingBox.y + orgPos.y
          w = node.absoluteBoundingBox.width
          h = node.absoluteBoundingBox.height
          nw = node.rectangleCornerRadii[0]
          ne = node.rectangleCornerRadii[1]
          se = node.rectangleCornerRadii[2]
          sw = node.rectangleCornerRadii[3]
        path.roundRect(x-outer,y-outer,w+outer*2,h+outer*2,nw+outer,ne+outer,se+outer,sw+outer)
        path.roundRectRev(x+inner,y+inner,w-inner*2,h-inner*2,nw-inner,ne-inner,se-inner,sw-inner)

      else:
        path = newPath()
        path.moveTo(x-outer, y-outer)
        path.lineTo(x+w+outer, y-outer,  )
        path.lineTo(x+w+outer, y+h+outer,)
        path.lineTo(x-outer,   y+h+outer,)
        path.lineTo(x-outer,   y-outer,  )
        path.closePath()

        path.moveTo(x+inner, y+inner)
        path.lineTo(x+inner,   y+h-inner)
        path.lineTo(x+w-inner, y+h-inner)
        path.lineTo(x+w-inner, y+inner)
        path.lineTo(x+inner,   y+inner)
        path.closePath()

      strokeMaskCtx.fillPolygon(
        path,
        white
      )

  of "VECTOR", "STAR":
    if node.fills.len > 0:
      fillMaskCtx.fill(clear)
      for geometry in node.fillGeometry:
        let pos = node.absoluteBoundingBox.xy + orgPos
        fillMaskCtx.fillPolygon(
          geometry.path,
          white,
          pos
        )

    if node.strokes.len > 0:
      strokeMaskCtx.fill(clear)
      for geometry in node.strokeGeometry:
        let pos = node.absoluteBoundingBox.xy + orgPos
        strokeMaskCtx.fillPolygon(
          geometry.path,
          white,
          pos
        )

  of "TEXT":

    func hAlignCase(s: string): HAlignMode =
      case s
      of "CENTER": return Center
      of "LEFT": return Left
      of "RIGHT": return Right
      else: return Left

    func vAlignCase(s: string): VAlignMode =
      case s
      of "CENTER": return Middle
      of "TOP": return Top
      of "BOTTOM": return Bottom
      else: Top

    let pos = node.absoluteBoundingBox.xy + orgPos
    var font = readFontTtf("fonts/" & node.style.fontFamily & ".ttf")
    font.size = node.style.fontSize
    font.lineHeight = node.style.lineHeightPx

    let layout = font.typeset(
      text = node.characters,
      pos = pos,
      size = node.absoluteBoundingBox.wh,
      hAlign = hAlignCase(node.style.textAlignHorizontal),
      vAlign = vAlignCase(node.style.textAlignVertical)
    )
    fillMaskCtx.fill(clear)
    fillMaskCtx.drawText(layout)

  for effect in node.effects:
    if effect.`type` == "DROP_SHADOW":
      applyDropShadowEffect(effect, node)

  for fill in node.fills:
    applyPaint(fillMaskCtx, fill, node, orgPos)

  for stroke in node.strokes:
    applyPaint(strokeMaskCtx, stroke, node, orgPos)

  # TODO: fix INNER_SHADOW
  # for effect in node.effects:
  #   if effect.`type` == "INNER_SHADOW":
  #     applyInnerShadowEffect(effect, node)

  drawChildren(node)
  for child in node.children:
    node.pixels.blitWithBlendMode(
      child.pixels,
      parseBlendMode(child.blendMode),
      child.pixelBox.xy - node.pixelBox.xy
    )

  print "  draw", node.name, node.pixelBox
  node.dirty = false
  assert node.pixels != nil

  #node.pixels.save("nodes/" & node.name & ".pixels.png")

  #mainCtx.blitWithBlendMode(node.pixels, parseBlendMode(node.blendMode))
  #mainCtx.save("nodes/" & node.name & ".mainCtx.png")
