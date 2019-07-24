import macros, tables, json, strutils, chroma, print, vmath
import fidget/uibase
when defined(js):
  import fidget/backendhtml
  export backendhtml
elif defined(backendnull):
  import fidget/backendnull
  export backendnull
else:
  import fidget/backendopengl
  export backendopengl
export uibase, chroma


template node(kindStr: string, name: string, inner: untyped): untyped =
  ## Base temaptle for group, frame, rectange ...

  # we should draw the parent first as we are drawing the a child now
  parent = groupStack[^1]
  if not parent.wasDrawn:
    parent.draw()
    parent.wasDrawn = true

  current = Group()
  current.id = name
  current.kind = kindStr
  current.wasDrawn = false
  current.transparency = 1.0
  current.textStyle = parent.textStyle
  groupStack.add(current)

  inner

  if not current.wasDrawn:
    current.draw()
    current.wasDrawn = true

  discard groupStack.pop()
  if groupStack.len > 1:
    current = groupStack[^1]
  else:
    current = nil
  if groupStack.len > 2:
    parent = groupStack[^2]
  else:
    parent = nil


template group*(name: string, inner: untyped): untyped =
  ## Starts a new group.
  node("group", name, inner)


template frame*(name: string, inner: untyped): untyped =
  ## Starts a new frame.
  node("frame", name, inner)


template rectangle*(name: string, inner: untyped): untyped =
  ## Starts a new rectangle.
  node("rectangle", name, inner)


template text*(name: string, inner: untyped): untyped =
  ## Starts a new text element.
  node("text", name, inner)


template component*(name: string, inner: untyped): untyped =
  ## Starts a new component.
  node("component", name, inner)


template instance*(name: string, inner: untyped): untyped =
  ## Starts a new instance of a component.
  node("component", name, inner)


template rectangle*(color: string) =
  ## Shorthand for rectange with fill.
  rectangle "":
    box 0, 0, parent.box.w, parent.box.h
    fill color


proc mouseOverlapLogic(): bool =
  (not popupActive or inPopup) and mouse.pos.inside(current.screenBox)


template onClick*(inner: untyped) =
  ## OnClick event handler.
  if mouse.click and mouseOverlapLogic():
    inner

template onClickOutside*(inner: untyped) =
  ## On click outside event handler. Usefull for deselecting things.
  if mouse.click and not mouseOverlapLogic():
    inner

template onRightClick*(inner: untyped) =
  ## OnClick event handler.
  if mouse.rightClick and mouseOverlapLogic():
    inner

template onKey*(inner: untyped) =
  ## This is called when key is pressed.
  if keyboard.state == Press:
    inner


template onKeyUp*(inner: untyped) =
  ## This is called when key is pressed.
  if keyboard.state == Up:
    inner


template onKeyDown*(inner: untyped) =
  ## This is called when key is pressed.
  if keyboard.state == Down:
    inner


template onInput*(inner: untyped) =
  ## This is called when key is pressed and this element has focus
  if keyboard.state == Press and keyboard.inputFocusId == current.id:
    inner

template onHover*(inner: untyped) =
  ## Code in the block will run when this box is hovered.
  if mouseOverlapLogic():
    inner


template onDown*(inner: untyped) =
  ## Code in the block will run when this box is hovered.
  if mouse.down and mouseOverlapLogic():
    inner


proc id*(id: string) =
  ## Sets ID.
  current.id = id


proc font*(fontFamily: string, fontSize, fontWeight, lineHeight: float, textAlignHorizontal, textAlignVertical: int) =
  ## Sets the font
  current.textStyle.fontFamily = fontFamily
  current.textStyle.fontSize = fontSize
  current.textStyle.fontWeight = fontWeight
  current.textStyle.lineHeight = lineHeight
  current.textStyle.textAlignHorizontal = textAlignHorizontal
  current.textStyle.textAlignVertical = textAlignVertical

proc fontFamily*(fontFamily: string) =
  ## Sets the font family
  current.textStyle.fontFamily = fontFamily

proc fontSize*(fontSize: float) =
  ## Sets the font size in pixels
  current.textStyle.fontSize = fontSize

proc fontWeight*(fontWeight: float) =
  ## Sets the font weight
  current.textStyle.fontWeight = fontWeight

proc lineHeight*(lineHeight: float) =
  ## Sets the font size
  current.textStyle.lineHeight = lineHeight

proc textAlign*(textAlignHorizontal, textAlignVertical: int) =
  ## Sets the horizontal and vertical alignment
  current.textStyle.textAlignHorizontal = textAlignHorizontal
  current.textStyle.textAlignVertical = textAlignVertical

proc characters*(text: string) =
  ## Adds text to the group.
  if current.text == "":
    current.text = text
  else:
    current.text &= text


proc placeholder*(text: string) =
  ## Adds placeholder text to the group.
  current.placeholder = text


proc image*(imageName: string) =
  ## Adds text to the group.
  current.imageName = imageName


proc box*(x, y, w, h: float) =
  ## Sets the box dimentions.
  current.box.x = x
  current.box.y = y
  current.box.w = w
  current.box.h = h
  current.screenBox = current.box
  if parent != nil:
    current.screenBox = current.box + parent.screenBox


template box*(x, y, w, h: untyped) =
  ## Sets the box dimentions.
  box(float x, float y, float w, float h)


proc box*(b: Box) =
  ## Sets the box dimentions.
  box(b.x, b.y, b.w, b.h)


proc rotation*(rotationInDeg: float) =
  ## Sets rotation in degrees
  current.rotation = rotationInDeg


proc fill*(color: Color) =
  ## Sets background color.
  current.fill = color


proc fill*(color: string) =
  ## Sets background color.
  current.fill = parseHtmlColor(color)


proc fill*(color: string, alpha: float32) =
  ## Sets background color.
  current.fill = parseHtmlColor(color)
  current.fill.a = alpha


proc transparency*(transparency: float32) =
  ## Sets transparency.
  current.transparency = transparency


proc stroke*(color: Color) =
  ## Sets stroke/border color.
  current.stroke = color


proc stroke*(color: string) =
  ## Sets stroke/border color.
  current.stroke = parseHtmlColor(color)


proc stroke*(color: string, alpha: float32) =
  ## Sets stroke/border color.
  current.stroke = parseHtmlColor(color)
  current.stroke.a = alpha


proc strokeWeight*(weight: float) =
  ## Sets stroke/border weight.
  current.strokeWeight = weight


proc zLevel*(zLevel: int) =
  ## Sets zLevel.
  current.zLevel = zLevel


proc cornerRadius*(a, b, c, d: float) =
  ## Sets all radius of all 4 corners
  current.cornerRadius = (a, b, c, d)


proc cornerRadius*(radius: float) =
  ## Sets all radius of all 4 corners
  cornerRadius(radius, radius, radius, radius)


proc editableText*(editableText: bool) =
  ## Sets the code for this group
  current.editableText = editableText


template binding*(stringVarible: untyped) =
  ## Makes the current object text-editable and binds it to the
  ## stringVarible
  editableText true
  onInput:
    stringVarible = keyboard.input
    redraw()
  characters stringVarible

template override*(name: string, inner: untyped) =
  template `name`(): untyped =
    inner


# Navigation and URL functions
# proc goto*(url: string)
# proc openBrowser*(url: string)


proc parseParams*(): TableRef[string, string] =
  ## Parses the params of the main URL
  result = newTable[string, string]()
  if window.innerUrl.len > 0:
    for pair in window.innerUrl[1..^1].split("&"):
      let
        arr = pair.split("=")
        key = arr[0]
        val = arr[1]
      result[key] = val


