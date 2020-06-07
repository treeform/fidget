import chroma, vmath, tables, input, sequtils

when not defined(js):
  import typography, typography/textboxes, unicode, tables

const
  clearColor* = color(0, 0, 0, 0)
  whiteColor* = color(1, 1, 1, 1)
  blackColor* = color(0, 0, 0, 1)

type
  Constraint* = enum
    cMin
    cMax
    cScale
    cStretch
    cCenter

  HAlign* = enum
    hLeft
    hCenter
    hRight

  VAlign* = enum
    vTop
    vCenter
    vBottom

  TextAutoResize* = enum
    tsNone
    tsWidthAndHeight
    tsHeight

  TextStyle* = object
    fontFamily*: string
    fontSize*: float
    fontWeight*: float
    lineHeight*: float
    textAlignHorizontal*: HAlign
    textAlignVertical*: VAlign
    autoResize*: TextAutoResize

  BorderStyle* = object
    color*: Color
    width*: float

  ShadowStyle* = enum
    DropShadow
    InnerShadow

  LayoutAlign* = enum
    # Applicable only inside auto-layout frames.
    laMin
    laCenter
    laMax
    laStretch

  LayoutMode* = enum
    # The auto-layout mode on a frame.
    lmNone
    lmVertical
    lmHorizontal

  CounterAxisSizingMode* = enum
    # How to deal with the opposite side of an auto-layout frame.
    csAuto
    csFixed

  Shadow* = object
    kind*: ShadowStyle
    blur*: float
    x*: float
    y*: float
    color*: Color

  NodeKind* = enum
    nkRoot
    nkFrame
    nkGroup
    nkImage
    nkText
    nkRectangle
    nkComponent
    nkInstance

  Node* = ref object
    id*: string
    idPath*: string
    kind*: NodeKind
    text*: string
    code*: string
    nodes*: seq[Node]
    box*: Rect
    orgBox*: Rect
    rotation*: float
    screenBox*: Rect
    textOffset*: Vec2
    fill*: Color
    transparency*: float
    strokeWeight*: float
    stroke*: Color
    zLevel*: int
    resizeDone*: bool
    htmlDone*: bool
    textStyle*: TextStyle
    textPadding*: int
    imageName*: string
    cornerRadius*: (float, float, float, float)
    editableText*: bool
    multiline*: bool
    bindingSet*: bool
    drawable*: bool
    cursorColor*: Color
    highlightColor*: Color
    shadows*: seq[Shadow]
    constraintsHorizontal*: Constraint
    constraintsVertical*: Constraint
    layoutAlign*: LayoutAlign
    layoutMode*: LayoutMode
    counterAxisSizingMode*: CounterAxisSizingMode
    horizontalPadding*: float32
    verticalPadding*: float32
    itemSpacing*: float32
    clipContent*: bool
    diffIndex*: int
    when not defined(js):
      textLayout*: seq[GlyphPosition]
      textLayoutHeight*: float32
      textLayoutWidth*: float32

  KeyState* = enum
    Empty
    Up
    Down
    Repeat
    Press # Used for text input

  MouseCursorStyle* = enum
    Default
    Pointer
    Grab
    NSResize

  Mouse* = ref object
    #state*: KeyState
    pos*, delta*, prevPos*: Vec2
    wheelDelta*: float
    cursorStyle*: MouseCursorStyle # Sets the mouse cursor icon

  Keyboard* = ref object
    state*: KeyState
    # keyCode*: int
    # scanCode*: int
    consumed*: bool       ## Consumed - need to prevent default action.
    keyString*: string
    altKey*: bool
    ctrlKey*: bool
    shiftKey*: bool
    superKey*: bool
    inputFocusIdPath*: string
    prevInputFocusIdPath*: string
    input*: string
    textCursor*: int      # At which character in the input string are we
    selectionCursor*: int # To which character are we selecting to

