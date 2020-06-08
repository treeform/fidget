import chroma, dom2 as dom, html5_canvas, math, strformat, strutils, tables,
    common, vmath, internal, input, std/compilesettings, strformat
import print

static:
  ## Writes the needed index.html file.
  let indexPath = querySetting(outDir) & "/index.html"
  try:
    discard readFile(indexPath)
  except:
    echo "Writing out ", indexPath, "."
    writeFile(indexPath, &"""
<html>
<head>
<script src="{querySetting(outDir) & "/" & querySetting(outFile)}"></script>
</head>
<body></body>
</html>
  """)

type
  PerfCounter* = object
    drawMain*: float
    numLowLevelCalls*: int

  Node = common.Node
  HTMLNode = dom.Node

var
  nodeCache*: seq[Node]
  domCache*: seq[Element]

  rootDomNode*: Element
  canvasNode*: Element
  ctx*: CanvasRenderingContext2D

  forceTextReLayout*: bool

  perf*: PerfCounter

  clipStack: seq[Rect]
  clipCache: Table[int, Rect]

var colorCache: Table[chroma.Color, string]
proc toHtmlRgbaCached(color: Color): string =
  result = colorCache.getOrDefault(color)
  if result == "":
    result = color.toHtmlRgba()
    colorCache[color] = result

proc focus*(keyboard: Keyboard, node: Node) =
  ## uses JS events
  discard

proc unFocus*(keyboard: Keyboard, node: Node) =
  ## uses JS events
  discard

proc removeAllChildren(dom: HTMLNode) =
  while dom.firstChild != nil:
    dom.removeChild(dom.firstChild)

proc removeTextSelection*() {.exportc.} =
  echo dom.window.document.getSelection()
  dom.window.document.getSelection().removeAllRanges()

var computeTextBoxCache = newTable[string, Vec2]()
proc computeTextBox*(
  text: string,
  width: float,
  fontName: string,
  fontSize: float,
  fontWeight: float,
  lineHeight: float,
): Vec2 =
  ## Give text, font and a width of the box, compute how far the
  ## text will fill down the hight of the box.
  let key = text & $width & fontName & $fontSize
  if key in computeTextBoxCache:
    return computeTextBoxCache[key]
  var tempDiv = document.createElement("div")
  document.body.appendChild(tempDiv)
  tempDiv.style.fontSize = $fontSize & "px"
  tempDiv.style.lineHeight = $lineHeight & "px"
  tempDiv.style.fontFamily = fontName
  tempDiv.style.fontWeight = $fontWeight
  tempDiv.style.position = "absolute"
  tempDiv.style.left = "-1000"
  tempDiv.style.top = "-1000"
  tempDiv.style.maxWidth = $width & "px"
  tempDiv.innerHTML = text
  result.x = float tempDiv.clientWidth
  result.y = float tempDiv.clientHeight
  document.body.removeChild(tempDiv)
  computeTextBoxCache[key] = result

# proc computeTextHeight*(
#   text: string,
#   width: float,
#   fontName: string,
#   fontSize: float,
#   fontWeight: float,
# ): float =
#   ## Give text, font and a width of the box, compute how far the
#   ## text will fill down the hight of the box.
#   let box = computeTextBox(text, width, fontName, fontSize, fontWeight)
#   return box.y

computeTextLayout = proc(node: Node) =
  let size = computeTextBox(
    node.text,
    node.box.w,
    node.textStyle.fontFamily,
    node.textStyle.fontSize,
    node.textStyle.fontWeight,
    node.textStyle.lineHeight,
  )
  node.textLayoutWidth = size.x
  node.textLayoutHeight = size.y

type
  TextMetrics* {.importc.} = ref object
    width: float   # This is read-only
    actualBoundingBoxAscent*: float
    actualBoundingBoxDescent*: float
    actualBoundingBoxLeft*: float
    actualBoundingBoxRight*: float
    alphabeticBaseline*: float
    emHeightAscent*: float
    emHeightDescent*: float
    fontBoundingBoxAscent*: float
    fontBoundingBoxDescent*: float
    hangingBaseline*: float
    ideographicBaseline*: float

