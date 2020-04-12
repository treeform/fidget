import chroma, fidget/uibase, json, macros, strutils, tables, vmath

export chroma, uibase

when defined(js):
  import fidget/htmlbackend
  export htmlbackend
elif defined(null):
  import fidget/nullbackend
  export nullbackend
else:
  import fidget/openglbackend
  export openglbackend

template node(kindStr: string, name: string, inner: untyped): untyped =
  ## Base template for group, frame, rectange ...

  # we should draw the parent first as we are drawing the a child now
  parent = groupStack[^1]
  if not parent.wasDrawn:
    parent.draw()
    parent.wasDrawn = true

  current = Group()
  current.id = name
  current.kind = kindStr
  current.wasDrawn = false
  current.textStyle = parent.textStyle
  current.cursorColor = parent.cursorColor
  current.highlightColor = parent.highlightColor
  current.transparency = parent.transparency
  groupStack.add(current)

  for g in groupStack:
    if g.id != "":
      if current.idPath.len > 0:
        current.idPath.add "-"
      current.idPath.add g.id

  #TODO: figure out if function wrap is good?
  # function wrap is needed for JS, but bad for non JS?
  # var innerFn = proc() =
  #   inner
  # innerFn()
  block:
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
  ## On click outside event handler. Useful for deselecting things.
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

proc hasKeyboardFocus*(group: Group): bool =
  ## Does a group have keyboard input focus.
  return keyboard.inputFocusIdPath == group.idPath

template onInput*(inner: untyped) =
  ## This is called when key is pressed and this element has focus.
  if keyboard.state == Press and current.hasKeyboardFocus():
    inner

template onHover*(inner: untyped) =
  ## Code in the block will run when this box is hovered.
  if mouseOverlapLogic():
    inner

template onDown*(inner: untyped) =
  ## Code in the block will run when this mouse is dragging.
  if mouse.down and mouseOverlapLogic():
    inner

template onFocus*(inner: untyped) =
  ## On focusing an input element.
  if keyboard.inputFocusIdPath == current.idPath and
      keyboard.prevInputFocusIdPath != current.idPath:
    inner

template onUnFocus*(inner: untyped) =
  ## On loosing focus on an imput element.
  if keyboard.inputFocusIdPath != current.idPath and
      keyboard.inputFocusIdPath == current.idPath:
    inner

proc id*(id: string) =
  ## Sets ID.
  current.id = id

proc font*(
  fontFamily: string,
  fontSize, fontWeight, lineHeight: float,
  textAlignHorizontal: HAlign,
  textAlignVertical: VAlign
) =
  ## Sets the font.
  current.textStyle.fontFamily = fontFamily
  current.textStyle.fontSize = fontSize
  current.textStyle.fontWeight = fontWeight
  current.textStyle.lineHeight = lineHeight
  current.textStyle.textAlignHorizontal = textAlignHorizontal
  current.textStyle.textAlignVertical = textAlignVertical

proc fontFamily*(fontFamily: string) =
  ## Sets the font family.
  current.textStyle.fontFamily = fontFamily

proc fontSize*(fontSize: float) =
  ## Sets the font size in pixels.
  current.textStyle.fontSize = fontSize

proc fontWeight*(fontWeight: float) =
  ## Sets the font weight.
  current.textStyle.fontWeight = fontWeight

proc lineHeight*(lineHeight: float) =
  ## Sets the font size.
  current.textStyle.lineHeight = lineHeight

proc textAlign*(textAlignHorizontal: HAlign, textAlignVertical: VAlign) =
  ## Sets the horizontal and vertical alignment.
  current.textStyle.textAlignHorizontal = textAlignHorizontal
  current.textStyle.textAlignVertical = textAlignVertical

proc textPadding*(textPadding: int) =
  ## Sets the text padding on editable multiline text areas.
  current.textPadding = textPadding

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
  ## Sets the box dimensions.
  current.box.x = x
  current.box.y = y
  current.box.w = w
  current.box.h = h
  current.screenBox = current.box
  if parent != nil:
    current.screenBox = current.box + parent.screenBox

proc box*(x, y, w, h: int|float32|float) =
  ## Sets the box dimensions with integers
  box(float x, float y, float w, float h)

proc box*(rect: Rect) =
  ## Sets the box dimensions with integers
  box(rect.x, rect.y, rect.w, rect.h)

proc orgBox*(x, y, w, h: int|float32|float) =
  ## Sets the box dimensions of the original element for constraints.
  #box(float x, float y, float w, float h)
  current.orgBox.x = float x
  current.orgBox.y = float y
  current.orgBox.w = float w
  current.orgBox.h = float h

