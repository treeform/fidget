import ../../src/fidget
import ../../src/fidget/dom2

import print
import random
import math


var bars = newSeq[int](1000)
for i, bar in bars:
  bars[i] = rand(40)


drawMain = proc() =
  let h: int = bars.len * 60 + 20
  frame "main":
    box 0, 0, window.innerWidth, max(window.innerHeight, h)
    rectangle "#F7F7F9"

    group "center":
      box (parent.box.w - 1000) / 2, 0, 1000, float max(window.innerHeight, h)
      rectangle "#FFFFFF"

      for i, bar in bars.mpairs:
        group "bar":
          box 20, 20 + 60 * i, 960, 60

          # if current box is not on screen, don't draw children
          if current.screenBox.overlap(scrollBox):

            rectangle "dec":
              box 0, 0, 40, 40
              fill "#AEB5C0"

              onHover:
                fill "#FF4400"

              onClick:
                dec bar
                if bar < 0: bar = 0

            rectangle "inc":
              box 920, 0, 40, 40
              fill "#AEB5C0"

              onHover:
                fill "#FF4400"

              onClick:
                inc bar
                if bar > 40: bar = 40

            group "bar":
              box 60, 0, 960 - 80*2, 40
              rectangle "#F7F7F9"

              rectangle "barFg":
                box 0, 0, 20*bar, 40
                fill "#46D15F"