proc measureText(
  ctx: CanvasRenderingContext2D,
  text: cstring
): TextMetrics {.importcpp.}

var baseLineCache = newTable[string, float]()
proc getBaseLine *(
  fontName: string,
  fontSize: float,
  fontWeight: float,
): float =
  let font = &"{fontSize}px {fontName}"
  if font notin baseLineCache:
    ctx.font = &"{fontSize}px {fontName}"
    let m = ctx.measureText("A")
    baseLineCache[font] = fontSize - m.actualBoundingBoxAscent
  baseLineCache[font]

proc tag(node: Node): string =
  if node.kind == nkText:
    if node.editableText:
      if node.multiline:
        return "textarea"
      else:
        return "input"
    else:
      return "span"
  else:
    return "div"

proc createDefaultElement(tag: string): Element =
  result = document.createElement(tag)
  if tag == "textarea" or tag == "input":
    result.setAttribute("type", "text")
    result.style.border = "none"
    result.style.outline = "none"
    result.style.backgroundColor = "transparent"
    result.style.fontFamily = "inherit"
    result.style.fontSize = "inherit"
    result.style.fontWeight = "inherit"
    result.style.padding = "0px"
    result.style.resize = "none"

proc insertChildAtIndex(parent: Element, index: int, child: Element) =
  parent.insertBefore(child, parent.children[index])

