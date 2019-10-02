import ../../src/fidget

import print
import random
import math

# when not defined(js):
#   import fidget/backendopengl, typography, tables
#   fonts["Ubuntu"] = readFontSVG("Ubuntu.svg")


var bars = newSeq[float](30)
for i, bar in bars:
  bars[i] = rand(1.0)


drawMain = proc() =

  window.title = "Fidget Bars Example"

  print root.box

  let h = bars.len * 60 + 20
  let barW = root.box.w - 100
  frame "main":
    box 0, 0, int root.box.w, max(int root.box.h, h)
    rectangle "#F7F7F9"

    group "center":
      box 50, 0, barW, float max(int root.box.h, h)
      rectangle "#FFFFFF"

      for i, bar in bars.mpairs:
        group "bar":
          box 20, 20 + 60 * i, barW, 60

          # if current box is not on screen, don't draw children
          if current.screenBox.overlap(scrollBox):

            rectangle "dec":
              box 0, 0, 40, 40
              fill "#AEB5C0"

              onHover:
                fill "#FF4400"

              onClick:
                bar -= 0.1
                if bar < 0.0: bar = 0.0

            rectangle "inc":
              box barW-80, 0, 40, 40
              fill "#AEB5C0"

              onHover:
                fill "#FF4400"

              onClick:
                bar += 0.1
                if bar > 1.0: bar = 1.0

            group "bar":
              box 60, 0, barW - 80*2, 40
              rectangle "#F7F7F9"

              rectangle "barFg":
                box 0, 0, (barW - 80*2) * float(bar), 40
                fill "#46D15F"


    # font "Ubuntu", 12, 200, 16, -1, -1

    # text "hiw":
    #   box 0, 0, 300, 300
    #   fill "#FFFFFF"
    #   textAlign -1, -1
    #   characters "Hello World"

startFidget()
