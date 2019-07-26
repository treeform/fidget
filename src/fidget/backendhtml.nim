import uibase, dom2 as dom, chroma, strutils, math, tables
import print

var
  divCache*: seq[Group]
  rootDomNode: Element


proc removeAllChildren(dom: Node) =
  while dom.firstChild != nil:
    dom.removeChild(dom.firstChild)


var computeTextHeightCache = newTable[string, float]()
proc computeTextHeight*(text: string, width: float, fontName: string, fontSize: float): float =
  ## Give text, font and a width of the box, compute how far the
  ## text will fill down the hight of the box.
  let key = text & $width & fontName & $fontSize
  if key in computeTextHeightCache:
    return computeTextHeightCache[key]
  var tempDiv = document.createElement("div")
  document.body.appendChild(tempDiv)
  tempDiv.style.fontSize = $fontSize & "px"
  tempDiv.style.fontFamily = fontName
  tempDiv.style.position = "absolute"
  tempDiv.style.left = "-1000"
  tempDiv.style.top = "-1000"
  tempDiv.style.width = $width & "px"
  tempDiv.innerHTML = text
  result = float tempDiv.clientHeight
  document.body.removeChild(tempDiv)
  computeTextHeightCache[key] = result


proc draw*(group: Group) =

  while divCache.len <= numGroups:
    rootDomNode.appendChild(document.createElement("div"))
    inc perf.numLowLevelCalls
    divCache.add(Group())
  var
    dom = rootDomNode.childNodes[numGroups]
    cacheGroup = divCache[numGroups]

  if cacheGroup.id != current.id:
    inc perf.numLowLevelCalls
    cacheGroup.id = current.id
    dom.id = current.id

  if cacheGroup.screenBox != current.screenBox:
    inc perf.numLowLevelCalls
    cacheGroup.screenBox = current.screenBox
    dom.style.position = "absolute"
    dom.style.left = $current.screenBox.x & "px"
    dom.style.top = $current.screenBox.y & "px"
    dom.style.width = $current.screenBox.w & "px"
    dom.style.height = $current.screenBox.h & "px"

  if cacheGroup.fill != current.fill or cacheGroup.kind != current.kind:
    inc perf.numLowLevelCalls
    cacheGroup.fill = current.fill
    if current.kind == "text":
      dom.style.color = $current.fill.toHtmlRgba()
      dom.style.backgroundColor = "rgba(0,0,0,0)"
    else:
      dom.style.backgroundColor = $current.fill.toHtmlRgba()
      dom.style.color = "rgba(0,0,0,0)"

  if cacheGroup.stroke != current.stroke:
    inc perf.numLowLevelCalls
    cacheGroup.stroke = current.stroke
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
      var inputDiv: Node
      if cacheGroup.editableText == false or dom.childNodes.len == 0:
        dom.removeAllChildren()
        inputDiv = document.createElement("input")
        inputDiv.setAttribute("type", "text")
        inputDiv.style.border = "none"
        inputDiv.style.outline = "none"
        inputDiv.style.width = "100%"
        inputDiv.style.backgroundColor = "transparent"
        inputDiv.style.fontFamily = "inherit"
        inputDiv.style.fontSize = "inherit"
        inputDiv.style.fontWeight = "inherit"
        inputDiv.style.padding = "0px"
        dom.appendChild(inputDiv)
        cacheGroup.text = ""
        cacheGroup.placeholder = ""
        cacheGroup.editableText = current.editableText
      else:
        inputDiv = dom.childNodes[0]

      cacheGroup.editableText = true

      if cacheGroup.text != current.text:
        cacheGroup.text = current.text
        inputDiv.setAttribute("value", current.text)

      if cacheGroup.placeholder != current.placeholder:
        cacheGroup.placeholder = current.placeholder
        inputDiv.setAttribute("placeholder", current.placeholder)

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

        textDiv.style.position = "absolute"

        case current.textStyle.textAlignHorizontal:
          of -1:
            textDiv.style.left = "0px"
          of 1:
            textDiv.style.right = "0px"
          else:
            textDiv.style.left = "50%"

        case current.textStyle.textAlignVertical:
          of -1:
            textDiv.style.top = "0px"
          of 1:
            textDiv.style.bottom = "0px"
          else:
            textDiv.style.bottom = "50%"

        if current.textStyle.textAlignVertical == 0:
          if current.textStyle.textAlignHorizontal == 0:
            textDiv.style.transform = "translate(-50%,-50%)"
            textDiv.style.top = "50%"
            textDiv.style.bottom = ""
          else:
            textDiv.style.transform = "translate(0, -50%)"
            textDiv.style.top = "50%"
            textDiv.style.bottom = ""
        else:
          if current.textStyle.textAlignHorizontal == 0:
            textDiv.style.transform = "translate(-50%, 0)"

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
  scrollBox.h = float document.body.clientHeight

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

  # only set mouse style when it changes
  if prevMouseCursorStyle != mouse.cursorStyle:
    prevMouseCursorStyle = mouse.cursorStyle
    case mouse.cursorStyle:
      of Default:
        rootDomNode.style.cursor = "default"
      of Pointer:
        rootDomNode.style.cursor = "pointer"


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

  dom.window.addEventListener "input", proc(event: Event) =
    ## When INPUT element has keyboard input this is called
    if document.activeElement.nodeName == "INPUT":
      keyboard.input = $(cast[InputElement](document.activeElement).value)
      keyboard.inputFocusId = $document.activeElement.parentElement.id
      keyboard.state = Press
      redraw()


  dom.window.addEventListener "focusin", proc(event: Event) =
    ## When INPUT element gets focus this is called, set the keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "focus" does not bubble, so its not used here.
    if document.activeElement.nodeName == "INPUT":
      keyboard.input = $(cast[InputElement](document.activeElement).value)
      keyboard.inputFocusId = $document.activeElement.parentElement.id
      redraw()

  dom.window.addEventListener "focusout", proc(event: Event) =
    ## When INPUT element looses focus this is called, clear keyboard.input and
    ## the keyboard.inputFocusId
    ## Note: "blur" does not bubble, so its not used here.
    keyboard.input = ""
    keyboard.inputFocusId = ""
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