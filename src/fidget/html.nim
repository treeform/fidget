import chroma, dom2 as dom, html5_canvas, internal, math, strformat, strutils,
    tables, uibase, vmath

type
  PerfCounter* = object
    drawMain*: float
    numLowLevelCalls*: int

var
  groupCache*: seq[Group]
  domCache*: seq[Element]

  rootDomNode*: Element
  canvasNode*: Element
  ctx*: CanvasRenderingContext2D

  forceTextRelayout*: bool

  perf*: PerfCounter

var colorCache = newTable[chroma.Color, string]()
proc toHtmlRgbaCached(color: Color): string =
  result = colorCache.getOrDefault(color)
  if result == "":
    result = color.toHtmlRgba()
    colorCache[color] = result

proc removeAllChildren(dom: Node) =
  while dom.firstChild != nil:
    dom.removeChild(dom.firstChild)

proc removeTextSelection*() {.exportc.} =
  echo dom.window.document.getSelection()
  dom.window.document.getSelection().removeAllRanges()

var computeTextBoxCache = newTable[string, (float, float)]()
proc computeTextBox*(text: string, width: float, fontName: string,
    fontSize: float): (float, float) =
  ## Give text, font and a width of the box, compute how far the
  ## text will fill down the hight of the box.
  let key = text & $width & fontName & $fontSize
  if key in computeTextBoxCache:
    return computeTextBoxCache[key]
  var tempDiv = document.createElement("div")
  document.body.appendChild(tempDiv)
  tempDiv.style.fontSize = $fontSize & "px"
  tempDiv.style.fontFamily = fontName
  tempDiv.style.position = "absolute"
  tempDiv.style.left = "-1000"
  tempDiv.style.top = "-1000"
  tempDiv.style.maxWidth = $width & "px"
  tempDiv.innerHTML = text
  result[0] = float tempDiv.clientWidth
  result[1] = float tempDiv.clientHeight
  document.body.removeChild(tempDiv)
  computeTextBoxCache[key] = result

proc computeTextHeight*(text: string, width: float, fontName: string,
    fontSize: float): float =
  ## Give text, font and a width of the box, compute how far the
  ## text will fill down the hight of the box.
  let (_, h) = computeTextBox(text, width, fontName, fontSize)
  return h

proc tag(group: Group): string =
  if group.kind == "":
    return ""
  elif group.kind == "text":
    if group.editableText:
      if group.multiline:
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

