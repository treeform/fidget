import fidget

import print
import random
import vmath


var bars = newSeq[int](10)
for i, bar in bars:
  bars[i] = rand(40)


proc drawMain() =

  window.title = "Hovers Example"

  popupActive = true

  let h = bars.len * 60 + 20
  frame "main":
    box 0, 0, int root.box.w, max(int root.box.h, h)

    group "center":
      box 100, 100, 100, 100
      fill "#0000FF"

      onHover:
        fill "#FF0000"

    inPopup = true
    group "center":
      box 150, 150, 100, 100
      fill "#00FF00"

      onHover:
        fill "#FF0000"
    inPopup = false

startFidget(drawMain)
