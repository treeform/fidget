import uibase, dom2, chroma, strutils


var divCache*: seq[Group]


proc draw*(group: Group) =


  # while document.body.childNodes.len <= numGroups:
  #   document.body.appendChild(document.createElement("div"))

  # var dom = document.body.childNodes[numGroups]
  # let id: cstring = current.id
  # asm "`dom`.id = `id`"
  # print "draw", current.id

  # dom.style.position = "absolute"
  # dom.style.left = $current.screenBox.x & "px"
  # dom.style.top = $current.screenBox.y & "px"
  # dom.style.width = $current.screenBox.w & "px"
  # dom.style.height = $current.screenBox.h & "px"

  # dom.style.backgroundColor = $current.fill.toHtmlRgba()
  # dom.style.color = $current.textColor.toHtmlRgba()

  # if current.text != "":
  #   # remove old text
  #   while dom.firstChild != nil:
  #     dom.removeChild(dom.firstChild)
  #   # group has text, add text
  #   var textDom = document.createTextNode(current.text)
  #   dom.appendChild(textDom)

  # inc numGroups

  while divCache.len <= numGroups:
    document.body.appendChild(document.createElement("div"))
    inc perf.numLowLevelCalls
    divCache.add(Group())

  var
    dom = document.body.childNodes[numGroups]
    cacheGroup = divCache[numGroups]

  # if current.fill.a == 0.0 and current.text == "":
  #   if cacheGroup.text != "":
  #     while dom.firstChild != nil:
  #       dom.removeChild(dom.firstChild)
  #   return

  if cacheGroup.id != current.id:
    inc perf.numLowLevelCalls
    cacheGroup.id = current.id
    let id: cstring = current.id
    asm "`dom`.id = `id`"

  if cacheGroup.screenBox != current.screenBox:
    inc perf.numLowLevelCalls
    cacheGroup.screenBox = current.screenBox
    dom.style.position = "absolute"
    dom.style.left = $current.screenBox.x & "px"
    dom.style.top = $current.screenBox.y & "px"
    dom.style.width = $current.screenBox.w & "px"
    dom.style.height = $current.screenBox.h & "px"

  if cacheGroup.fill != current.fill:
    inc perf.numLowLevelCalls
    cacheGroup.fill = current.fill
    dom.style.backgroundColor = $current.fill.toHtmlRgba()

  if cacheGroup.textColor != current.textColor:
    inc perf.numLowLevelCalls
    cacheGroup.textColor = current.textColor
    dom.style.color = $current.textColor.toHtmlRgba()

  if cacheGroup.textAlign != current.textAlign:
    inc perf.numLowLevelCalls
    cacheGroup.textAlign = current.textAlign
    dom.style.textAlign = toLowerAscii($current.textAlign)

  if cacheGroup.text != current.text:
    inc perf.numLowLevelCalls
    cacheGroup.text = current.text
    # remove old text
    while dom.firstChild != nil:
      dom.removeChild(dom.firstChild)

    if current.text != "":
      # group has text, add text
      var textDom = document.createTextNode(current.text)
      dom.appendChild(textDom)

    dom.style.whiteSpace = "pre"

  inc numGroups

var startTime: float

proc drawStart*() =
  startTime = window.performance.now()
  numGroups = 0
  perf.numLowLevelCalls = 0

  # set up root HTML
  root.box.x = 0
  root.box.y = 0
  root.box.w = float document.body.clientWidth
  root.box.h = float document.body.clientHeight

  scrollBox.x = float window.scrollX
  scrollBox.y = float window.scrollY
  scrollBox.w = float document.body.clientWidth
  scrollBox.h = float document.body.clientHeight

  document.body.style.overflowX = "hidden"
  document.body.style.overflowY = "scroll"


proc drawFinish*() =

  perf.drawMain = window.performance.now() - startTime

  # print perf.drawMain
  # print numGroups
  # print perf.numLowLevelCalls

  # remove left over nodes
  while document.body.childNodes.len > numGroups:
    document.body.removeChild(document.body.lastChild)
    discard divCache.pop()


proc hardRedraw*() =
  setupRoot()

  drawStart()
  drawMain()
  drawFinish()


proc requestHardRedraw*(time: float = 0.0) =
  requestedFrame = false
  hardRedraw()


proc redraw*() =
  if not requestedFrame:
    requestedFrame = true
    discard window.requestAnimationFrame(requestHardRedraw)

window.addEventListener "load", proc(event: Event) =
  redraw()

  # clear body of any html nodes
  while document.body.firstChild != nil:
    document.body.removeChild(document.body.firstChild)


window.addEventListener "resize", proc(event: Event) =
  redraw()


window.addEventListener "scroll", proc(event: Event) =
  redraw()


window.addEventListener "mousedown", proc(event: Event) =
  mouse.pos.x = float event.pageX
  mouse.pos.y = float event.pageY
  mouse.click = true
  mouse.down = true
  hardRedraw()
  mouse.click = false


window.addEventListener "mouseup", proc(event: Event) =
  redraw()
  mouse.down = false


window.addEventListener "mousemove", proc(event: Event) =
  # don't redraw(), too heavy
  mouse.pos.x = float event.pageX
  mouse.pos.y = float event.pageY
  redraw()


proc set*(keyboard: Keyboard, state: KeyState, event: Event) =
  keyboard.state = state
  keyboard.keyCode = event.keyCode
  var keyString: cstring
  asm """`keyString` = `event`.key"""
  keyboard.keyString = $keyString
  keyboard.altKey = event.altKey
  keyboard.ctrlKey = event.ctrlKey
  keyboard.shiftKey = event.shiftKey

proc use*(keyboard: Keyboard) =
  keyboard.state = Empty
  keyboard.keyCode = 0
  keyboard.keyString = ""
  keyboard.altKey = false
  keyboard.ctrlKey = false
  keyboard.shiftKey = false

proc use*(mouse: Mouse) =
  mouse.click = false

window.addEventListener "keydown", proc(event: Event) =
  keyboard.set(Down, event)
  hardRedraw()
  if keyboard.state != Empty:
    keyboard.use()
  else:
    event.preventDefault()

window.addEventListener "keyup", proc(event: Event) =
  keyboard.set(Up, event)
  hardRedraw()
  if keyboard.state != Empty:
    keyboard.use()
  else:
    event.preventDefault()

window.addEventListener "keypress", proc(event: Event) =
  keyboard.set(Press, event)
  hardRedraw()
  if keyboard.state != Empty:
    keyboard.use()
  else:
    event.preventDefault()