## Test the mouse cursor changing when you hover over an element.

import fidget

proc drawMain() =
  rectangle "example":
    box 100, 100, 100, 100
    fill "#FF0000"
    onHover:
      fill "#00FF00"
      mouse.cursorStyle = Pointer

startFidget(drawMain, w = 400, h = 400)
