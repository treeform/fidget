import fidget, math, random

var bars = newSeq[int](1000)
for i, bar in bars:
  bars[i] = rand(40)

when defined(js):
  loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.ttf")
else:
  loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.svg")

proc drawMain() =

  window.title = "Fidget Fonts Example"

  font "IBM Plex Sans Regular", 12, 200, 16, hLeft, vTop

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
        textAlign hLeft, vTop
        characters "top left"

      text "tr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hRight, vTop
        characters "top right"

      text "tc":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hCenter, vTop
        characters "top center"

      text "cl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hLeft, vCenter
        characters "center left"

      text "cr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hRight, vCenter
        characters "center right"

      text "cm":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hCenter, vCenter
        characters "center"

      text "bl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hLeft, vBottom
        characters "bottom left"

      text "br":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hRight, vBottom
        characters "bottom right"

      text "bc":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hCenter, vBottom
        characters "bottom center"

    group "box2":
      box 500, 100, 300, 300
      fill "#AEB5C0"
      fontSize 40

      text "tl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hLeft, vTop
        characters "TL"

      text "tr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hRight, vTop
        characters "TR"

      text "tc":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hCenter, vTop
        characters "TC"

      text "cl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hLeft, vCenter
        characters "CL"

      text "cr":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hRight, vCenter
        characters "CR"

      text "c":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hCenter, vCenter
        characters "C"

      text "bl":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hLeft, vBottom
        characters "BL"

      text "br":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hRight, vBottom
        characters "BR"

      text "bc":
        box 0, 0, 300, 300
        fill "#FFFFFF"
        textAlign hCenter, vBottom
        characters "BC"

startFidget(drawMain)
