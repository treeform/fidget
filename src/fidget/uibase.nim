import chroma, vmath, sequtils
# typography

when not defined(js):
  import typography/textboxes

const
  clearColor* = color(0,0,0,0)
  whiteColor* = color(1,1,1,1)
  blackColor* = color(0,0,0,1)

type

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
    textAlignHorizontal*: int
    textAlignVertical*: int

  BorderStyle* = object
    color*: Color
    width*: float

  Group* = ref object
    id*: string
    idPath*: string
    kind*: string
    text*: string
    placeholder*: string
    code*: string
    kids*: seq[Group]
    box*: Box
    rotation*: float
    screenBox*: Box
    fill*: Color
    transparency*: float
    strokeWeight*: float
    stroke*: Color
    zLevel*: int
    resizeDone*: bool
    htmlDone*: bool
    textStyle*: TextStyle
    imageName*: string
    cornerRadius*: (float, float, float, float)
    wasDrawn*: bool # was group drawn or it still needs to be drawn
    editableText*: bool
    multiline*: bool
    drawable*: bool


  KeyState* = enum
    Empty
    Up
    Down
    Repeat
    Press # used for text input

  MouseCursorStyle* = enum
    Default
    Pointer

  Mouse* = ref object
    state: KeyState
    pos*: Vec2
    click*: bool # mouse button just got held down
    rightClick*: bool # mouse right click
    down*: bool # mouse button is held down
    cursorStyle*: MouseCursorStyle # sets the mouse cursor icon

  Keyboard* = ref object
    state*: KeyState
    keyCode*: int
    scanCode*: int
    keyString*: string
    altKey*: bool
    ctrlKey*: bool
    shiftKey*: bool
    superKey*: bool
    inputFocusIdPath*: string
    prevInputFocusIdPath*: string
    input*: string
    textCursor*: int # at which character in the input string are we
    selectionCursor*: int # to which character are we selecting to


  Perf* = object
    drawMain*: float
    numLowLevelCalls*: int

  Window* = ref object
    innerTitle*: string
    innerUrl*: string

var
  window* = Window()
  parent*: Group
  root*: Group
  prevRoot*: Group
  groupStack*: seq[Group]
  current*: Group
  scrollBox*: Box
  scrollBoxMega*: Box # scroll box is 500px biger in y direction
  scrollBoxMini*: Box # scroll box is smaller by 100px usefull for debugggin
  mouse* = Mouse()
  keyboard* = Keyboard()
  drawMain*: proc()
  perf*: Perf
  requestedFrame*: bool
  numGroups*: int
  rootUrl*: string
  popupActive*: bool
  inPopup*: bool
  #fonts* = newTable[string, Font]()

when not defined(js):
  var
    textBox*: TextBox

mouse = Mouse()
mouse.pos = Vec2()


proc setupRoot*() =
  prevRoot = root
  root = Group()
  groupStack = @[root]
  current = root
  root.id = "root"


proc use*(keyboard: Keyboard) =
  keyboard.state = Empty
  keyboard.keyCode = 0
  keyboard.scanCode = 0
  keyboard.keyString = ""
  keyboard.altKey = false
  keyboard.ctrlKey = false
  keyboard.shiftKey = false
  keyboard.superKey = false


proc use*(mouse: Mouse) =
  mouse.click = false


proc clamp*(value, min, max: int): int =
  ## Makes sure the value is between min and max inclusive
  max(min, min(value, max))


proc between*(value, min, max: float|int): bool =
  ## Returns true if value is between min and max or equals to them.
  (value >= min) and (value <= max)


proc inside*(p: Vec2, b: Box): bool =
  ## Return true if position is inside the box.
  return p.x > b.x and p.x < b.x + b.w and p.y > b.y and p.y < b.y + b.h


proc overlap*(a, b: Box): bool =
  ## Returns true if box a overlaps box b.
  let
    xOverlap = between(a.x, b.x, b.x + b.w) or between(b.x, a.x, a.x + a.w)
    yOverlap = between(a.y, b.y, b.y + b.h) or between(b.y, a.y, a.y + a.h)
  return xOverlap and yOverlap


proc `+`*(a, b: Box): Box =
  ## Add two boxes together.
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.w = a.w
  result.h = a.h


proc `$`*(g: Group): string =
  ## Format group is a string.
  result = "Group"
  if g.id.len > 0:
    result &= " id:" & $g.id
  result &= " screenBox:" & $g.box


proc xy*(b: Box): Vec2 = vec2(b.x, b.y)
proc wh*(b: Box): Vec2 = vec2(b.w, b.h)


