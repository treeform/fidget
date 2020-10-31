
import cairo, math, vmath, schema, print

var
  surface: ptr Surface
  ctx: ptr Context
  nodeStack: seq[Node]
  parentNode: Node
  at: Vec2

proc frameFills(node: Node) =
  if node.fills.len > 0:
    for fill in node.fills:
      ctx.setSourceRgba(
        fill.color.r,
        fill.color.g,
        fill.color.b,
        fill.color.a,
      )
      ctx.newPath()
      ctx.rectangle(
        node.absoluteBoundingBox.x,
        node.absoluteBoundingBox.y,
        node.absoluteBoundingBox.width,
        node.absoluteBoundingBox.height,
      )
      ctx.fill()

proc drawNode*(node: Node)

proc drawChildren(node: Node) =
  parentNode = node
  nodeStack.add(node)
  for child in node.children:
    drawNode(child)
  discard nodeStack.pop()
  if nodeStack.len > 0:
    parentNode = nodeStack[^1]

proc drawNode*(node: Node) =
  case node.`type`
  of "DOCUMENT", "CANVAS", "GROUP":
    drawChildren(node)

  of "FRAME":
    if parentNode.`type` == "CANVAS":
      surface = imageSurfaceCreate(
        FORMAT_ARGB32,
        node.absoluteBoundingBox.width.int32,
        node.absoluteBoundingBox.height.int32)
      ctx = surface.create()
      ctx.translate(
        -node.absoluteBoundingBox.x,
        -node.absoluteBoundingBox.y
      )
      frameFills(node)
      drawChildren(node)
      print "write frame", node.name
      discard surface.writeToPng("frames/" & node.name & ".png")
    else:
      parentNode = node
      frameFills(node)
      drawChildren(node)

  of "RECTANGLE":

    for fill in node.fills:
      if fill.`type` == "IMAGE":
        print "image fill", fill.imageRef
        var image = imageSurfaceCreateFromPng("images/" & fill.imageRef)
        ctx.setSource(
          image,
          node.absoluteBoundingBox.x,
          node.absoluteBoundingBox.y
        )
      else:
        ctx.setSourceRgba(
          fill.color.r,
          fill.color.g,
          fill.color.b,
          fill.color.a,
        )
      ctx.newPath()
      if node.cornerRadius > 0:
        const degrees = PI / 180.0
        let
          x = node.absoluteBoundingBox.x
          y = node.absoluteBoundingBox.y
          width = node.absoluteBoundingBox.width
          height = node.absoluteBoundingBox.height
          radius = node.cornerRadius
        ctx.arc(x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees)
        ctx.arc(x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees)
        ctx.arc(x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees)
        ctx.arc(x + radius, y + radius, radius, 180 * degrees, 270 * degrees)
      else:
        ctx.rectangle(
          node.absoluteBoundingBox.x,
          node.absoluteBoundingBox.y,
          node.absoluteBoundingBox.width,
          node.absoluteBoundingBox.height,
        )
      ctx.fill()

  of "TEXT":
    for fill in node.fills:
      ctx.setSourceRgba(
        fill.color.r,
        fill.color.g,
        fill.color.b,
        fill.color.a,
      )
    ctx.selectFontFace(node.style.fontFamily, FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
    ctx.setFontSize(node.style.fontSize)
    ctx.moveTo(node.absoluteBoundingBox.x, node.absoluteBoundingBox.y + node.style.fontSize)
    ctx.showText(node.characters)
    ctx.fill()
