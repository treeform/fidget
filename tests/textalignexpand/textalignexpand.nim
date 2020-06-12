import fidget

loadFont("Ubuntu", "Ubuntu.ttf")
setTitle("Text Align Expand")

proc drawMain() =
  frame "textAlignExpand":
    box 0, 0, 400, 400
    fill "#ffffff"
    text "Fidget1":
      box 301, 328, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hRight, vBottom
      characters "Fidget"
    text "Fidget2":
      box 301, 184, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hRight, vCenter
      characters "Fidget"
    text "Fidget3":
      box 301, 40, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hRight, vTop
      characters "Fidget"
    text "Fidget4":
      box 171, 328, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hCenter, vBottom
      characters "Fidget"
    text "Fidget5":
      box 171, 184, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hCenter, vCenter
      characters "Fidget"
    text "Fidget6":
      box 171, 40, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hCenter, vTop
      characters "Fidget"
    text "Fidget7":
      box 40, 328, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vBottom
      characters "Fidget"
    text "Fidget8":
      box 40, 184, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vCenter
      characters "Fidget"
    text "Fidget9":
      box 41, 40, 59, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vTop
      characters "Fidget"
    rectangle "Center":
      box 301, 328, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 301, 184, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 301, 40, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 171, 328, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 171, 184, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 171, 40, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 40, 328, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 40, 184, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 40, 40, 59, 32
      fill "#d8fbbd"
    rectangle "Center":
      box 260, 260, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 260, 150, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 260, 40, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 150, 260, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 150, 150, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 150, 40, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 40, 260, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 40, 150, 100, 100
      fill "#f0fce7"
    rectangle "Center":
      box 40, 40, 100, 100
      fill "#f0fce7"

startFidget(drawMain, w = 400, h = 400)
