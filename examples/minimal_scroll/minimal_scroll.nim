## This minimal example shows 5 blue squares in a scroll box

import fidget

proc drawMain() =
  frame "main":
    box 0, 0, 620, 140
    frame "scrollBox":
      box 5, 5, 610, 130
      stroke "#000"
      strokeWeight 1
      clipContent true
      scrollable true, true
      fill "#FFF"
      for i in 0 .. 4:
        group "blockA" & $i:
          scrollSpeed (i + 1) * 2 - 6
          box 15 + (float i) * 120, 15, 100, 100
          fill "#2B9FEA"
          stroke "#000"
          strokeWeight 1

startFidget(drawMain, w = 620, h = 140)
