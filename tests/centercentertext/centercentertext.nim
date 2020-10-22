## Shows a text pad like program.

import fidget

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")

setTitle("cCenter and vCenter text")

proc drawMain() =

  frame "phoneLike":
    box 0, 0, parent.box.w, parent.box.h
    orgBox 0, 0, 375, 667

    fill "#ffffff"

    text "Some Test X":
      box 55, 81, 266, 62
      constraints cCenter, cCenter
      fill "#000000"
      font "IBM Plex Sans", 48, 400, 48, hLeft, vCenter
      characters "Some Test X"
      textAutoResize tsWidthAndHeight

    rectangle "box":
      box 55, 81, 266, 62
      constraints cCenter, cCenter
      fill "#ff7b7b"

startFidget(drawMain, w = 375, h = 667)
