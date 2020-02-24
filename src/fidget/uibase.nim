import chroma, vmath, sequtils
# typography

when not defined(js):
  import typography/textboxes

const
  clearColor* = color(0,0,0,0)
  whiteColor* = color(1,1,1,1)
  blackColor* = color(0,0,0,1)

type

  Contraints* = enum
    cMin
    cMax
    cScale
    cBoth
    cCenter

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
    box*: Rect
    orgBox*: Rect
    rotation*: float
    screenBox*: Rect
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
    cursorColor*: Color
    highlightColor*: Color

  KeyState* = enum
    Empty
    Up
    Down
    Repeat
    Press # used for text input

  MouseCursorStyle* = enum
    Default
    Pointer
    Grab
    NSResize

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
  scrollBox*: Rect
  scrollBoxMega*: Rect # scroll box is 500px biger in y direction
  scrollBoxMini*: Rect # scroll box is smaller by 100px usefull for debugggin

  ## Set to true so that it repains every frame, used for:
  ##   games and multimidia with animations apps.
  ## Set to false so that it repains only following user action, used for:
  ##   animationless UI apps.
  repainEveryFrame*: bool = true
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

  windowSize*: Vec2
  windowFrame*: Vec2
  dpi*: float

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
  root.highlightColor = rgba(0, 0, 0, 20).color
  root.cursorColor = rgba(0, 0, 0, 255).color

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


proc between*(value, min, max: float32|float|int): bool =
  ## Returns true if value is between min and max or equals to them.
  (value >= min) and (value <= max)


proc inside*(p: Vec2, b: Rect): bool =
  ## Return true if position is inside the box.
  return p.x > b.x and p.x < b.x + b.w and p.y > b.y and p.y < b.y + b.h


proc overlap*(a, b: Rect): bool =
  ## Returns true if box a overlaps box b.
  let
    xOverlap = between(a.x, b.x, b.x + b.w) or between(b.x, a.x, a.x + a.w)
    yOverlap = between(a.y, b.y, b.y + b.h) or between(b.y, a.y, a.y + a.h)
  return xOverlap and yOverlap


proc `+`*(a, b: Rect): Rect =
  ## Add two boxes together.
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.w = a.w
  result.h = a.h
