import fidget, math, print, random, tables

loadFont("Inconsolata", "../data/Inconsolata.svg")

var
  textValue = """
-- sql query
SELECT foo
FROM bar
WHERE a = 234 and b = "nothing"
"""

proc drawMain() =

  window.title = "Pad of Code"

  frame "main":
    box 0, 0, parent.box.w-20, 1000
    font "Inconsolata", 16.0, 400.0, 20, -1, -1
    rectangle "#F7F7F9"

    text "codebox":
      box 0, 0, parent.box.w, 1000
      fill "#000000"
      multiline true
      binding textValue

startFidget(drawMain)