proc drawDiff(current: Group) =

  if groupCache.len == numGroups:
    inc perf.numLowLevelCalls

    var old = Group()
    old.kind = current.kind
    old.editableText = current.editableText
    old.multiline = current.multiline
    var dom = createDefaultElement(current.tag)
    rootDomNode.appendChild(dom)

    groupCache.add(old)
    domCache.add(dom)

  var
    dom = domCache[numGroups]
    old = groupCache[numGroups]

  # When tags don't match we can't convert a node
  # into another node, so we have to recreate them
  if old.tag != current.tag:
    inc perf.numLowLevelCalls

    old = Group()
    old.kind = current.kind
    old.editableText = current.editableText
    old.multiline = current.multiline
    dom = createDefaultElement(current.tag)
    rootDomNode.replaceChild(dom, rootDomNode.children[numGroups])
    domCache[numGroups] = dom
    groupCache[numGroups] = old

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
    if current.kind == "text":
      dom.style.color = $current.fill.toHtmlRgba()
      dom.style.backgroundColor = "rgba(0,0,0,0)"
    else:
      dom.style.backgroundColor = $current.fill.toHtmlRgba()
      dom.style.color = "rgba(0,0,0,0)"

  # check storke (border color)
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

  # check cornerRadius (border raidus)
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
    # TODO check this
    if current.textStyle.lineHeight == 0:
      dom.style.lineHeight = "normal"
    else:
      dom.style.lineHeight = $current.textStyle.lineHeight & "px"

  # check imageName (background image)
  if old.imageName != current.imageName:
    inc perf.numLowLevelCalls
    old.imageName = current.imageName
    if current.imageName != "":
      dom.style.backgroundImage = "url(" & current.imageName & ")"
      dom.style.backgroundSize = "100% 100%"
    else:
      dom.style.backgroundImage = ""

  # check placeholder (gray text that appears inside when no text)
  if old.placeholder != current.placeholder:
    old.placeholder = current.placeholder
    dom.setAttribute("placeholder", current.placeholder)

  if current.textPadding != old.textPadding:
    old.textPadding = current.textPadding
    dom.style.padding = $current.textPadding & "px"
    dom.style.boxSizing = "border-box"

  if old.screenBox.wh == current.box.wh:
    current.textOffset = old.textOffset

  if current.kind == "text":
    if current.editableText:
      if old.text != current.text:
        if document.activeElement != dom:
          cast[TextAreaElement](dom).value = current.text
    else:
      if forceTextRelayout or (old.text != current.text):
        inc perf.numLowLevelCalls
        old.text = current.text

        dom.innerText = current.text

        if current.textStyle.textAlignHorizontal != hLeft or
            current.textStyle.textAlignVertical != vTop:
          var box = computeTextBox(
            current.text,
            current.screenBox.w,
            current.textStyle.fontFamily,
            current.textStyle.fontSize
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
              top = current.screenBox.h - box[1]
            of vCenter:
              top = current.screenBox.h / 2 - box[1] / 2

          current.textOffset.x = left
          current.textOffset.y = top

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

  inc numGroups

proc draw*(group: Group) =
  drawDiff(group)

var startTime: float
var prevMouseCursorStyle: MouseCursorStyle

proc drawStart() =
  startTime = dom.window.performance.now()
  numGroups = 0
  perf.numLowLevelCalls = 0

  uibase.window.innerUrl = $dom.window.location.search

  # set up root HTML
  root.box.x = 0
  root.box.y = 0
  root.box.w = float dom.window.innerWidth #document.body.clientWidth #
  root.box.h = float document.body.clientHeight
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
  var devicePixelRatio = 2.0
  var
    width = float(dom.window.innerWidth)
    height = float(dom.window.innerHeight)
  canvas.clientWidth = int(width)
  canvas.clientHeight = int(height)
  canvas.width = int(width * devicePixelRatio)
  canvas.height = int(height * devicePixelRatio)

  canvas.style.display = "block"
  canvas.style.position = "absolute"
  canvas.style.zIndex = -1
  canvas.style.left = cstring($scrollBox.x & "px")
  canvas.style.top = cstring($scrollBox.y & "px")
  canvas.style.width = cstring($width & "px")
  canvas.style.height = cstring($height & "px")

  ctx.scale(devicePixelRatio, devicePixelRatio)

  mouse.cursorStyle = Default

proc drawFinish() =

  perf.drawMain = dom.window.performance.now() - startTime

  #echo perf.drawMain
  #echo numGroups
  #echo perf.numLowLevelCalls

  # remove left over nodes
  while rootDomNode.childNodes.len > numGroups:
    rootDomNode.removeChild(domCache[^1])
    discard groupCache.pop()
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

  # Used for onFocus/onUnFocus.
  keyboard.prevInputFocusIdPath = keyboard.inputFocusIdPath

proc hardRedraw() =
  if rootDomNode == nil: # check if we have loaded
    return

  setupRoot()

  drawStart()
  drawMain()
  drawFinish()

proc requestHardRedraw(time: float = 0.0) =
  requestedFrame = false
  hardRedraw()

proc redraw*() =
  if not requestedFrame:
    requestedFrame = true
    discard dom.window.requestAnimationFrame(requestHardRedraw)

proc set*(keyboard: Keyboard, state: KeyState, event: KeyboardEvent) =
  keyboard.state = state
  keyboard.keyCode = event.keyCode
  var keyString: cstring
  asm """`keyString` = `event`.key"""
  keyboard.keyString = $keyString
  keyboard.altKey = event.altKey
  keyboard.ctrlKey = event.ctrlKey
  keyboard.shiftKey = event.shiftKey

proc startFidget*(draw: proc()) =
  ## Start the HTML backend
  ## NOTE: returns instantly!
  drawMain = draw

  uibase.window.innerUrl = $dom.window.location.pathname

  dom.window.addEventListener "load", proc(event: Event) =
    ## called when html page loads and JS can start running
    rootDomNode = document.createElement("div")
    document.body.appendChild(rootDomNode)

    canvasNode = document.createElement("canvas")
    document.body.appendChild(canvasNode)
    redraw()

  dom.window.addEventListener "resize", proc(event: Event) =
    ## Resize does not need to do anything special in HTML mode
    redraw()

  dom.window.addEventListener "scroll", proc(event: Event) =
    ## Scroll does not need to do anything special in HTML mode
    redraw()

  dom.window.addEventListener "mousedown", proc(event: Event) =
    ## When mouse button is pressed
    let event = cast[MouseEvent](event)
    mouse.pos.x = float event.pageX
    mouse.pos.y = float event.pageY
    mouse.click = true
    mouse.down = true
    hardRedraw()
    mouse.click = false

  dom.window.addEventListener "mouseup", proc(event: Event) =
    ## When mouse button is released
    redraw()
    mouse.down = false

  dom.window.addEventListener "mousemove", proc(event: Event) =
    # When mouse moves
    let event = cast[MouseEvent](event)
    mouse.pos.x = float event.pageX
    mouse.pos.y = float event.pageY
    redraw()

  dom.window.addEventListener "keydown", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with keyup for continuous things like scroll or games
    let event = cast[KeyboardEvent](event)
    keyboard.set(Down, event)
    hardRedraw()
    if keyboard.state != Empty:
      keyboard.consume()
    else:
      event.preventDefault()

  dom.window.addEventListener "keyup", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with keydown
    let event = cast[KeyboardEvent](event)
    keyboard.set(Up, event)
    hardRedraw()
    if keyboard.state != Empty:
      keyboard.consume()
    else:
      event.preventDefault()

  # dom.window.addEventListener "keypress", proc(event: Event) =
  #   ## When keyboards key is pressed
  #   ## Used for typing because of key repeats
  #   keyboard.set(Press, event)
  #   hardRedraw()
  #   if keyboard.state != Empty:
  #     keyboard.use()
  #   else:
  #     event.preventDefault()

  proc isTextTag(node: Node): bool =
    node.nodeName == "TEXTAREA" or node.nodeName == "INPUT"

  dom.window.addEventListener "input", proc(event: Event) =
    ## When INPUT element has keyboard input this is called
    if document.activeElement.isTextTag:
      keyboard.input = $(cast[TextAreaElement](document.activeElement).value)
      keyboard.inputFocusIdPath = $document.activeElement.id
      keyboard.state = Press
      redraw()

  dom.window.addEventListener "focusin", proc(event: Event) =
    ## When INPUT element gets focus this is called, set the keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "focus" does not bubble, so its not used here.
    if document.activeElement.isTextTag:
      keyboard.input = $(cast[TextAreaElement](document.activeElement).value)
      keyboard.inputFocusIdPath = $document.activeElement.id
      redraw()

  dom.window.addEventListener "focusout", proc(event: Event) =
    ## When INPUT element looses focus this is called, clear keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "blur" does not bubble, so its not used here.

    # redraw everything to sync up the bind(string)
    redraw()

    keyboard.input = ""
    keyboard.inputFocusIdPath = ""
    redraw()

  dom.window.addEventListener "popstate", proc(event: Event) =
    ## Called when users presses back or forward buttons.
    redraw()

  document.fonts.onloadingdone = proc(event: Event) =
    computeTextBoxCache.clear()
    forceTextRelayout = true
    hardRedraw()
    forceTextRelayout = false

proc goto*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  type Dummy = object
  dom.window.history.pushState(Dummy(), "", url)
  echo "goto ", url
  uibase.window.innerUrl = url
  redraw()

proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard dom.window.open(url, "_blank")

proc openBrowserWithText*(text: string) =
  ## Opens a URL in a browser
  var window = dom.window.open("", "_blank")
  window.document.write("<code style=display:block;white-space:pre-wrap>" &
      text & "</code>")

proc `title=`*(win: uibase.Window, title: string) =
  ## Sets window title
  if win.innerTitle != title:
    dom.document.title = title
    win.innerTitle = title
    redraw()

proc `title`*(win: uibase.Window): string =
  ## Gets window title
  win.innerTitle

proc `url=`*(win: uibase.Window, url: string) =
  ## Sets window url
  if win.innerUrl != url:
    win.innerUrl = url
    redraw()

proc `url`*(win: uibase.Window): string =
  ## Gets window url
  #win.innerUrl
  return $dom.window.location.pathname

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