var
  parent*: Node
  root*: Node
  prevRoot*: Node
  nodeStack*: seq[Node]
  current*: Node
  scrollBox*: Rect
  scrollBoxMega*: Rect # Scroll box is 500px bigger in y direction
  scrollBoxMini*: Rect # Scroll box is smaller by 100px useful for debugging
  mouse* = Mouse()
  keyboard* = Keyboard()
  requestedFrame*: bool
  numNodes*: int
  popupActive*: bool
  inPopup*: bool
  fullscreen* = false
  windowSize*: Vec2    # Screen coordinates
  windowFrame*: Vec2   # Pixel coordinates
  pixelRatio*: float   # Multiplier to convert from screen coords to pixels

  # Used to check for duplicate ID paths.
  pathChecker*: Table[string, bool]

when not defined(js):
  var
    textBox*: TextBox
    fonts*: Table[string, Font]

  func hAlignMode*(align: HAlign): HAlignMode =
    case align:
      of hLeft: HAlignMode.Left
      of hCenter: Center
      of hRight: HAlignMode.Right

  func vAlignMode*(align: VAlign): VAlignMode =
    case align:
      of vTop: Top
      of vCenter: Middle
      of vBottom: Bottom

mouse = Mouse()
mouse.pos = Vec2()

proc dumpTree*(node: Node, indent="") =
  echo indent, node.id, node.screenBox
  for n in node.nodes:
    dumpTree(n, "  " & indent)

iterator reverse*[T](a: seq[T]): T {.inline.} =
  var i = a.len - 1
  while i > -1:
      yield a[i]
      dec i

iterator reversePairs*[T](a: seq[T]): (int, T) {.inline.} =
  var i = a.len - 1
  while i > -1:
      yield (a.len - 1 - i, a[i])
      dec i

proc setupRoot*() =
  if root == nil:
    root = Node()
    root.kind = nkRoot
    root.id = "root"
    root.highlightColor = rgba(0, 0, 0, 60).color
    root.cursorColor = rgba(0, 0, 0, 255).color
  nodeStack = @[root]
  current = root
  root.diffIndex = 0

proc clearInputs*() =
  # Used for onFocus/onUnFocus.
  keyboard.prevInputFocusIdPath = keyboard.inputFocusIdPath

  mouse.wheelDelta = 0

  # Reset key and mouse press to default state
  for i in 0 ..< buttonPress.len:
    buttonPress[i] = false
    buttonRelease[i] = false

  if any(buttonDown, proc(b: bool): bool = b):
    keyboard.state = KeyState.Down
  else:
    keyboard.state = KeyState.Empty

proc click*(mouse: Mouse): bool =
  buttonPress[MOUSE_LEFT]

proc down*(mouse: Mouse): bool =
  buttonDown[MOUSE_LEFT]

proc consume*(keyboard: Keyboard) =
  ## Reset the keyboard state consuming any event information.
  keyboard.state = Empty
  keyboard.keyString = ""
  keyboard.altKey = false
  keyboard.ctrlKey = false
  keyboard.shiftKey = false
  keyboard.superKey = false
  keyboard.consumed = true

proc consume*(mouse: Mouse) =
  ## Reset the mouse state consuming any event information.
  buttonPress[MOUSE_LEFT] = false

