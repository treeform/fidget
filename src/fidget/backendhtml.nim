import uibase, dom2 as dom, chroma, strutils, math, tables
import print

var
  divCache*: seq[Group]
  rootDomNode: Element


var colorCache = newTable[Color, string]()
proc toHtmlRgbaCached(color: Color): string =
  result = colorCache.getOrDefault(color)
  if result == "":
    result = color.toHtmlRgba()
    colorCache[color] = result


proc removeAllChildren(dom: Node) =
  while dom.firstChild != nil:
    dom.removeChild(dom.firstChild)


var computeTextBoxCache = newTable[string, (float, float)]()
proc computeTextBox*(text: string, width: float, fontName: string, fontSize: float): (float, float) =
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


proc computeTextHeight*(text: string, width: float, fontName: string, fontSize: float): float =
  ## Give text, font and a width of the box, compute how far the
  ## text will fill down the hight of the box.
  let (w, h) = computeTextBox(text, width, fontName, fontSize)
  return h


proc drawDiff(group: Group) =

  while divCache.len <= numGroups:
    rootDomNode.appendChild(document.createElement("div"))
    inc perf.numLowLevelCalls
    divCache.add(Group())
  var
    dom = rootDomNode.childNodes[numGroups]
    cacheGroup = divCache[numGroups]

  if cacheGroup.idPath != current.idPath:
    inc perf.numLowLevelCalls
    cacheGroup.id = current.id
    cacheGroup.idPath = current.idPath
    dom.id = current.idPath

  if cacheGroup.drawable != current.drawable:
    dom.removeAllChildren()
    cacheGroup.drawable = current.drawable
    if current.drawable:
      var canvasNode = document.createElement("canvas")
      canvasNode.id = current.idPath & "-canvas"
      canvasNode.style.width = $current.box.w & "px"
      canvasNode.style.height = $current.box.h & "px"
      canvasNode.setAttribute("width", $current.box.w)
      canvasNode.setAttribute("height", $current.box.h)
      dom.appendChild(canvasNode)

  if cacheGroup.screenBox != current.screenBox:
    inc perf.numLowLevelCalls
    cacheGroup.screenBox = current.screenBox
    dom.style.position = "absolute"
    dom.style.left = $current.screenBox.x & "px"
    dom.style.top = $current.screenBox.y & "px"
    dom.style.width = $current.screenBox.w & "px"
    dom.style.height = $current.screenBox.h & "px"

    if current.kind == "text":
      if dom.childNodes.len > 0:
        var textAreaNode = dom.childNodes[0]
        textAreaNode.style.width = $current.box.w & "px"
        textAreaNode.style.height = $current.box.h & "px"

    if current.drawable:
      if dom.childNodes.len > 0:
        var canvasNode = dom.childNodes[0]
        canvasNode.style.width = $current.box.w & "px"
        canvasNode.style.height = $current.box.h & "px"
        canvasNode.setAttribute("width", $current.box.w)
        canvasNode.setAttribute("height", $current.box.h)

  if cacheGroup.fill != current.fill or cacheGroup.kind != current.kind:
    inc perf.numLowLevelCalls
    cacheGroup.fill = current.fill
    if current.kind == "text":
      dom.style.color = $current.fill.toHtmlRgba()
      dom.style.backgroundColor = "rgba(0,0,0,0)"
    else:
      dom.style.backgroundColor = $current.fill.toHtmlRgba()
      dom.style.color = "rgba(0,0,0,0)"

  if cacheGroup.stroke != current.stroke or
      cacheGroup.strokeWeight != current.strokeWeight:
    inc perf.numLowLevelCalls
    cacheGroup.stroke = current.stroke
    cacheGroup.strokeWeight = current.strokeWeight
    if current.strokeWeight > 0:
      dom.style.borderStyle = "solid"
      dom.style.boxSizing = "border-box"
      dom.style.borderColor = $current.stroke.toHtmlRgba()
      dom.style.borderWidth = $current.strokeWeight & "px"
    else:
      dom.style.borderStyle = "none"

  if cacheGroup.transparency != current.transparency:
    inc perf.numLowLevelCalls
    cacheGroup.transparency = current.transparency
    dom.style.opacity = $current.transparency

  if cacheGroup.textStyle != current.textStyle:
    inc perf.numLowLevelCalls
    cacheGroup.textStyle = current.textStyle
    dom.style.fontFamily = current.textStyle.fontFamily
    dom.style.fontSize = $current.textStyle.fontSize & "px"
    dom.style.fontWeight = $current.textStyle.fontWeight
    #dom.style.lineHeight = $current.textStyle.lineHeight & "px"

  if cacheGroup.kind == "text" and current.kind != "text":
    dom.removeAllChildren()
    cacheGroup.text = ""

  if current.kind == "text":
    if current.editableText:
      # input element were you can type
      var textAreaNode: Node
      if cacheGroup.editableText == false or dom.childNodes.len == 0:
        dom.removeAllChildren()
        if current.multiline:
          textAreaNode = document.createElement("textarea")
        else:
          textAreaNode = document.createElement("input")
        textAreaNode.setAttribute("type", "text")
        textAreaNode.style.border = "none"
        textAreaNode.style.outline = "none"
        textAreaNode.style.width = $current.box.w & "px"
        textAreaNode.style.height = $current.box.h & "px"
        textAreaNode.style.backgroundColor = "transparent"
        textAreaNode.style.fontFamily = "inherit"
        textAreaNode.style.fontSize = "inherit"
        textAreaNode.style.fontWeight = "inherit"
        textAreaNode.style.padding = "0px"
        textAreaNode.style.resize = "none"
        #textAreaNode.style.overflow = "hidden"
        dom.appendChild(textAreaNode)
        cacheGroup.text = ""
        cacheGroup.placeholder = ""
        cacheGroup.editableText = current.editableText
      else:
        textAreaNode = dom.childNodes[0]

      cacheGroup.editableText = true

      if cacheGroup.text != current.text:
        cacheGroup.text = current.text
        #textAreaNode.setAttribute("value", current.text)
        cast[TextAreaElement](textAreaNode).value = current.text

      if cacheGroup.placeholder != current.placeholder:
        cacheGroup.placeholder = current.placeholder
        textAreaNode.setAttribute("placeholder", current.placeholder)

    else:
      # normal text element
      if cacheGroup.editableText == true:
        dom.removeAllChildren()
        cacheGroup.text = ""
        cacheGroup.editableText = current.editableText

      if cacheGroup.text != current.text:
        inc perf.numLowLevelCalls
        cacheGroup.text = current.text

        # remove old text
        dom.removeAllChildren()

        var textDiv = document.createElement("span")
        dom.appendChild(textDiv)

        if current.text != "":
          # group has text, add text
          var textDom = document.createTextNode(current.text)
          textDiv.appendChild(textDom)

        if current.textStyle.textAlignHorizontal != -1 or current.textStyle.textAlignVertical != -1:
          var box = computeTextBox(
            current.text,
            current.screenBox.w,
            current.textStyle.fontFamily,
            current.textStyle.fontSize
          )
          textDiv.style.position = "absolute"
          case current.textStyle.textAlignHorizontal:
            of -1:
              textDiv.style.left = "0px"
            of 1:
              textDiv.style.left = $(current.screenBox.w - box[0]) & "px"
            else:
              textDiv.style.left = $(current.screenBox.w / 2 - box[0] / 2) & "px"

          case current.textStyle.textAlignVertical:
            of -1:
              textDiv.style.top = "0px"
            of 1:
              textDiv.style.top = $(current.screenBox.h - box[1]) & "px"
            else:
              textDiv.style.top = $(current.screenBox.h / 2 - box[1] / 2) & "px"


  if cacheGroup.imageName != current.imageName:
    cacheGroup.imageName = current.imageName
    if current.imageName != "":
      dom.style.backgroundImage = "url(" & current.imageName & ".png)"
      dom.style.backgroundSize = "100% 100%"
    else:
      dom.style.backgroundImage = ""

  if cacheGroup.cornerRadius != current.cornerRadius:
    cacheGroup.cornerRadius = current.cornerRadius
    dom.style.borderRadius = (
      $current.cornerRadius[0] & "px " &
      $current.cornerRadius[1] & "px " &
      $current.cornerRadius[2] & "px " &
      $current.cornerRadius[3] & "px"
    )

  # kind should be the last thing to change
  cacheGroup.kind = current.kind

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

  document.body.style.overflowX = "auto"
  document.body.style.overflowY = "auto"

  mouse.cursorStyle = Default


