import fidget, math, strformat

var
  fontS = 14.0
  lineH = 14.0

when defined(js):
  loadFont("IBM Plex Sans Regular", "../../examples/data/IBMPlexSans-Regular.ttf")
else:
  loadFont("IBM Plex Sans Regular", "../../examples/data/IBMPlexSans-Regular.svg")

proc drawMain() =

  setTitle("Fidget Fonts Example")

  font "IBM Plex Sans Regular", 12, 200, 16, hLeft, vTop

  let h = 1000
  frame "main":

    # onKeyDown:
    #   if keyboard.keyCode == 39:
    #     fontS += 1.0
    #   if keyboard.keyCode == 37:
    #     fontS -= 1.0

    #   if keyboard.keyCode == 86:
    #     lineH += 1.0
    #   if keyboard.keyCode == 67:
    #     lineH -= 1.0
    #   print fontS, keyboard.keyCode

    box 0, 0, int root.box.w, max(int root.box.h, h)

    text "t":
      box 10, 10, 600, 50
      fill "#46D15F"
      fontSize 50
      characters "Text Align"

    group "box2":
      box 100, 100, 300, 300
      #fill "#AEB5C0"
      fontSize fontS
      lineHeight lineH

      text "tl":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hLeft, vTop
        characters "TL"

      text "tr":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hRight, vTop
        characters "TR"

      text "tc":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hCenter, vTop
        characters "TC"

      text "cl":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hLeft, vCenter
        characters "CL"

      text "cr":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hRight, vCenter
        characters "CR"

      text "c":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hCenter, vCenter
        characters "C"

      text "bl":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hLeft, vBottom
        characters "BL"

      text "br":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hRight, vBottom
        characters "BR"

      text "bc":
        box 0, 0, 300, 300
        fill "#AEB5C0"
        textAlign hCenter, vBottom
        characters "BC"

    group "box2":
      box 100, 500, 10000, 100
      text "bc":
        box 0, 0, 10000, 100
        fontSize fontS
        lineHeight lineH
        fill "#AEB5C0"
        textAlign hLeft, vTop
        characters &"fontSize {fontS} lineHeight {lineH}"

    group "box2":
      box 100, 650, 10000, 100
      text "bc":
        box 0, 0, 10000, 100
        fontSize fontS
        lineHeight lineH
        fill "#AEB5C0"
        textAlign hLeft, vCenter
        characters &"fontSize {fontS} lineHeight {lineH}"

    group "box2":
      box 100, 800, 10000, 100
      text "bc":
        box 0, 0, 10000, 100
        fontSize fontS
        lineHeight lineH
        fill "#AEB5C0"
        textAlign hLeft, vBottom
        characters &"fontSize {fontS} lineHeight {lineH}"

startFidget(drawMain)
