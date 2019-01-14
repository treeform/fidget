import macros
import json
import strutils
import chroma
import print

import fidget/uibase
import fidget/backendhtml
export uibase, backendhtml


proc between*(value, min, max: float): bool =
  ## Returns true if value is between min and max or equals to them.
  (value >= min) and (value <= max)


proc inside*(p: Pos, b: Box): bool =
  ## Return true if position is inside the box.
  return p.x > b.x and p.x < b.x + b.w and p.y > b.y and p.y < b.y + b.h


proc overlap*(a, b: Box): bool =
  ## Returns true if box a overlaps box b.
  let
    xOverlap = between(a.x, b.x, b.x + b.w) or between(b.x, a.x, a.x + a.w)
    yOverlap = between(a.y, b.y, b.y + b.h) or between(b.y, a.y, a.y + a.h)
  return xOverlap and yOverlap


proc `+`*(a, b: Box): Box =
  ## Add two boxes together.
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.w = a.w
  result.h = a.h


proc `$`*(g: Group): string =
  ## Format group is a string.
  result = "Group"
  if g.id.len > 0:
    result &= " id:" & $g.id
  result &= " screenBox:" & $g.box


template def(name: string, kind: string, inner: untyped): untyped =
  ## Base temaptle for group, frame, rectange ...
  current = Group()
  current.id = groupName
  current.kind = type
  groupStack.add(current)
  parent = groupStack[^2]

  inner

  current.draw()

  discard groupStack.pop()


template group*(name: string, inner: untyped): untyped =
  ## Starts a new group.
  def("group", name, inner)


template frame*(name: string, inner: untyped): untyped =
  ## Starts a new frame.
  def("frame", name, inner)


template rectangle*(name: string, inner: untyped): untyped =
  ## Starts a new rectangle.
  def("rectangle", name, inner)


template rectangle*(color: string) =
  ## Shorthand for rectange with fill.
  rectangle "":
    box 0, 0, parent.box.w, parent.box.h
    fill color


template onClick*(inner: untyped) =
  ## OnClick event handler.
  if mouse.click:
    if mouse.pos.inside(current.screenBox):
      inner


template onClickOutside*(inner: untyped) =
  ## On click outside event handler. Usefull for deselecting things.
  if mouse.click:
    if not mouse.pos.inside(current.screenBox):
      inner


template onKey*(inner: untyped) =
  ## This is called when key is pressed.
  if keyboard.state == Press:
    inner


template onHover*(inner: untyped) =
  ## Code in the block will run when this box is hovered.
  if mouse.pos.inside(current.screenBox):
    inner


proc id*(id: string) =
  ## Sets ID.
  current.id = id


proc textAlign*(textAlign: TextAlign) =
  ## Aligns text right, left or center.
  current.textAlign = textAlign


proc text*(text: string) =
  ## Adds text to the group.
  if current.text == "":
    current.text = text
  else:
    current.text &= text


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


proc fill*(color: Color) =
  ## Sets background color.
  current.fill = color


proc fill*(color: string) =
  ## Sets background color.
  current.fill = parseHtmlColor(color)


proc textColor*(color: Color) =
  ## Sets background color.
  current.textColor = color


proc textColor*(color: string) =
  ## Sets background color.
  current.textColor = parseHtmlColor(color)


proc zLevel*(zLevel: int) =
  ## Sets zLevel.
  current.zLevel = zLevel