proc drawFinish() =

  perf.drawMain = dom.window.performance.now() - startTime

  #echo perf.drawMain
  #echo numGroups
  #echo perf.numLowLevelCalls

  # remove left over nodes
  while rootDomNode.childNodes.len > numGroups:
    rootDomNode.removeChild(rootDomNode.lastChild)
    discard divCache.pop()

  # Only set mouse style when it changes.
  if prevMouseCursorStyle != mouse.cursorStyle:
    prevMouseCursorStyle = mouse.cursorStyle
    case mouse.cursorStyle:
      of Default:
        rootDomNode.style.cursor = "default"
      of Pointer:
        rootDomNode.style.cursor = "pointer"

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


proc set*(keyboard: Keyboard, state: KeyState, event: Event) =
  keyboard.state = state
  keyboard.keyCode = event.keyCode
  var keyString: cstring
  asm """`keyString` = `event`.key"""
  keyboard.keyString = $keyString
  keyboard.altKey = event.altKey
  keyboard.ctrlKey = event.ctrlKey
  keyboard.shiftKey = event.shiftKey


proc startFidget*() =
  ## Start the Fidget UI

  uibase.window.innerUrl = $dom.window.location.pathname

  dom.window.addEventListener "load", proc(event: Event) =
    ## called when html page loads and JS can start running
    rootDomNode = document.createElement("div")
    document.body.appendChild(rootDomNode)
    redraw()

  dom.window.addEventListener "resize", proc(event: Event) =
    ## Resize does not need to do anything special in HTML mode
    redraw()

  dom.window.addEventListener "scroll", proc(event: Event) =
    ## Scroll does not need to do anything special in HTML mode
    redraw()

  dom.window.addEventListener "mousedown", proc(event: Event) =
    ## When mouse button is pressed
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
    mouse.pos.x = float event.pageX
    mouse.pos.y = float event.pageY
    redraw()

  dom.window.addEventListener "keydown", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with keyup for continuous things like scroll or games
    keyboard.set(Down, event)
    hardRedraw()
    if keyboard.state != Empty:
      keyboard.use()
    else:
      event.preventDefault()

  dom.window.addEventListener "keyup", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with keydown
    keyboard.set(Up, event)
    hardRedraw()
    if keyboard.state != Empty:
      keyboard.use()
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
      keyboard.inputFocusIdPath = $document.activeElement.parentElement.id
      keyboard.state = Press
      redraw()

  dom.window.addEventListener "focusin", proc(event: Event) =
    ## When INPUT element gets focus this is called, set the keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "focus" does not bubble, so its not used here.
    if document.activeElement.isTextTag:
      keyboard.input = $(cast[TextAreaElement](document.activeElement).value)
      keyboard.inputFocusIdPath = $document.activeElement.parentElement.id
      redraw()

  dom.window.addEventListener "focusout", proc(event: Event) =
    ## When INPUT element looses focus this is called, clear keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "blur" does not bubble, so its not used here.
    keyboard.input = ""
    keyboard.inputFocusIdPath = ""
    redraw()

  dom.window.addEventListener "popstate", proc(event: Event) =
    ## Called when users presses back or forward buttons.
    redraw()


proc goto*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  type dummy = object
  dom.window.history.pushState(dummy(), "", url)
  echo "goto ", url
  uibase.window.innerUrl = url
  redraw()


proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard dom.window.open(url, "_blank")


proc openBrowserWithText*(text: string) =
  ## Opens a URL in a browser
  var window = dom.window.open("", "_blank")
  window.document.write("<code style=display:block;white-space:pre-wrap>" & text & "</code>")


proc `title=`*(win: uibase.Window, title: string) =
  ## Sets window title
  if win.innerTitle != title:
    dom.document.title = title
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