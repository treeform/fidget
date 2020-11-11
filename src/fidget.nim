import algorithm, chroma, fidget/common, fidget/input, json, macros, strutils,
    tables, vmath

export chroma, common, input

when defined(js):
  import fidget/htmlbackend
  export htmlbackend
elif defined(nullbackend):
  import fidget/nullbackend
  export nullbackend
else:
  import fidget/openglbackend
  export openglbackend

proc preNode(kind: NodeKind, id: string) =
  # Process the start of the node.

  parent = nodeStack[^1]

  # TODO: maybe a better node differ?

  if parent.nodes.len <= parent.diffIndex:
    # Create Node.
    current = Node()
    current.id = id
    current.uid = newUId()
    parent.nodes.add(current)
  else:
    # Reuse Node.
    current = parent.nodes[parent.diffIndex]
    if current.id == id:
      # Same node.
      discard
    else:
      # Big change.
      current.id = id
    current.resetToDefault()

  current.kind = kind
  current.textStyle = parent.textStyle
  current.cursorColor = parent.cursorColor
  current.highlightColor = parent.highlightColor
  current.transparency = parent.transparency
  nodeStack.add(current)
  inc parent.diffIndex

  current.idPath = ""
  for i, g in nodeStack:
    if i != 0:
      current.idPath.add "."
    if g.id != "":
      current.idPath.add g.id
    else:
      current.idPath.add $g.diffIndex

  current.diffIndex = 0

proc postNode() =
  ## Node drawing is done.

  current.removeExtraChildren()

  # Pop the stack.
  discard nodeStack.pop()
  if nodeStack.len > 1:
    current = nodeStack[^1]
  else:
    current = nil
  if nodeStack.len > 2:
    parent = nodeStack[^2]
  else:
    parent = nil

template node(kind: NodeKind, id: string, inner: untyped): untyped =
  ## Base template for node, frame, rectangle...
  preNode(kind, id)
  inner
  postNode()

template group*(id: string, inner: untyped): untyped =
  ## Starts a new node.
  node(nkGroup, id, inner)

template frame*(id: string, inner: untyped): untyped =
  ## Starts a new frame.
  node(nkFrame, id, inner)

template rectangle*(id: string, inner: untyped): untyped =
  ## Starts a new rectangle.
  node(nkRectangle, id, inner)

template text*(id: string, inner: untyped): untyped =
  ## Starts a new text element.
  node(nkText, id, inner)

template component*(id: string, inner: untyped): untyped =
  ## Starts a new component.
  node(nkComponent, id, inner)

template instance*(id: string, inner: untyped): untyped =
  ## Starts a new instance of a component.
  node(nkInstance, id, inner)

template group*(inner: untyped): untyped =
  ## Starts a new node.
  node(nkGroup, "", inner)

template frame*(inner: untyped): untyped =
  ## Starts a new frame.
  node(nkFrame, "", inner)

template rectangle*(inner: untyped): untyped =
  ## Starts a new rectangle.
  node(nkRectangle, "", inner)

template text*(inner: untyped): untyped =
  ## Starts a new text element.
  node(nkText, "", inner)

template component*(inner: untyped): untyped =
  ## Starts a new component.
  node(nkComponent, "", inner)

template instance*(inner: untyped): untyped =
  ## Starts a new instance of a component.
  node(nkInstance, "", inner)

template rectangle*(color: string|Color) =
  ## Shorthand for rectangle with fill.
  rectangle "":
    box 0, 0, parent.box.w, parent.box.h
    fill color

proc mouseOverlapLogic*(): bool =
  ## Returns true if mouse overlaps the current node.
  (not popupActive or inPopup) and
  current.screenBox.w > 0 and
  current.screenBox.h > 0 and
  mouse.pos.inside(current.screenBox)

template onClick*(inner: untyped) =
  ## On click event handler.
  if mouse.click and mouseOverlapLogic():
    inner

template onClickOutside*(inner: untyped) =
  ## On click outside event handler. Useful for deselecting things.
  if mouse.click and not mouseOverlapLogic():
    inner

template onRightClick*(inner: untyped) =
  ## On right click event handler.
  if buttonPress[MOUSE_RIGHT] and mouseOverlapLogic():
    inner

template onMouseDown*(inner: untyped) =
  ## On when mouse is down and overlapping the element.
  if buttonDown[MOUSE_LEFT] and mouseOverlapLogic():
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

proc hasKeyboardFocus*(node: Node): bool =
  ## Does a node have keyboard input focus.
  return keyboard.focusNode == node

template onInput*(inner: untyped) =
  ## This is called when key is pressed and this element has focus.
  if keyboard.state == Press and current.hasKeyboardFocus():
    inner

template onHover*(inner: untyped) =
  ## Code in the block will run when this box is hovered.
  if mouseOverlapLogic():
    inner

template onHoverOut*(inner: untyped) =
  ## Code in the block will run when hovering outside the box.
  if not mouseOverlapLogic():
    inner

template onDown*(inner: untyped) =
  ## Code in the block will run when this mouse is dragging.
  if mouse.down and mouseOverlapLogic():
    inner

