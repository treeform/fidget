import json, jsutils/jsons, print, tables, chroma, vmath, cairo

type
  Component = ref object
    key: string
    name: string
    description: string

  Device = ref object
    `type`: string
    rotation: string

  Box = ref object
    x, y, width, height: float32

  Constraints = ref object
    vertical: string
    horizontal: string

  Fill = ref object
    blendMode: string
    `type`: string
    color: Color

  Effect = ref object
    `type`: string
    visible: bool
    color: Color
    blendMode: string
    offset: Vec2
    radius: float32
    spread: float32

  Grid = ref object
    `type`: string

  CharacterStyleOverrides = ref object
    `type`: string

  TextStyle = ref object
    fontFamily: string
    fontPostScriptName: string
    fontWeight: float32
    textAutoResize: string
    fontSize: float32
    textAlignHorizontal: string
    textAlignVertical: string
    letterSpacing: float32
    lineHeightPx: float32
    lineHeightPercent: float32
    lineHeightUnit: string

  Node = ref object
    id: string ## A string uniquely identifying this node within the document.
    name: string ## The name given to the node by the user in the tool.
    visible: bool ## default true,  Whether or not the node is visible on the canvas.
    `type`: string ## The type of the node, refer to table below for details.
    #pluginData: JsonNode ## Data written by plugins that is visible only to the plugin that wrote it. Requires the `pluginData` to include the ID of the plugin.
    #sharedPluginData: JsonNode ##  Data written by plugins that is visible to all plugins. Requires the `pluginData` parameter to include the string "shared".
    blendMode: string
    children: seq[Node]
    prototypeStartNodeID: string
    prototypeDevice: Device
    absoluteBoundingBox: Box
    constraints: Constraints
    layoutAlign: string
    clipsContent: bool
    background: seq[Fill]
    fills: seq[Fill]
    strokes: seq[Fill]
    strokeWeight: float32
    strokeAlign: string
    backgroundColor: Color
    layoutGrids: seq[Grid]
    layoutMode: string
    itemSpacing: float32
    effects: seq[Effect]
    cornerRadius: float32
    rectangleCornerRadii: seq[float32]
    characters: string
    style: TextStyle
    #characterStyleOverrides: seq[CharacterStyleOverrides]
    #styleOverrideTable:

  FigmaFile = ref object
    document: Node
    components: Table[string, Component]
    schemaVersion: int
    name: string
    lastModified: string
    thumbnailUrl: string
    version: string
    role: string

proc parseFigma(file: JsonNode): FigmaFile =
  assert file["schemaVersion"].getInt() == 0
  result = file.fromJson(FigmaFile)


let ff = parseFigma(parseJson(readFile("import.json")))

echo pretty %ff



# original example on https://cairographics.org/samples/

import cairo
import math

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

proc drawNode(node: Node)

proc drawChildren(node: Node) =
  parentNode = node
  nodeStack.add(node)
  for child in node.children:
    drawNode(child)
  discard nodeStack.pop()
  if nodeStack.len > 0:
    parentNode = nodeStack[^1]

proc drawNode(node: Node) =
  case node.`type`
  of "DOCUMENT", "CANVAS":
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
        node.absoluteBoundingBox.x ,
        node.absoluteBoundingBox.y ,
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

drawNode(ff.document)

# var
#   xc = 128.0
#   yc = 128.0
#   radius = 100.0
#   angle1 = 45.0  * PI / 180.0  # angles are specified
#   angle2 = 180.0 * PI / 180.0  # in radians

# ctx.setLineWidth(10.0)
# ctx.arc(xc, yc, radius, angle1, angle2)
# ctx.stroke()

# # draw helping lines
# ctx.setSourceRGBA(1.0, 0.2, 0.2, 0.6)
# ctx.setLineWidth(6.0)

# ctx.arc(xc, yc, 10.0, 0, 2*PI)
# ctx.fill()

# ctx.arc(xc, yc, radius, angle1, angle1)
# ctx.lineTo(xc, yc)
# ctx.arc(xc, yc, radius, angle2, angle2)
# ctx.lineTo(xc, yc)
# ctx.stroke()
