import fidget

proc drawMain() =
  frame "constraints":
    # Got to specify orgBox for constraints to work.
    orgBox 0, 0, 400, 400
    # Then grow the normal box.
    box root.box
    # Constraints will work on the difference between orgBox and box.
    fill "#ffffff"
    rectangle "Center":
      box 150, 150, 100, 100
      constraints cCenter, cCenter
      fill "#f8c5a8"
    rectangle "Scale":
      box 100, 100, 200, 200
      constraints cScale, cScale
      fill "#ffac7d"
    rectangle "LRTB":
      box 40, 40, 320, 320
      constraints cStretch, cStretch
      fill "#ff8846"
    rectangle "TR":
      box 360, 20, 20, 20
      constraints cMax, cMin
      fill "#ff5b00"
    rectangle "TL":
      box 20, 20, 20, 20
      constraints cMin, cMin
      fill "#ff5b00"
    rectangle "BR":
      box 360, 360, 20, 20
      constraints cMax, cMax
      fill "#ff5b00"
    rectangle "BL":
      box 20, 360, 20, 20
      constraints cMin, cMax
      fill "#ff5b00"

startFidget(drawMain, w = 400, h = 400)
