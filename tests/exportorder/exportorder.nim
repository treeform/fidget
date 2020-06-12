
import fidget

setTitle("Export Order")

proc drawMain() =
  frame "export_order":
    box 0, 0, 400, 400
    constraints cMin, cMin
    fill "#ffffff"
    rectangle "rect1":
      ## This is the top rectangle
      box 250, 250, 100, 100
      fill "#f9e0d2"
    rectangle "rect2":
      box 200, 200, 100, 100
      fill "#f8c5a8"
    rectangle "rect3":
      box 150, 150, 100, 100
      fill "#ffac7d"
    rectangle "rect4":
      box 100, 100, 100, 100
      fill "#ff8846"
    rectangle "rect5":
      ## This is the bottom rectangle
      box 50, 50, 100, 100
      fill "#ff5b00"

startFidget(drawMain, w = 400, h = 400)
