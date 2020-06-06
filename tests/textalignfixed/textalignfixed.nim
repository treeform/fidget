
import fidget

loadFont("Ubuntu", "data/Ubuntu.ttf")
setTitle("Text Align Fixed")

proc drawMain() =
  frame "textAlignFixed":
    box 0, 0, 400, 400
    fill "#ffffff"
    text "Fidget":
      box 260, 260, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hRight, vBottom
      characters "Fidget"
    text "Fidget":
      box 260, 150, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hRight, vCenter
      characters "Fidget"
    text "Fidget":
      box 260, 40, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hRight, vTop
      characters "Fidget"
    text "Fidget":
      box 150, 260, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hCenter, vBottom
      characters "Fidget"
    text "Fidget":
      box 150, 150, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hCenter, vCenter
      characters "Fidget"
    text "Fidget":
      box 150, 40, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hCenter, vTop
      characters "Fidget"
    text "Fidget":
      box 40, 260, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vBottom
      characters "Fidget"
    text "Fidget":
      box 40, 150, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vCenter
      characters "Fidget"
    text "Fidget":
      box 40, 40, 100, 100
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vTop
      characters "Fidget"
    rectangle "Center":
      box 260, 260, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 260, 150, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 260, 40, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 150, 260, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 150, 150, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 150, 40, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 40, 260, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 40, 150, 100, 100
      fill "#f8c5a8"
    rectangle "Center":
      box 40, 40, 100, 100
      fill "#f8c5a8"

startFidget(drawMain, w = 400, h = 400)
