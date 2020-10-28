import fidget

setTitle("Constraints Center Offset")

proc drawMain() =
  frame "constraints":
    orgBox 0, 0, 500, 500
    box 0, 0, parent.box.w, parent.box.h
    fill "#ffffff"
    rectangle "Rectangle 5":
      box 300, 100, 100, 100
      constraints cCenter, cCenter
      fill "#d8fbbd"
    rectangle "Rectangle 4":
      box 300, 300, 100, 100
      constraints cCenter, cCenter
      fill "#ff7b7b"
    rectangle "Rectangle 3":
      box 100, 300, 100, 100
      constraints cCenter, cCenter
      fill "#ffb48a"
    rectangle "Rectangle 2":
      box 100, 100, 100, 100
      constraints cCenter, cCenter
      fill "#abf1e5"

startFidget(drawMain, w = 500, h = 500)
