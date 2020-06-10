import fidget, math, random

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

    text "singleLineBox":
      box 300, 0, 400, 40
      fill "#000000"
      textAlign hLeft, vTop
      binding singleLineValue
      onFocus:
        echo "onFocus singleLineBox"
      onUnFocus:
        echo "onUnFocus singleLineBox"
    text "singleLineBoxPlaceHolder":
      box 300, 0, 400, 40
      fill "#888888"
      textAlign hLeft, vTop
      selectable false
      if singleLineValue == "":
        characters "This is an single line box."
      else:
        characters ""
      onFocus:
        echo "onFocus ", current.id
      onUnFocus:
        echo "onUnFocus ", current.id
    group "bg2":
      box 300, 0, 400, 40
      fill "#F8F8F8"

    text "multiLineBox":
      box 300, 60, 400, 100
      fill "#000000"
      textAlign hLeft, vTop
      multiline true
      #placeholder "This is a text area"
      binding multiLineValue
      onFocus:
        echo "onFocus multiLineBox"
      onUnFocus:
        echo "onUnFocus multiLineBox"
    text "multiLineBoxPlaceHolder":
      box 300, 60, 400, 100
      fill "#888888"
      textAlign hLeft, vTop
      selectable false
      if multiLineValue == "":
        characters "This is an multi line box."
      else:
        characters ""
      onFocus:
        echo "onFocus ", current.id
      onUnFocus:
        echo "onUnFocus ", current.id
    group "bg3":
      box 300, 60, 400, 100
      fill "#F8F8F8"

    text "singleLineOut":
      box 300, 300, 400, 40
      fill "#000000"
      textAlign hLeft, vTop
      characters singleLineValue
    group "bg4":
      box 300, 300, 400, 40
      fill "#F8E8E8"

    text "multiLineOut":
      box 300, 360, 400, 100
      fill "#000000"
      textAlign hLeft, vTop
      multiline true
      characters multiLineValue
    group "bg5":
      box 300, 360, 400, 100
      fill "#F8E8E8"

    text "inputFocusIdPath":
      box 300, 480, 400, 40
      fill "#000000"
      textAlign hLeft, vTop
      if keyboard.focusNode != nil:
        characters keyboard.focusNode.id
      else:
        characters "nil"
    group "bg6":
      box 300, 480, 400, 40
      fill "#F8E8E8"

    text "prevInputFocusIdPath":
      box 300, 560, 400, 40
      fill "#000000"
      textAlign hLeft, vTop
      if keyboard.onUnFocusNode != nil:
        characters keyboard.onUnFocusNode.id
      else:
        characters "nil"
    group "bg7":
      box 300, 560, 400, 40
      fill "#F8E8E8"

    text "button1":
      box 300, 620, 100, 20
      fill "#000000"
      textAlign hLeft, vTop
      multiline true
      characters "Press me"
    group "bg8":
      box 300, 620, 100, 20
      fill "#F8E8E8"
      onHover:
        fill "#FF0000"
      onClick:
        echo "pressed!"

    group "bg1":
      box 0, 0, 200, 500
      fill "#F8F8F8"
      var y: int
      for button in Button:
        if buttonDown[button]:
          text "text-" & $button:
            box 10, y*20, 150, 20
            fill "#000000"
            echo $button
            characters $button

          group "group-" & $button:
            box 150, y*20, 20, 20
            fill "#FF0000"

          inc y



loadFont("IBM Plex Sans Regular", "../../examples/data/IBMPlexSans-Regular.ttf")

startFidget(drawMain)