proc drawDiff(current: Node) =

  if current.clipContent:
    # TODO: merge with prev clipping stack
    clipStack.add current.screenBox

  if nodeCache.len == numNodes:
    inc perf.numLowLevelCalls

    var old = Node()
    old.kind = current.kind
    old.editableText = current.editableText
    old.multiline = current.multiline
    var dom = createDefaultElement(current.tag)
    rootDomNode.appendChild(dom)

    nodeCache.add(old)
    domCache.add(dom)

  var
    dom = domCache[numNodes]
    old = nodeCache[numNodes]

  # When tags don't match we can't convert a node
  # into another node, so we have to recreate them
  if old.tag != current.tag:
    inc perf.numLowLevelCalls

    old = Node()
    old.kind = current.kind
    old.editableText = current.editableText
    old.multiline = current.multiline
    dom = createDefaultElement(current.tag)
    rootDomNode.replaceChild(dom, rootDomNode.children[numNodes])
    domCache[numNodes] = dom
    nodeCache[numNodes] = old

  # change kinds
  if old.kind != current.kind:
    old.kind = current.kind

  # check ID path
  if old.idPath != current.idPath:
    inc perf.numLowLevelCalls
    old.id = current.id
    old.idPath = current.idPath
    dom.id = current.idPath

  # check fill (background color or text color)
  if old.fill != current.fill:
    inc perf.numLowLevelCalls
    old.fill = current.fill
    if current.kind == nkText:
      dom.style.color = $current.fill.toHtmlRgba()
      dom.style.backgroundColor = "rgba(0,0,0,0)"
    else:
      dom.style.backgroundColor = $current.fill.toHtmlRgba()
      dom.style.color = "rgba(0,0,0,0)"

  # check stroke (border color)
  if old.stroke != current.stroke or
      old.strokeWeight != current.strokeWeight:
    inc perf.numLowLevelCalls
    old.stroke = current.stroke
    old.strokeWeight = current.strokeWeight
    if current.strokeWeight > 0:
      dom.style.borderStyle = "solid"
      dom.style.boxSizing = "border-box"
      dom.style.borderColor = $current.stroke.toHtmlRgba()
      dom.style.borderWidth = $current.strokeWeight & "px"
    else:
      dom.style.borderStyle = "none"

  # check cornerRadius (border radius)
  if old.cornerRadius != current.cornerRadius:
    old.cornerRadius = current.cornerRadius
    dom.style.borderRadius = (
      $current.cornerRadius[0] & "px " &
      $current.cornerRadius[1] & "px " &
      $current.cornerRadius[2] & "px " &
      $current.cornerRadius[3] & "px"
    )

  # check transparency
  if old.transparency != current.transparency:
    inc perf.numLowLevelCalls
    old.transparency = current.transparency
    dom.style.opacity = $current.transparency

  # check shadows
  if old.shadows != current.shadows:
    inc perf.numLowLevelCalls
    old.shadows = current.shadows
    var boxShadowString = ""
    for s in current.shadows:
      if s.kind == DropShadow:
        boxShadowString.add &"{s.x}px {s.y}px {s.blur}px {s.color.toHtmlRgba},"
      if s.kind == InnerShadow:
        boxShadowString.add &"inset {s.x}px {s.y}px {s.blur}px {s.color.toHtmlRgba},"
    if boxShadowString.len > 0:
      boxShadowString.setLen(boxShadowString.len - 1)
    dom.style.boxShadow = boxShadowString

  # check text style
  if old.textStyle != current.textStyle:
    inc perf.numLowLevelCalls
    old.textStyle = current.textStyle
    dom.style.fontFamily = current.textStyle.fontFamily
    dom.style.fontSize = $current.textStyle.fontSize & "px"
    dom.style.fontWeight = $current.textStyle.fontWeight
    dom.style.lineHeight = $max(0, current.textStyle.lineHeight) & "px"

  # check imageName (background image)
  if old.imageName != current.imageName:
    inc perf.numLowLevelCalls
    old.imageName = current.imageName
    if current.imageName != "":
      dom.style.backgroundImage = "url(" & current.imageName & ")"
      dom.style.backgroundSize = "100% 100%"
    else:
      dom.style.backgroundImage = ""

  if current.textPadding != old.textPadding:
    old.textPadding = current.textPadding
    dom.style.padding = $current.textPadding & "px"
    dom.style.boxSizing = "border-box"

  if old.screenBox.wh == current.box.wh:
    current.textOffset = old.textOffset

  if current.kind == nkText:
    if current.editableText:
      if old.text != current.text:
        if document.activeElement != dom:
          cast[TextAreaElement](dom).value = current.text
    else:
      if forceTextReLayout or (old.text != current.text):
        inc perf.numLowLevelCalls
        old.text = current.text

        dom.innerText = current.text
        dom.style.verticalAlign = "text-top"

        var box = computeTextBox(
          current.text,
          current.screenBox.w,
          current.textStyle.fontFamily,
          current.textStyle.fontSize,
          current.textStyle.fontWeight,
          current.textStyle.lineHeight
        )
        var baseLine = getBaseLine(
          current.textStyle.fontFamily,
          current.textStyle.fontSize,
          current.textStyle.fontWeight
        )

        var left = 0.0
        case current.textStyle.textAlignHorizontal:
          of hLeft:
            left = 0
          of hRight:
            left = current.screenBox.w - box[0]
          of hCenter:
            left = current.screenBox.w / 2 - box[0] / 2

        var top = 0.0
        case current.textStyle.textAlignVertical:
          of vTop:
            top = 0
          of vBottom:
            top = current.screenBox.h - box[1] + baseLine
          of vCenter:
            top = current.screenBox.h / 2 - box[1] / 2 + baseLine / 2

        var lineOffset = current.textStyle.fontSize / 2 -
          max(0, current.textStyle.lineHeight) / 2
        current.textOffset.x = left
        current.textOffset.y = top + lineOffset
      else:
        current.textOffset.x = 0
        current.textOffset.y = 0

  if current.tag == "input":
    dom.style.paddingBottom = $(current.box.h - current.textStyle.lineHeight) & "px"
    case current.textStyle.textAlignHorizontal:
      of hLeft:
        dom.style.textAlign = "left"
      of hRight:
        dom.style.textAlign = "right"
      of hCenter:
        dom.style.textAlign = "center"

  # check position on screen
  if old.screenBox != current.screenBox or old.textOffset != current.textOffset:
    inc perf.numLowLevelCalls
    old.screenBox = current.screenBox
    old.textOffset = current.textOffset
    dom.style.position = "absolute"
    dom.style.left = $(current.screenBox.x + current.textOffset.x) & "px"
    dom.style.top = $(current.screenBox.y + current.textOffset.y) & "px"
    dom.style.width = $current.screenBox.w & "px"
    dom.style.height = $current.screenBox.h & "px"

  # Set clipping mask.
  if clipStack.len > 0:
    let clipMask = clipStack[^1]
    if numNodes notin clipCache or clipCache[numNodes] != clipMask:
      clipCache[numNodes] = clipMask
      let a = clipMask.xy - current.screenBox.xy
      let b = clipMask.xy + clipMask.wh - current.screenBox.xy
      let clipPath = &"polygon({a.x}px {a.y}px, {a.x}px {b.y}px, {b.x}px {b.y}px, {b.x}px {a.y}px)"
      dom.style.clipPath = clipPath
      inc perf.numLowLevelCalls
  else:
    if numNodes in clipCache:
      dom.style.clipPath = ""
      inc perf.numLowLevelCalls
      clipCache.del(numNodes)

  inc numNodes

