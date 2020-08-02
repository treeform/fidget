## This shows how to set window bounds, so that window can't be resized smaller
## or larger by the user.
## Note: setWindowBounds does not work in JS mode.

import fidget, vmath

proc loadMain() =
  setWindowBounds(vec2(200, 200), vec2(300, 300))

proc drawMain() =
  frame "main":
    box 0, 0, 620, 140
    for i in 0 .. 4:
      group "block":
        box 20 + i * 120, 20, 100, 100
        fill "#2B9FEA"

startFidget(draw=drawMain, load=loadMain, w = 300, h = 300)
