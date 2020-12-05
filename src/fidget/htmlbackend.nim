import chroma, common, dom2 as dom, html5_canvas, input, internal, math, os,
    strformat, strutils, tables, vmath, html/ajax, json

const defaultStyle = """
div {
  border: none;
  outline: none;
  background-color: transparent;
  font-family: inherit;
  font-size: inherit;
  font-weight: inherit;
  padding: 0;
  margin: 0;
  resize: none;
  position: absolute;
  display: block;
}
"""

type
  PerfCounter* = object
    drawMain*: float
    numLowLevelCalls*: int

  Node = common.Node
  HTMLNode = dom.Node

var
  rootDomNode*: Element
  canvasNode*: Element
  ctx*: CanvasRenderingContext2D

  forceTextReLayout*: bool

  perf*: PerfCounter

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
  dom.window.document.getSelection().removeAllRanges()

var
  computeTextBoxCache = newTable[string, Vec2]()
  tempDiv: Element
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
  if tempDiv == nil:
    tempDiv = document.createElement("div")
    rootDomNode.appendChild(tempDiv)
    tempDiv.style.position = "absolute"
    tempDiv.style.left = "-10000px"
    tempDiv.style.top = "-10000px"

  tempDiv.style.fontSize = $fontSize & "px"
  tempDiv.style.lineHeight = $lineHeight & "px"
  tempDiv.style.fontFamily = fontName
  tempDiv.style.fontWeight = $fontWeight
  tempDiv.style.maxWidth = $width & "px"

  tempDiv.innerText = text

  result.x = float(tempDiv.clientWidth) + 1.0
  result.y = float(tempDiv.clientHeight)
  computeTextBoxCache[key] = result

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
    width: float # This is read-only
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
proc getBaseLine*(
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

template hasDifferent(node: common.Node, key: untyped): bool =
  if node.cache.key != node.key:
    node.cache.key = node.key
    true
  else:
    false

proc remove*(element: Element) =
  remove(cast[HTMLNode](element))

proc remove*(node: Node) =
  ## Removes non needed HTML elements right before node is removed.
  if node.element != nil:
    node.element.remove()
    node.element = nil
  if node.textElement != nil:
    node.textElement.remove()
    node.textElement = nil
  nodeLookup.del(node.uid)
  node.cache = nil

proc removeExtraChildren*(node: Node) =
  ## Deal with removed nodes.
  if node.diffIndex != node.nodes.len:
    for i in node.diffIndex ..< node.nodes.len:
      remove(node.nodes[i])
    node.nodes.setLen(node.diffIndex)

proc draw*(index: int, node: Node, parent: Node) =
  ## Draws the node (diffs HTML elements).

  if node.cache != nil:
    if node.cache.kind == nkText and node.kind != nkText:
      # Remove text stuff from the node.
      node.element.removeAttribute("style")
      node.textElement.remove()
      node.textElement = nil
      node.cache = Node()
      node.cache.kind = node.kind

    if node.cache.kind != nkText and node.kind == nkText:
      # Remove non-text stuff from the node.
      node.element.removeAttribute("style")
      node.cache = Node()
      node.cache.kind = node.kind

  if node.element == nil:
    node.element = document.createElement("div")
    nodeLookup[node.uid] = node
    if parent == nil:
      rootDomNode.appendChild(node.element)
    else:
      parent.element.appendChild(node.element)
    node.cache = Node()
    node.cache.kind = node.kind

  # Add the text part if this is a text node.
  if node.kind == nkText and node.textElement == nil:
    node.textElement = document.createElement("div")
    node.textElement.style.display = "table-cell"
    node.textElement.style.position = "unset"
    node.textElement.style.whiteSpace = "pre-wrap"
    node.element.appendChild(node.textElement)

  # Check if text should be editable by user.
  if node.hasDifferent(editableText):
    if node.editableText:
      node.textElement.setAttribute("contenteditable", "true")
      node.element.style.overflowX = "hidden"
      node.element.style.overflowY = "auto"
    else:
      node.textElement.setAttribute("contenteditable", "true")
      node.element.style.overflowX = "visible"
      node.element.style.overflowY = "visible"

  # Check node id.
  if node.hasDifferent(id):
    node.element.setAttribute("class", node.id)

  # Check node uid.
  if node.hasDifferent(uid):
    node.element.setAttribute("id", node.uid)

  node.zIndex =
    if parent != nil:
      parent.nodes.len - index
    else:
      0
  if node.hasDifferent(zIndex):
    node.element.style.zIndex = $node.zIndex

  # Check dimensions (always absolute positioned).
  if node.hasDifferent(box):
    node.element.style.left = $node.box.x & "px"
    node.element.style.top = $node.box.y & "px"
    node.element.style.width = $node.box.w & "px"
    node.element.style.height = $node.box.h & "px"

    if node.textElement != nil:
      node.textElement.style.width = $node.box.w & "px"
      node.textElement.style.height = $node.box.h & "px"

  # Check transparency.
  if node.hasDifferent(transparency):
    node.element.style.opacity = $node.transparency

  if node.hasDifferent(scrollBars):
    if node.scrollBars:
      node.element.style.overflow = "auto"
    else:
      node.element.style.overflow = "visible"

  if node.hasDifferent(clipContent):
    if node.clipContent:
      node.element.style.overflow = "hidden"
    else:
      node.element.style.overflow = "visible"

  if node.kind == nkText:
    # In a text node many params apply to the text (not the fill).

    # Check fill (text color).
    if node.hasDifferent(fill):
      node.textElement.style.color = $node.fill.toHtmlRgba()

    if node.hasDifferent(text):
      if keyboard.focusNode != node:
        node.textElement.innerText = node.text
      else:
        # Don't mess with inner text when user is typing!
        discard

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

  else:
    # Not text node.

    # Check shadows.
    if node.hasDifferent(shadows):
      var boxShadowString = ""
      for s in node.shadows:
        if s.kind == DropShadow:
          boxShadowString.add &"{s.x}px {s.y}px {s.blur}px {s.color.toHtmlRgba},"
        if s.kind == InnerShadow:
          boxShadowString.add &"inset {s.x}px {s.y}px {s.blur}px {s.color.toHtmlRgba},"
      if boxShadowString.len > 0:
        boxShadowString.setLen(boxShadowString.len - 1)
      node.element.style.boxShadow = boxShadowString

    # Check for image (background image).
    if node.hasDifferent(imageName):
      if node.imageName != "":
        node.element.style.backgroundImage = &"url({dataDir / node.imageName})"
        node.element.style.backgroundSize = "100% 100%"
      else:
        node.element.style.backgroundImage = ""

    # Check fill (background color).
    if node.hasDifferent(fill):
      node.element.style.backgroundColor = $node.fill.toHtmlRgba()

    # Check stroke weight (border).
    if node.hasDifferent(strokeWeight) or node.hasDifferent(stroke):
      if node.strokeWeight != 0:
        node.element.style.borderWidth = $node.strokeWeight & "px"
        node.element.style.borderColor = $node.stroke.toHtmlRgba()
        node.element.style.boxSizing = "border-box"
        node.element.style.borderStyle = "solid"
      else:
        node.element.style.borderStyle = "none"

    # Check corner radius (border radius)
    if node.hasDifferent(cornerRadius):
      node.element.style.borderRadius = (
        $node.cornerRadius[0] & "px " &
        $node.cornerRadius[1] & "px " &
        $node.cornerRadius[2] & "px " &
        $node.cornerRadius[3] & "px"
      )

  for i, n in node.nodes:
    draw(i, n, node)

var startTime: float

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

  if document.activeElement != nil:
    let selection = document.getSelection()
    keyboard.textCursor = selection.anchorOffset
    keyboard.selectionCursor = selection.focusOffset
  else:
    keyboard.textCursor = 0
    keyboard.selectionCursor = 0

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
  when type(canvas.style.zIndex) is cstring:
    canvas.style.zIndex = "-1"
  else:
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

  # Only set mouse style when it changes.
  if mouse.prevCursorStyle != mouse.cursorStyle:
    mouse.prevCursorStyle = mouse.cursorStyle
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

  root.removeExtraChildren()

  computeLayout(nil, root)
  computeScreenBox(nil, root)

  draw(0, root, nil)

  drawFinish()

proc requestHardRedraw(time: float = 0.0) =
  requestedFrame = false
  hardRedraw()

proc refresh*() =
  if not requestedFrame:
    requestedFrame = true
    discard dom.window.requestAnimationFrame(requestHardRedraw)

proc startFidget*(draw: proc(), load: proc() = nil, w = 0, h = 0) =
  ## Start the HTML backend
  ## NOTE: returns instantly!
  drawMain = draw
  loadMain = load

  dom.window.addEventListener "load", proc(event: Event) =
    ## called when html page loads and JS can start running
    rootDomNode = document.createElement("div")
    rootDomNode.style.position = "absolute"
    rootDomNode.style.top = "0px"
    rootDomNode.style.left = "0px"
    document.body.appendChild(rootDomNode)
    # Add a canvas node for drawing.
    canvasNode = document.createElement("canvas")
    document.body.appendChild(canvasNode)
    # Add a style node.
    var styleNode = document.createElement("style")
    styleNode.innerText = defaultStyle
    document.head.appendChild(styleNode)
    refresh()

  dom.window.addEventListener "resize", proc(event: Event) =
    ## Resize does not need to do anything special in HTML mode
    refresh()

  dom.window.addEventListener "scroll", proc(event: Event) =
    ## Scroll does not need to do anything special in HTML mode
    refresh()

  dom.window.addEventListener "wheel", proc(event: Event) =
    ## When wheel is used
    let event = cast[WheelEvent](event)
    mouse.wheelDelta += vec2(event.deltaX, event.deltaY)
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

  dom.window.addEventListener "keypress", proc(event: Event) =
    let event = cast[KeyboardEvent](event)
    if keyboard.focusNode != nil and not keyboard.focusNode.multiline:
      if event.keyCode == 13:
        event.preventDefault()

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

  proc fixMultiline() =
    ## fix keyboard input if it has \n in it
    if keyboard.focusNode != nil and not keyboard.focusNode.multiline:
      if "\n" in keyboard.input:
        keyboard.input = keyboard.input.replace("\n", "")
        document.activeElement.innerText = keyboard.input
        # TODO Keep the selection the same

  dom.window.addEventListener "input", proc(event: Event) =
    ## When INPUT element has keyboard input this is called
    keyboard.input = $document.activeElement.innerText
    keyboard.state = Press
    fixMultiline()
    refresh()

  dom.window.addEventListener "paste", proc(ev: Event) =
    ## When text is pasted into an input a content editable tag,
    ## it needs to have its formatting removed.
    let event = cast[ClipboardEvent](ev)
    if keyboard.focusNode == nil:
      return
    var paste = $event.clipboardData.getData("text")
    var selection = window.document.getSelection()
    selection.deleteFromDocument()
    if selection.rangeCount == 0:
      return
    selection.getRangeAt(0).insertNode(document.createTextNode(paste))
    selection.collapse()
    ev.preventDefault()
    keyboard.input = $document.activeElement.innerText
    echo "keyboard.input"
    echo keyboard.input
    keyboard.state = Press
    fixMultiline()
    refresh()

  dom.window.addEventListener "focusin", proc(event: Event) =
    ## When INPUT element gets focus this is called, set the keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "focus" does not bubble, so its not used here.
    var uid: string
    if document.activeElement.hasAttribute("id"):
      uid = $document.activeElement.getAttribute("id")
    else:
      uid = $document.activeElement.parentNode.getAttribute("id")
    #Note: keyboard.onUnFocusNode is set by focus out.
    let node = nodeLookup[uid]
    keyboard.input = node.text
    keyboard.onFocusNode = node
    keyboard.focusNode = node
    refresh()

  dom.window.addEventListener "focusout", proc(event: Event) =
    ## When INPUT element looses focus this is called, clear keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "blur" does not bubble, so its not used here.
    # redraw everything to sync up the bind(string)
    keyboard.onUnFocusNode = keyboard.focusNode
    # Note: onFocusNode and focusNode are set by focusin.
    keyboard.onFocusNode = nil
    keyboard.focusNode = nil
    keyboard.input = ""
    refresh()

  dom.window.addEventListener "popstate", proc(event: Event) =
    ## Called when users presses back or forward buttons.
    refresh()

  document.fonts.onloadingdone = proc(event: Event) =
    computeTextBoxCache.clear()
    forceTextReLayout = true
    hardRedraw()
    forceTextReLayout = false

  if loadMain != nil:
    loadMain()

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

proc setUrl*(url: string, scrollToTop = true) =
  ## Goes to a new URL, inserts it into history so that back button works.
  ## Also scrolls to the top of the page to mimic how an HTML reload would look.
  if getUrl() != url:
    type Dummy = object
    dom.window.history.pushState(Dummy(), "", url)
    if scrollToTop:
      document.documentElement.scrollTop = 0
    refresh()

proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads a font.
  dom.window.document.write &"""
    <style>@font-face {{font-family: '{name}'; src: URL('{dataDir / pathOrUrl}') format('truetype');}}</style>
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

proc setWindowBounds*(min, max: Vec2) =
  ## setWindowBounds does not work in JS mode.
  discard

proc httpGet*(url: string): HttpCall =
  if url notin httpCalls:
    result = HttpCall()

    result.httpRequest = newXMLHttpRequest()
    proc httpGetCb(e: Event) {.closure.} =
      if result.httpRequest.readyState == rsDONE:
        if result.httpRequest.status == 200:
          result.status = Ready
          result.data = $result.httpRequest.responseText
          result.json = parseJson(result.data)
        else:
          result.status = Error
      refresh()
    result.httpRequest.onreadystatechange = httpGetCb
    result.httpRequest.open("GET", url)
    result.httpRequest.send()

    httpCalls[url] = result
    result.status = Loading
  else:
    result = httpCalls[url]

  when not defined(js):
    if result.status == Loading and result.future.finished:
      result.status = Ready
      result.data = result.future.read()

  return