template hasDifferent(node: common.Node, key: untyped): bool =
  if node.cache.key != node.key:
    node.cache.key = node.key
    print "changed ", node.key
    true
  else:
    false

proc draw*(node: Node, parent: Node) =
  if node.element == nil:
    print "create element"
    if node.kind == nkText:
      node.element = document.createElement("div")
      node.textElement = document.createElement("div")
      node.textElement.style.display = "table-cell"
      node.textElement.style.position = "unset"

      node.textElement.setAttribute("contenteditable", "true")

      node.element.appendChild(node.textElement)
    else:
      node.element = document.createElement("div")

    if parent == nil:
      document.body.appendChild(node.element)
    else:
      parent.element.appendChild(node.element)

  if node.hasDifferent(id):
    node.element.setAttribute("id", node.id)

  if node.hasDifferent(box):
    node.element.style.left = $node.box.x & "px"
    node.element.style.top = $node.box.y & "px"
    node.element.style.width = $node.box.w & "px"
    node.element.style.height = $node.box.h & "px"

    if node.textElement != nil:
      node.textElement.style.width = $node.box.w & "px"
      node.textElement.style.height = $node.box.h & "px"

  if node.hasDifferent(fill):
    if node.kind == nkText:
      node.element.style.color = $node.fill.toHtmlRgba()
    else:
      node.element.style.backgroundColor = $node.fill.toHtmlRgba()

  if node.kind == nkText:
    if node.hasDifferent(text):
      node.textElement.innerText = node.text

    if node.hasDifferent(textStyle):

      node.textElement.style.fontFamily = node.textStyle.fontFamily
      node.textElement.style.fontSize = $node.textStyle.fontSize & "px"
      node.textElement.style.fontWeight = $node.textStyle.fontWeight
      node.textElement.style.lineHeight = $max(0, node.textStyle.lineHeight) & "px"

      case node.textStyle.textAlignHorizontal:
        of hLeft:
          node.textElement.style.textAlign = "left"
        of hCenter:
          node.textElement.style.textAlign = "center"
        of hRight:
          node.textElement.style.textAlign = "right"
      case node.textStyle.textAlignVertical:
        of vTop:
          node.textElement.style.verticalAlign = "top"
        of vCenter:
          node.textElement.style.verticalAlign = "middle"
        of vBottom:
          node.textElement.style.verticalAlign = "bottom"

  for n in node.nodes.reverse:
    draw(n, node)

proc postDrawChildren*(node: Node) =
  if current.clipContent:
    discard clipStack.pop()

var startTime: float
var prevMouseCursorStyle: MouseCursorStyle

