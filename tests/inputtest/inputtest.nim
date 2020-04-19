import fidget, math, random, strutils

var bars = newSeq[int](10)
for i, bar in bars:
  bars[i] = rand(40)

var
  singleLineValue: string # = "Quick brown fox jumped over the lazy dog"
  multiLineValue: string # = "Quick brown fox jumped over the lazy dog"

proc drawMain() =

  setTitle("Input Test")

  let h = 1000
  frame "main":
    font "IBM Plex Sans Regular", 14.0, 400.0, 20, hLeft, vCenter

    box 0, 0, int root.box.w, max(int root.box.h, h)

    group "bg":
      box 0, 0, 200, 500
      fill "#F8F8F8"

    group "bg":
      box 300, 0, 200, 40
      fill "#F8F8F8"
    text "singleLineBox":
      box 300, 0, 200, 40
      fill "#000000"
      textAlign hLeft, vTop
      onFocus:
        echo "onFocus singleLineBox"
      onUnFocus:
        echo "onUnFocus singleLineBox"
      placeholder "This is an input"
      binding singleLineValue

    group "bg":
      box 300, 60, 200, 100
      fill "#F8F8F8"
    text "multiLineBox":
      box 300, 60, 200, 100
      fill "#000000"
      textAlign hLeft, vTop
      onFocus:
        echo "onFocus multiLineBox"
      onUnFocus:
        echo "onUnFocus multiLineBox"
      multiline true
      placeholder "This is a text area"
      binding multiLineValue


    group "bg":
      box 300, 300, 200, 40
      fill "#F8E8E8"
    text "singleLineOut":
      box 300, 300, 200, 40
      fill "#000000"
      textAlign hLeft, vTop
      characters singleLineValue

    group "bg":
      box 300, 360, 200, 100
      fill "#F8E8E8"
    text "multiLineOut":
      box 300, 360, 200, 100
      fill "#000000"
      textAlign hLeft, vTop
      multiline true
      characters multiLineValue

    var y: int
    for button in Button:
      if buttonDown[button]:
        text "text-" & $button:
          box 10, y*20, 150, 20
          fill "#000000"
          editableText false
          characters $button

        group "group-" & $button:
          box 150, y*20, 20, 20

          fill "#FF0000"

        inc y

loadFont("IBM Plex Sans Regular", "../../examples/data/IBMPlexSans-Regular.ttf")

startFidget(drawMain)