proc rotation*(rotationInDeg: float) =
  ## Sets rotation in degrees.
  current.rotation = rotationInDeg

proc fill*(color: Color) =
  ## Sets background color.
  current.fill = color

proc fill*(color: Color, alpha: float32) =
  ## Sets background color.
  current.fill = color
  current.fill.a = alpha

proc fill*(color: string, alpha: float32 = 1.0) =
  ## Sets background color.
  current.fill = parseHtmlColor(color)
  current.fill.a = alpha

proc transparency*(transparency: float32) =
  ## Sets transparency.
  current.transparency = transparency

proc stroke*(color: Color) =
  ## Sets stroke/border color.
  current.stroke = color

proc stroke*(color: string, alpha = 1.0) =
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
  ## Sets all radius of all 4 corners.
  current.cornerRadius = (a, b, c, d)

proc cornerRadius*(radius: float) =
  ## Sets all radius of all 4 corners.
  cornerRadius(radius, radius, radius, radius)

proc editableText*(editableText: bool) =
  ## Sets the code for this group.
  current.editableText = editableText

proc multiline*(multiline: bool) =
  ## Sets if editable text is multiline (textarea) or single line.
  current.multiline = multiline

proc cursorColor*(color: Color) =
  ## Sets the color of the text cursor.
  current.cursorColor = color

proc cursorColor*(color: string, alpha = 1.0) =
  ## Sets the color of the text cursor.
  current.cursorColor = parseHtmlColor(color)
  current.cursorColor.a = alpha

proc highlightColor*(color: Color) =
  ## Sets the color of text selection.
  current.highlightColor = color

proc highlightColor*(color: string, alpha = 1.0) =
  ## Sets the color of text selection.
  current.highlightColor = parseHtmlColor(color)
  current.highlightColor.a = alpha

proc dropShadow*(blur, x, y: float, color: string, alpha: float) =
  ## Sets drawable, drawable in HTML creates a canvas.
  var c = parseHtmlColor(color)
  c.a = alpha
  current.shadows.add Shadow(kind: DropShadow, blur: blur, x: x, y: y, color: c)

proc innerShadow*(blur, x, y: float, color: string, alpha: float) =
  ## Sets drawable, drawable in HTML creates a canvas.
  var c = parseHtmlColor(color)
  c.a = alpha
  current.shadows.add(Shadow(
    kind: InnerShadow,
    blur: blur,
    x: x,
    y: y,
    color: c
  ))

proc drawable*(drawable: bool) =
  ## Sets drawable, drawable in HTML creates a canvas.
  current.drawable = drawable

proc constraints*(vCon: Contraints, hCon: Contraints) =
  ## Sets vertical or horizontal constraint.
  case vCon
    of cMin: discard
    of cMax:
      let righSpace = parent.orgBox.w - current.box.x
      current.box.x = parent.box.w - righSpace
    of cScale:
      let xScale = parent.box.w / parent.orgBox.w
      current.box.x *= xScale
      current.box.w *= xScale
    of cStretch:
      let xDiff = parent.box.w - parent.orgBox.w
      current.box.w += xDiff
    of cCenter:
      current.box.x = floor((parent.box.w - current.box.w) / 2.0)

  case hCon
    of cMin: discard
    of cMax:
      let bottomSpace = parent.orgBox.h - current.box.y
      current.box.y = parent.box.h - bottomSpace
    of cScale:
      let yScale = parent.box.h / parent.orgBox.h
      current.box.y *= yScale
      current.box.h *= yScale
    of cStretch:
      let yDiff = parent.box.h - parent.orgBox.h
      current.box.h += yDiff
    of cCenter:
      current.box.y = floor((parent.box.h - current.box.h) / 2.0)

  current.screenBox = current.box + parent.screenBox

template binding*(stringVariable: untyped) =
  ## Makes the current object text-editable and binds it to the stringVariable.
  editableText true
  onInput:
    stringVariable = keyboard.input
    refresh()
  characters stringVariable

template override*(name: string, inner: untyped) =
  template `name`(): untyped =
    inner

# Navigation and URL functions
# proc goto*(url: string)
# proc openBrowser*(url: string)

proc parseParams*(): TableRef[string, string] =
  ## Parses the params of the main URL.
  result = newTable[string, string]()
  if window.innerUrl.len > 0:
    for pair in window.innerUrl[1..^1].split("&"):
      let
        arr = pair.split("=")
        key = arr[0]
        val = arr[1]
      result[key] = val
