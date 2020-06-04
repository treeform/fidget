import chroma, fidget/common, json, macros, strutils, tables, vmath,
    fidget/input, strformat

export chroma, common, input

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
  ## Base template for group, frame, rectangle...

  # Verify we have drawn the parent first since we are drawing a child now
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
        current.idPath.add "."
      current.idPath.add g.id

  # if pathChecker.hasKey(current.idPath):
  #   raise newException(ValueError, &"Duplicate id path `{current.idPath}` found.")
  # else:
  #   pathChecker[current.idPath] = true

  block:
    inner

  if not current.wasDrawn:
    current.draw()
    current.wasDrawn = true

  current.postDrawChildren()

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

template rectangle*(color: string|Color) =
  ## Shorthand for rectangle with fill.
  rectangle "":
    box 0, 0, parent.box.w, parent.box.h
    fill color

proc mouseOverlapLogic*(): bool =
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
  if buttonPress[MOUSE_RIGHT] and mouseOverlapLogic():
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
  ## This is called when key is held down.
  if keyboard.state == Down:
    inner

proc hasKeyboardFocus*(group: Group): bool =
  ## Does a group have keyboard input focus.
  return keyboard.inputFocusIdPath == group.idPath

template onInput*(inner: untyped) =
  ## This is called when key is pressed and this element has focus.
  if not current.bindingSet:
    raise newException(ValueError, "onInput: Binding not set, must be called after.")
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
  if not current.bindingSet:
    raise newException(ValueError, "onFocus: Binding not set, must be called after.")
  if keyboard.inputFocusIdPath == current.idPath and
      keyboard.prevInputFocusIdPath != current.idPath:
    inner

template onUnFocus*(inner: untyped) =
  ## On loosing focus on an input element.
  if not current.bindingSet:
    raise newException(ValueError, "onUnFocus: Binding not set, must be called after.")
  if keyboard.inputFocusIdPath != current.idPath and
      keyboard.prevInputFocusIdPath == current.idPath:
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

proc textAutoResize*(textAutoResize: TextAutoResize) =
  current.textAutoResize = textAutoResize

proc characters*(text: string) =
  ## Adds text to the group.
  if current.text == "":
    current.text = text
  else:
    current.text &= text

proc image*(imageName: string) =
  ## Adds image to the group.
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

proc clipContent*(clipContent: bool) =
  ## Causes the parent to clip the children.
  current.clipContent = clipContent

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
  if current.bindingSet:
    raise newException(ValueError, "Binding already set.")
  current.bindingSet = true

  editableText true
  characters stringVariable
  onClick:
    keyboard.focus(current)
  onClickOutside:
    keyboard.unFocus(current)
  onInput:
    if stringVariable != keyboard.input:
      stringVariable = keyboard.input
      refresh()

template override*(name: string, inner: untyped) =
  template `name`(): untyped =
    inner

proc parseParams*(): Table[string, string] =
  ## Parses the params of the main URL.
  let splitSearch = getUrl().split('?')
  if len(splitSearch) == 1:
    return

  let noHash = splitSearch[1].split('#')[0]
  for pair in noHash[0..^1].split("&"):
    let
      arr = pair.split("=")
      key = arr[0]
      val = arr[1]
    result[key] = val
