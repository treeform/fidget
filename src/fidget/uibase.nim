import chroma

const
  clearColor* = color(0,0,0,0)
  whiteColor* = color(1,1,1,1)
  blackColor* = color(0,0,0,1)

type
  Pos* = object
    x*: float
    y*: float

  Box* = object
    x*: float
    y*: float
    w*: float
    h*: float

  TextStyle* = object
    fontFamily*: string
    fontSize*: float
    fontWeight*: float
    lineHeight*: float
    textAlignHorizontal*: float
    textAlignVertical*:float

  BorderStyle* = object
    color*: Color
    width*: float

  Group* = ref object
    id*: string
    kind*: string
    text*: string
    code*: string
    kids*: seq[Group]
    box*: Box
    screenBox*: Box
    fill*: Color
    transparency*: float32
    strokeWeight*: int
    stroke*: Color
    zLevel*: int
    resizeDone*: bool
    htmlDone*: bool
    textStyle*: TextStyle
    imageName*: string
    cornerRadius*: (int, int, int, int)
    wasDrawn*: bool # was group drawn or it still needs to be drawn
    editableText*: bool

  KeyState* = enum
    Empty
    Up
    Down
    Press

  Mouse* = ref object
    state: KeyState
    pos*: Pos
    click*: bool # mouse button just got held down
    down*: bool # mouse button is held down

  Keyboard* = ref object
    state*: KeyState
    keyCode*: int
    keyString*: string
    altKey*: bool
    ctrlKey*: bool
    shiftKey*: bool
    inputFocusId*: string
    input*: string

  Perf* = object
    drawMain*: float
    numLowLevelCalls*: int

var
  parent*: Group
  root*: Group
  prevRoot*: Group
  groupStack*: seq[Group]
  current*: Group
  scrollBox*: Box
  mouse* = Mouse()
  keyboard* = Keyboard()
  drawMain*: proc()
  perf*: Perf
  requestedFrame*: bool
  numGroups*: int
  rootUrl*: string

mouse = Mouse()
mouse.pos = Pos()


proc setupRoot*() =
  prevRoot = root
  root = Group()
  groupStack = @[root]
  current = root
  root.id = "root"

proc use*(keyboard: Keyboard) =
  keyboard.state = Empty
  keyboard.keyCode = 0
  keyboard.keyString = ""
  keyboard.altKey = false
  keyboard.ctrlKey = false
  keyboard.shiftKey = false


proc use*(mouse: Mouse) =
  mouse.click = false