template onFocus*(inner: untyped) =
  ## On focusing an input element.
  if keyboard.onFocusNode == current:
    keyboard.onFocusNode = nil
    inner

template onUnFocus*(inner: untyped) =
  ## On loosing focus on an input element.
  if keyboard.onUnFocusNode == current:
    keyboard.onUnFocusNode = nil
    inner

proc id*(id: string) =
  ## Sets ID.
  current.id = id

proc font*(
  fontFamily: string,
  fontSize, fontWeight, lineHeight: float32,
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

proc fontSize*(fontSize: float32) =
  ## Sets the font size in pixels.
  current.textStyle.fontSize = fontSize

proc fontWeight*(fontWeight: float32) =
  ## Sets the font weight.
  current.textStyle.fontWeight = fontWeight

proc lineHeight*(lineHeight: float32) =
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
  ## Set the text auto resize mode.
  current.textStyle.autoResize = textAutoResize

proc characters*(text: string) =
  ## Sets text.
  if current.text != text:
    current.text = text

proc image*(imageName: string) =
  ## Sets image fill.
  current.imageName = imageName

proc orgBox*(x, y, w, h: int|float32|float32) =
  ## Sets the box dimensions of the original element for constraints.
  current.orgBox.x = float32 x
  current.orgBox.y = float32 y
  current.orgBox.w = float32 w
  current.orgBox.h = float32 h

proc box*(x, y, w, h: float32) =
  ## Sets the box dimensions.
  current.box.x = x
  current.box.y = y
  current.box.w = w
  current.box.h = h

proc box*(
  x: int|float32|float64,
  y: int|float32|float64,
  w: int|float32|float64,
  h: int|float32|float64
) =
  ## Sets the box dimensions with integers
  ## Always set box before orgBox when doing constraints.
  box(float32 x, float32 y, float32 w, float32 h)
  orgBox(float32 x, float32 y, float32 w, float32 h)

proc box*(rect: Rect) =
  ## Sets the box dimensions with integers
  box(rect.x, rect.y, rect.w, rect.h)

proc rotation*(rotationInDeg: float32) =
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

proc strokeWeight*(weight: float32) =
  ## Sets stroke/border weight.
  current.strokeWeight = weight

proc zLevel*(zLevel: int) =
  ## Sets zLevel.
  current.zLevel = zLevel

proc cornerRadius*(a, b, c, d: float32) =
  ## Sets all radius of all 4 corners.
  current.cornerRadius = (a, b, c, d)

proc cornerRadius*(radius: float32) =
  ## Sets all radius of all 4 corners.
  cornerRadius(radius, radius, radius, radius)

proc editableText*(editableText: bool) =
  ## Sets the code for this node.
  current.editableText = editableText

proc multiline*(multiline: bool) =
  ## Sets if editable text is multiline (textarea) or single line.
  current.multiline = multiline

proc clipContent*(clipContent: bool) =
  ## Causes the parent to clip the children.
  current.clipContent = clipContent

proc scrollBars*(scrollBars: bool) =
  ## Causes the parent to clip the children and draw scroll bars.
  current.scrollBars = scrollBars

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

proc dropShadow*(blur, x, y: float32, color: string, alpha: float32) =
  ## Sets drawable, drawable in HTML creates a canvas.
  var c = parseHtmlColor(color)
  c.a = alpha
  current.shadows.add Shadow(kind: DropShadow, blur: blur, x: x, y: y, color: c)

proc innerShadow*(blur, x, y: float32, color: string, alpha: float32) =
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

proc constraints*(vCon: Constraint, hCon: Constraint) =
  ## Sets vertical or horizontal constraint.
  current.constraintsVertical = vCon
  current.constraintsHorizontal = hCon

proc layoutAlign*(mode: LayoutAlign) =
  ## Set the layout alignment mode.
  current.layoutAlign = mode

proc layout*(mode: LayoutMode) =
  ## Set the layout mode.
  current.layoutMode = mode

proc counterAxisSizingMode*(mode: CounterAxisSizingMode) =
  ## Set the counter axis sizing mode.
  current.counterAxisSizingMode = mode

proc horizontalPadding*(v: float32) =
  ## Set the horizontal padding for auto layout.
  current.horizontalPadding = v

proc verticalPadding*(v: float32) =
  ## Set the vertical padding for auto layout.
  current.verticalPadding = v

proc itemSpacing*(v: float32) =
  ## Set the item spacing for auto layout.
  current.itemSpacing = v

proc selectable*(v: bool) =
  ## Set text selectable flag.
  current.selectable = v

template binding*(stringVariable: untyped) =
  ## Makes the current object text-editable and binds it to the stringVariable.
  current.bindingSet = true
  selectable true
  editableText true
  if not current.hasKeyboardFocus():
    characters stringVariable
  if not defined(js):
    onClick:
      keyboard.focus(current)
    onClickOutside:
      keyboard.unFocus(current)
  onInput:
    if stringVariable != keyboard.input:
      stringVariable = keyboard.input

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