proc drawStart() =
  startTime = dom.window.performance.now()
  numNodes = 0
  perf.numLowLevelCalls = 0
  pathChecker.clear()

  pixelRatio = dom.window.devicePixelRatio
  windowSize.x = window.innerWidth.float32
  windowSize.y = window.innerHeight.float32
  windowFrame.x = window.innerWidth.float32
  windowFrame.y = window.innerHeight.float32

  # set up root HTML
  root.box.x = 0
  root.box.y = 0
  root.box.w = windowFrame.x
  root.box.h = windowFrame.y
  root.transparency = 1.0

  scrollBox.x = float dom.window.scrollX
  scrollBox.y = float dom.window.scrollY
  scrollBox.w = float document.body.clientWidth
  scrollBox.h = float dom.window.innerHeight

  scrollBoxMega.x = float dom.window.scrollX
  scrollBoxMega.y = float dom.window.scrollY - 500
  scrollBoxMega.w = float document.body.clientWidth
  scrollBoxMega.h = float dom.window.innerHeight + 1000

  scrollBoxMini.x = float dom.window.scrollX
  scrollBoxMini.y = float dom.window.scrollY + 100
  scrollBoxMini.w = float document.body.clientWidth
  scrollBoxMini.h = float dom.window.innerHeight - 200

  document.body.style.overflowX = "hidden"
  document.body.style.overflowY = "scroll"

  var canvas = cast[Canvas](canvasNode)
  ctx = canvas.getContext2D()
  var
    width = float(dom.window.innerWidth)
    height = float(dom.window.innerHeight)
  canvas.clientWidth = int(width)
  canvas.clientHeight = int(height)
  canvas.width = int(width * pixelRatio)
  canvas.height = int(height * pixelRatio)

  canvas.style.display = "block"
  canvas.style.position = "absolute"
  canvas.style.zIndex = -1
  canvas.style.left = cstring($scrollBox.x & "px")
  canvas.style.top = cstring($scrollBox.y & "px")
  canvas.style.width = cstring($width & "px")
  canvas.style.height = cstring($height & "px")

  ctx.scale(pixelRatio, pixelRatio)

  mouse.cursorStyle = Default

proc drawFinish() =

  perf.drawMain = dom.window.performance.now() - startTime

  # echo perf.drawMain
  # echo numNodes
  # echo perf.numLowLevelCalls

  # remove left over nodes
  while rootDomNode.childNodes.len > numNodes:
    rootDomNode.removeChild(domCache[^1])
    discard nodeCache.pop()
    discard domCache.pop()

  # Only set mouse style when it changes.
  if prevMouseCursorStyle != mouse.cursorStyle:
    prevMouseCursorStyle = mouse.cursorStyle
    case mouse.cursorStyle:
      of Default:
        rootDomNode.style.cursor = "default"
      of Pointer:
        rootDomNode.style.cursor = "pointer"
      of Grab:
        rootDomNode.style.cursor = "grab"
      of NSResize:
        rootDomNode.style.cursor = "ns-resize"

  clearInputs()

proc hardRedraw() =
  if rootDomNode == nil: # check if we have loaded
    return

  setupRoot()

  drawStart()
  drawMain()

  computeLayout(nil, root)
  computeScreenBox(nil, root)

  draw(root, nil)

  drawFinish()

proc requestHardRedraw(time: float = 0.0) =
  requestedFrame = false
  hardRedraw()

proc refresh*() =
  if not requestedFrame:
    requestedFrame = true
    discard dom.window.requestAnimationFrame(requestHardRedraw)

