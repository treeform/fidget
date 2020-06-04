import chroma, vmath, tables, input, sequtils

when not defined(js):
  import typography/textboxes

const
  clearColor* = color(0, 0, 0, 0)
  whiteColor* = color(1, 1, 1, 1)
  blackColor* = color(0, 0, 0, 1)

type
  Contraints* = enum
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
    tNone
    tWidthAndHeight
    tHeight

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

  Shadow* = object
    kind*: ShadowStyle
    blur*: float
    x*: float
    y*: float
    color*: Color

  Group* = ref object
    id*: string
    idPath*: string
    kind*: string
    text*: string
    code*: string
    kids*: seq[Group]
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
    wasDrawn*: bool # Was group drawn or still needs to be drawn
    editableText*: bool
    multiline*: bool
    bindingSet*: bool
    drawable*: bool
    cursorColor*: Color
    highlightColor*: Color
    shadows*: seq[Shadow]
    clipContent*: bool

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
  parent*: Group
  root*: Group
  prevRoot*: Group
  groupStack*: seq[Group]
  current*: Group
  scrollBox*: Rect
  scrollBoxMega*: Rect # Scroll box is 500px bigger in y direction
  scrollBoxMini*: Rect # Scroll box is smaller by 100px useful for debugging
  mouse* = Mouse()
  keyboard* = Keyboard()
  requestedFrame*: bool
  numGroups*: int
  popupActive*: bool
  inPopup*: bool
  fullscreen* = false
  windowSize*: Vec2    # Screen coordinates
  windowFrame*: Vec2   # Pixel coordinates
  pixelRatio*: float   # Multiplier to convert from screen coords to pixels

  # Used to check for duplicate ID paths.
  pathChecker*: Table[string, bool]

when not defined(js):
  var textBox*: TextBox

mouse = Mouse()
mouse.pos = Vec2()

proc setupRoot*() =
  prevRoot = root
  root = Group()
  groupStack = @[root]
  current = root
  root.kind = "group"
  root.id = "root"
  root.highlightColor = rgba(0, 0, 0, 60).color
  root.cursorColor = rgba(0, 0, 0, 255).color

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
