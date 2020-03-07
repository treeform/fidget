import ../../src/fidget

import print
import random
import math

var bars = newSeq[int](1000)
for i, bar in bars:
  bars[i] = rand(40)

when defined(js):
  loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.ttf")
else:
  loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.svg")

drawMain = proc() =

  window.title = "Fidget Fonts Example"

  font "IBM Plex Sans Regular", 12, 200, 16, -1, -1

  let h = bars.len * 60 + 20
  frame "main":
    box 0, 0, int root.box.w, max(int root.box.h, h)
    rectangle "#F7F7F9"

    text "t":
      box 10, 10, 600, 50
      fill "#46D15F"
      fontSize 50
      characters "Font Features"

    group "box":
      box 100, 100, 300, 300
      fill "#AEB5C0"

      text "tl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign -1, -1
        characters "top left"

      text "tr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 1, -1
        characters "top right"

      text "tm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 0, -1
        characters "top middle"

      text "cl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign -1, 0
        characters "center left"

      text "cr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 1, 0
        characters "center right"

      text "cm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 0, 0
        characters "center middle"

      text "bl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign -1, 1
        characters "bottom left"

      text "br":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 1, 1
        characters "bottom right"

      text "bm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 0, 1
        characters "bottom middle"

    group "box2":
      box 500, 100, 300, 300
      fill "#AEB5C0"
      fontSize 40

      text "tl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign -1, -1
        characters "TL"

      text "tr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 1, -1
        characters "TR"

      text "tm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 0, -1
        characters "TM"

      text "cl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign -1, 0
        characters "CL"

      text "cr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 1, 0
        characters "CR"

      text "cm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 0, 0
        characters "CM"

      text "bl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign -1, 1
        characters "BL"

      text "br":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 1, 1
        characters "BR"

      text "bm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign 0, 1
        characters "BM"

startFidget()