proc computeLayout*(parent, node: Node) =
  ## Computes constraints and auto-layout.
  for n in node.nodes:
    computeLayout(node, n)

  # Constraints code.
  case node.constraintsVertical:
    of cMin: discard
    of cMax:
      let rightSpace = parent.orgBox.w - node.box.x
      node.box.x = parent.box.w - rightSpace
    of cScale:
      let xScale = parent.box.w / parent.orgBox.w
      node.box.x *= xScale
      node.box.w *= xScale
    of cStretch:
      let xDiff = parent.box.w - parent.orgBox.w
      node.box.w += xDiff
    of cCenter:
      node.box.x = floor((parent.box.w - node.box.w) / 2.0)

  case node.constraintsHorizontal:
    of cMin: discard
    of cMax:
      let bottomSpace = parent.orgBox.h - node.box.y
      node.box.y = parent.box.h - bottomSpace
    of cScale:
      let yScale = parent.box.h / parent.orgBox.h
      node.box.y *= yScale
      node.box.h *= yScale
    of cStretch:
      let yDiff = parent.box.h - parent.orgBox.h
      node.box.h += yDiff
    of cCenter:
      node.box.y = floor((parent.box.h - node.box.h) / 2.0)

  # Typeset text
  if node.kind == nkText:
    var font = fonts[node.textStyle.fontFamily]
    font.size = node.textStyle.fontSize
    font.lineHeight = node.textStyle.lineHeight
    if font.lineHeight == 0:
      font.lineHeight = font.size

    var
      boundsMin: Vec2
      boundsMax: Vec2
    node.textLayout = font.typeset(
      node.text.toRunes(),
      pos = vec2(0, 0),
      size = node.box.wh,
      hAlignMode(node.textStyle.textAlignHorizontal),
      vAlignMode(node.textStyle.textAlignVertical),
      clip = false,
      boundsMin = boundsMin,
      boundsMax = boundsMax
    )
    node.textLayoutWidth = boundsMax.x - boundsMin.x
    node.textLayoutHeight = boundsMax.y - boundsMin.y

    case node.textStyle.autoResize:
      of tsNone:
        # Fixed sized text node.
        discard
      of tsHeight:
        # Text will grow down.
        node.box.h = node.textLayoutHeight
      of tsWidthAndHeight:
        # Text will grow down and wide.
        node.box.w = node.textLayoutWidth
        node.box.h = node.textLayoutHeight

  # Auto-layout code.
  if node.layoutMode == lmVertical:
    if node.counterAxisSizingMode == csAuto:
      # Resize to fit elements tightly.
      var maxW = 0.0
      for n in node.nodes:
        if n.layoutAlign != laStretch:
          maxW = max(maxW, n.box.w)
      node.box.w = maxW + node.horizontalPadding * 2

    var at = 0.0
    at += node.verticalPadding
    for i, n in node.nodes.reversePairs:
      if i > 0:
        at += node.itemSpacing
      n.box.y = at
      case n.layoutAlign:
        of laMin:
          n.box.x = node.horizontalPadding
        of laCenter:
          n.box.x = node.box.w/2 - n.box.w/2
        of laMax:
          n.box.x = node.box.w - n.box.w - node.horizontalPadding
        of laStretch:
          n.box.x = node.horizontalPadding
          n.box.w = node.box.w - node.horizontalPadding * 2
          # Redo the layout for child node.
          computeLayout(node, n)
      at += n.box.h
    at += node.verticalPadding
    node.box.h = at

  if node.layoutMode == lmHorizontal:
    if node.counterAxisSizingMode == csAuto:
      # Resize to fit elements tightly.
      var maxH = 0.0
      for n in node.nodes:
        if n.layoutAlign != laStretch:
          maxH = max(maxH, n.box.h)
      node.box.h = maxH + node.verticalPadding * 2

    var at = 0.0
    at += node.horizontalPadding
    for i, n in node.nodes.reversePairs:
      if i > 0:
        at += node.itemSpacing
      n.box.x = at
      case n.layoutAlign:
        of laMin:
          n.box.y = node.verticalPadding
        of laCenter:
          n.box.y = node.box.h/2 - n.box.h/2
        of laMax:
          n.box.y = node.box.h - n.box.h - node.verticalPadding
        of laStretch:
          n.box.y = node.verticalPadding
          n.box.h = node.box.h - node.verticalPadding * 2
          # Redo the layout for child node.
          computeLayout(node, n)
      at += n.box.w
    at += node.horizontalPadding
    node.box.w = at

proc computeScreenBox*(parent, node: Node) =
  ## Setups screenBoxes for the whole tree.
  if parent == nil:
    node.screenBox = node.box
  else:
    node.screenBox = node.box + parent.screenBox
  for n in node.nodes:
    computeScreenBox(node, n)
