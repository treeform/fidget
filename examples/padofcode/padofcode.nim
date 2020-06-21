## Shows code pad with monospace font.

import fidget

loadFont("Inconsolata", "Inconsolata-Regular.ttf")

setTitle("Pad of Code")

var
  textValue = """
-- sql query
SELECT foo
FROM bar
WHERE a = 234 and b = "nothing"
"""

proc drawMain() =

  frame "main":
    box 0, 0, parent.box.w-20, parent.box.h
    font "Inconsolata", 16.0, 400.0, 20, hLeft, vTop
    fill "#F7F7F9"

    text "codebox":
      box 0, 0, parent.box.w, parent.box.h
      fill "#000000"
      multiline true
      binding textValue

startFidget(drawMain)
