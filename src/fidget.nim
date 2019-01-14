import typography, chroma
include ../engine/all
import ../client/common


export color, print, HAlignMode, VAlignMode

type
  NodeKind* = enum
    Frame
    Rectangle
    Group
    Text
    Instance

  Node* = object
    name*: string
    box*: Rect
    kind*: NodeKind
    fillColor*: Color

    textAlignHorizontal: HAlignMode
    textAlignVertical: VAlignMode
    fontFamily: string
    fontSize: float32
    textLineHeight: float32


var nodeStack = newSeq[Node](0)

var
  current*: ptr Node
  parent*: ptr Node


proc pushStack(kind: NodeKind, name: string) =
  # draw everything about parent node

  nodeStack.add Node()
  nodeStack[^1].kind = kind
  nodeStack[^1].name = name

  current = addr nodeStack[^1]
  if nodeStack.len > 1:
    parent = addr nodeStack[^2]

proc popStack() =
  discard nodeStack.pop()

  if nodeStack.len > 0:
    current = addr nodeStack[^1]
  if nodeStack.len > 1:
    parent = addr nodeStack[^2]

template frame*(name: string, body: untyped) =
  ## A frame node
  nodeStack.setLen(0)

  pushStack(Frame, name)

  block:
    body

  popStack()

template group*(name: string, body: untyped) =
  ## A frame node
  pushStack(Group, name)
  block:
    body

  popStack()

template rectangle*(name: string, body: untyped) =
  ## A rectangle node
  pushStack(Rectangle, name)

  block:
    body

  popStack()

template text*(name: string, body: untyped) =
  ## A rectangle node
  pushStack(Text, name)
  nodeStack[^1].textAlignHorizontal = HAlignMode.Left
  nodeStack[^1].textAlignVertical = VAlignMode.Top

  block:
    body

  popStack()


template component*(name: string, body: untyped) =
  ## A component node
  pushStack(Instance, name)

  block:
    body

  popStack()


template instance*(name: string, body: untyped) =
  ## A instance node
  pushStack(Instance, name)

  block:
    body

  popStack()


template click*(body: untyped) =
  ## What to do when user clicks
  if current.box.intersects(mousePos):
    let darkBg = color(0, 0, 0, 0.50)
    ctx.drawImageRect("data/ui/selection.png", at=current.box.xy, to=xy(current.box) + wh(current.box), color=darkBg, marginIn=1)
    if buttonPress[MOUSE_LEFT] == true:
      body

proc componentId*(componentId: string) =
  ## sets the compoenet id for instance node


proc image*(imagePath: string) =
  ## draws an image
  let b = nodeStack[^1].box
  if nodeStack[^1].fillColor == color(0,0,0,0):
    nodeStack[^1].fillColor = color(1,1,1,1)

  var at = vec2(b.x, b.y)
  var to = vec2(b.x + b.w, b.y + b.h)

  ctx.drawImageRect(
    "data/ui/" & imagePath & ".png",
    at=vec2(b.x, b.y),
    to=vec2(b.x + b.w, b.y + b.h),
    color = nodeStack[^1].fillColor,
    marginIn = 0
  )


proc fill*(color: Color) =
  nodeStack[^1].fillColor = color

proc textAlignHorizontal*(mode: HAlignMode) =
  nodeStack[^1].textAlignHorizontal = mode

proc textAlignVertical*(mode: VAlignMode) =
  nodeStack[^1].textAlignVertical = mode

proc fontFamily*(fontFamily: string) =
  nodeStack[^1].fontFamily = fontFamily

proc fontSize*(fontSize: float) =
  nodeStack[^1].fontSize = fontSize

proc textLineHeight*(textLineHeight: float) =
  nodeStack[^1].textLineHeight = textLineHeight

proc font*(fontFamily: string, fontSize, textLineHeight: float, textAlignHorizontal, textAlignVertical: int) =
  nodeStack[^1].fontFamily = fontFamily
  nodeStack[^1].fontSize = fontSize
  nodeStack[^1].textLineHeight = textLineHeight
  nodeStack[^1].textAlignHorizontal =
    [HAlignMode.Left, HAlignMode.Center, HAlignMode.Right][textAlignHorizontal + 1]
  nodeStack[^1].textAlignVertical =
    [VAlignMode.Top, VAlignMode.Middle, VAlignMode.Bottom][textAlignVertical + 1]

proc characters*(text: string) =
  let node = nodeStack[^1]
  var font: Font
  if node.fontFamily == "Moon":
    font = moonFont
  else:
    font = scoutFont

  ctx.simpleText(
    font,
    pos = node.box.xy,
    size = node.box.wh,
    text = text,
    fontSize = node.fontSize,
    hAlign = node.textAlignHorizontal,
    vAlign = node.textAlignVertical,
    color = node.fillColor,
    lineHeight = node.textLineHeight
  )

proc box*(x, y, w, h: float) =
  ## draws a ui box
  current.box.x = floor(x)
  current.box.y = floor(y)
  current.box.w = floor(w)
  current.box.h = floor(h)

  if current.kind == Frame:
    current.box.x = 0.0
    current.box.y = 0.0
    current.box.w = windowFrame.x
    current.box.h = windowFrame.y
  else:
    current.box.x += parent.box.x
    current.box.y += parent.box.y

  if current.kind == Rectangle:
    let b = nodeStack[^1].box
    uiRect(b.x, b.y, b.w, b.h, current.fillColor)