proc startFidget*(draw: proc(), w = 0, h = 0) =
  ## Start the HTML backend
  ## NOTE: returns instantly!
  drawMain = draw

  dom.window.addEventListener "load", proc(event: Event) =
    ## called when html page loads and JS can start running
    rootDomNode = document.createElement("div")
    document.body.appendChild(rootDomNode)

    canvasNode = document.createElement("canvas")
    document.body.appendChild(canvasNode)
    refresh()

  dom.window.addEventListener "resize", proc(event: Event) =
    ## Resize does not need to do anything special in HTML mode
    refresh()

  dom.window.addEventListener "scroll", proc(event: Event) =
    ## Scroll does not need to do anything special in HTML mode
    refresh()

  dom.window.addEventListener "mousedown", proc(event: Event) =
    ## When mouse button is pressed
    let event = cast[MouseEvent](event)
    let key = mouseButtonToButton[event.button]
    buttonPress[key] = true
    buttonDown[key] = true
    refresh()

  dom.window.addEventListener "mouseup", proc(event: Event) =
    ## When mouse button is released
    let event = cast[MouseEvent](event)
    let key = mouseButtonToButton[event.button]
    buttonDown[key] = false
    buttonRelease[key] = true
    refresh()

  dom.window.addEventListener "mousemove", proc(event: Event) =
    # When mouse moves
    let event = cast[MouseEvent](event)
    mouse.pos.x = float event.pageX
    mouse.pos.y = float event.pageY
    refresh()

  dom.window.addEventListener "keydown", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with key up for continuous things like scroll or games
    let event = cast[KeyboardEvent](event)
    #keyboard.set(Down, event)
    keyboard.state = KeyState.Press
    let key = keyCodeToButton[event.keyCode]
    buttonToggle[key] = not buttonToggle[key]
    buttonPress[key] = true
    buttonDown[key] = true
    hardRedraw()
    if keyboard.consumed:
      echo "preventDefault"
      event.preventDefault()
      keyboard.consumed = false


  dom.window.addEventListener "keyup", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with keydown
    let event = cast[KeyboardEvent](event)
    let key = keyCodeToButton[event.keyCode]
    buttonDown[key] = false
    buttonRelease[key] = true
    keyboard.state = KeyState.Up
    hardRedraw()

  proc isTextTag(node: HTMLNode): bool =
    node.nodeName == "TEXTAREA" or node.nodeName == "INPUT"

  dom.window.addEventListener "input", proc(event: Event) =
    ## When INPUT element has keyboard input this is called
    if document.activeElement.isTextTag:
      let activeTextElement = cast[TextAreaElement](document.activeElement)
      keyboard.input = $(activeTextElement.value)
      keyboard.inputFocusIdPath = $document.activeElement.id
      keyboard.state = Press
      keyboard.textCursor = activeTextElement.selectionStart
      keyboard.selectionCursor = activeTextElement.selectionEnd
      refresh()

  dom.window.addEventListener "focusin", proc(event: Event) =
    ## When INPUT element gets focus this is called, set the keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "focus" does not bubble, so its not used here.
    if document.activeElement.isTextTag:
      let activeTextElement = cast[TextAreaElement](document.activeElement)
      keyboard.input = $(activeTextElement.value)
      keyboard.inputFocusIdPath = $document.activeElement.id
      keyboard.textCursor = activeTextElement.selectionStart
      keyboard.selectionCursor = activeTextElement.selectionEnd
      refresh()

  dom.window.addEventListener "focusout", proc(event: Event) =
    ## When INPUT element looses focus this is called, clear keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "blur" does not bubble, so its not used here.
    # redraw everything to sync up the bind(string)
    refresh()
    keyboard.input = ""
    keyboard.inputFocusIdPath = ""
    refresh()

  dom.window.addEventListener "popstate", proc(event: Event) =
    ## Called when users presses back or forward buttons.
    refresh()

  document.fonts.onloadingdone = proc(event: Event) =
    computeTextBoxCache.clear()
    forceTextReLayout = true
    hardRedraw()
    forceTextReLayout = false

proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard dom.window.open(url, "_blank")

proc openBrowserWithText*(text: string) =
  ## Opens a URL in a browser
  var window = dom.window.open("", "_blank")
  window.document.write("<code style=display:block;white-space:pre-wrap>" &
      text & "</code>")

proc getTitle*(): string =
  ## Gets window title
  $dom.document.title

proc setTitle*(title: string) =
  ## Sets window title
  if getTitle() != title:
    dom.document.title = title
    refresh()

proc getUrl*(): string =
  ## Gets the current URL
  return $dom.window.location.pathname &
    $dom.window.location.search &
    $dom.window.location.hash

proc setUrl*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  if getUrl() != url:
    type Dummy = object
    dom.window.history.pushState(Dummy(), "", url)
    refresh()

proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads a font.
  dom.window.document.write &"""
    <style>@font-face {{font-family: '{name}'; src: URL('{pathOrUrl}') format('truetype');}}</style>
  """

proc setItem*(key, value: string) =
  ## Saves value into local storage or file.
  dom.window.localStorage.setItem(key, value)

proc getItem*(key: string): string =
  ## Gets a value into local storage or file.
  $dom.window.localStorage.getItem(key)

proc loadGoogleFontUrl*(url: string) =
  var link = document.createElement("link")
  link.setAttribute("href", url)
  link.setAttribute("rel", "stylesheet")
  document.head.appendChild(link)
