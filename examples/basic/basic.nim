import ../../src/fidget
import print
import vmath

when not defined(js):
  import typography, tables
  fonts["IBM Plex Sans Regular"] = readFontSvg("data/IBMPlexSans-Regular.svg")
  fonts["IBM Plex Sans Bold"] = readFontSvg("data/IBMPlexSans-Bold.svg")

var
  textInputVar = ""
  checkBoxValue: bool
  radioBoxValue: bool

drawMain = proc() =
  window.title = "Fidget Example"
  component "iceUI":
    box 0, 0, 530, 185
    constraints cMin, cMin
    rectangle "bg":
      box 0, 0, 530, 185
      constraints cMin, cMin
      fill "#ffffff"
      cornerRadius 0
      strokeWeight 1
    group "progress":
      box 260, 149, 250, 12
      rectangle "bg":
        box 0, 0, 250, 12
        constraints cMin, cMin
        fill "#ffffff"
        stroke "#70bdcf"
        cornerRadius 5
        strokeWeight 1
      rectangle "fill":
        box 2, 2, 189, 8
        constraints cMin, cMin
        fill "#9fe7f8"
        cornerRadius 5

    group "dropdown":
      box 260, 115, 100, 20
      rectangle "bg":
        box 0, 0, 100, 20
        constraints cMin, cMin
        fill "#72bdd0"
        cornerRadius 5
        strokeWeight 1
      instance "arrow":
        box 80, 0, 20, 20
        constraints cMin, cMin
        image "arrow"
      text "text":
        box 0, 0, 80, 20
        constraints cMin, cMin
        fill "#ffffff"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
        characters "Dropdown"

    group "checkbox":
      box 152, 85, 91, 20
      onClick:
        checkBoxValue = not checkBoxValue
      rectangle "square":
        box 0, 2, 16, 16
        constraints cMin, cMin
        if checkBoxValue:
          fill "#9FE7F8"
        else:
          fill "#ffffff"
        stroke "#70bdcf"
        cornerRadius 5
        strokeWeight 1
      text "text":
        box 21, 0, 70, 20
        constraints cMin, cMin
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
        characters "Checkbox"

    group "radiobox":
      box 152, 115, 91, 20
      onClick:
        radioBoxValue = not radioBoxValue
      rectangle "circle":
        box 0, 2, 16, 16
        constraints cMin, cMin
        if radioBoxValue:
          fill "#9FE7F8"
        else:
          fill "#ffffff"
        stroke "#72bdd0"
        cornerRadius 8
        strokeWeight 1
      text "text":
        box 21, 0, 70, 20
        constraints cMin, cMin
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
        characters "Radiobox"

    group "slider":
      box 260, 90, 250, 10
      rectangle "bg":
        box 0, 3, 250, 4
        constraints cMin, cMin
        fill "#c2e3eb"
        cornerRadius 2
        strokeWeight 1
      rectangle "fill":
        box 0, 3, 91, 4
        constraints cMin, cMin
        fill "#70bdcf"
        cornerRadius 2
        strokeWeight 1
      rectangle "pip":
        box 89, 0, 10, 10
        constraints cMin, cMin
        fill "#72bdd0"
        cornerRadius 5

    group "segmentedContorl":
      box 260, 55, 250, 20
      rectangle "bg":
        box 0, 0, 250, 20
        constraints cMin, cMin
        fill "#72bdd0"
        cornerRadius 5
        strokeWeight 1
      group "Button":
        box 190, 0, 60, 20
        text "text":
          box 0, 0, 60, 20
          constraints cMin, cMin
          fill "#ffffff"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
          characters "button"
      rectangle "seperator":
        box 189, 0, 1, 20
        constraints cMin, cMin
        fill "#ffffff", 0.5
        cornerRadius 0
        strokeWeight 1
      group "Button":
        box 110, 0, 80, 20
        text "text":
          box 0, 0, 80, 20
          constraints cMin, cMin
          fill "#ffffff"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
          characters "segmented"
      rectangle "seperator":
        box 109, 0, 1, 20
        constraints cMin, cMin
        fill "#ffffff", 0.5
        cornerRadius 0
        strokeWeight 1
      group "Button":
        box 80, 0, 30, 20
        text "text":
          box 0, 0, 30, 20
          constraints cMin, cMin
          fill "#ffffff"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
          characters "a"
      rectangle "seperator":
        box 79, 0, 1, 20
        constraints cMin, cMin
        fill "#ffffff", 0.5
        cornerRadius 0
        strokeWeight 1
      group "Button":
        box 50, 0, 30, 20
        text "text":
          box 0, 0, 30, 20
          constraints cMin, cMin
          fill "#ffffff"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
          characters "is"
      rectangle "seperator":
        box 49, 0, 1, 20
        constraints cMin, cMin
        fill "#ffffff", 0.5
        cornerRadius 0
        strokeWeight 1
      group "Button":
        box 0, 0, 49, 20
        rectangle "hover":
          box 0, 0, 49, 20
          constraints cMin, cMin
          fill "#ffffff", 0.5699999928474426
          strokeWeight 1
        text "text":
          box 0, 0, 49, 20
          constraints cMin, cMin
          fill "#46607e"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
          characters "This"
    group "button":
      box 150, 55, 90, 20
      rectangle "bg":
        box 0, 0, 90, 20
        constraints cMin, cMin
        cornerRadius 5
        fill "#72bdd0"
        onHover:
          fill "#5C8F9C"
        onDown:
          fill "#3E656F"
        strokeWeight 1
      text "text":
        box 0, 0, 90, 20
        constraints cMin, cMin
        fill "#ffffff"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, 0, 0
        characters "Button"
    group "input":
      box 260, 15, 250, 30
      rectangle "bg":
        box 0, 0, 250, 30
        constraints cMin, cMin
        fill "#ffffff", 0.3700000047683716
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1
      text "text":
        box 9, 8, 232, 15
        constraints cMin, cMin
        highlightColor "#E5F7FE"
        if textInputVar.len == 0:
          fill "#72bdd0", 0.5
        else:
          fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
        placeholder "Start typing here"
        binding textInputVar
    group "label":
      box 150, 15, 100, 30
      text "Text field:":
        box 0, 0, 100, 30
        constraints cMin, cMin
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
        characters "Text field:"
    group "verticalTabs":
      box 0, 0, 130, 185
      rectangle "bg":
        box 0, 0, 130, 185
        constraints cMin, cBoth
        fill "#e5f7fe"
        cornerRadius 0
        strokeWeight 1
      group "tab":
        box 0, 105, 130, 30
        text "Constraints":
          box 25, 0, 105, 30
          constraints cMin, cMin
          fill "#46607e"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
          characters "Constraints"
      group "tab":
        box 0, 75, 130, 30
        text "text":
          box 25, 0, 105, 30
          constraints cMin, cMin
          fill "#46607e"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
          characters "Image"
      group "tab":
        box 0, 45, 130, 30
        text "text":
          box 25, 0, 105, 30
          constraints cMin, cMin
          fill "#46607e"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
          characters "Text"
      group "tab":
        box 0, 15, 130, 30
        rectangle "hover":
          box 0, 0, 130, 30
          constraints cMin, cMin
          fill "#70bdcf"
          cornerRadius 0
          strokeWeight 1
        text "text":
          box 25, 0, 105, 30
          constraints cMin, cMin
          fill "#ffffff"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
          characters "Contorls"
    group "shadow":
      box 0, 0, 530, 3
      rectangle "l1":
        box 0, 0, 530, 1
        constraints cMin, cMin
        fill "#000000", 0.10000000149011612
        cornerRadius 0
        strokeWeight 1
      rectangle "l2":
        box 0, 1, 530, 1
        constraints cMin, cMin
        fill "#000000", 0.07000000029802322
        cornerRadius 0
        strokeWeight 1
      rectangle "l3":
        box 0, 2, 530, 1
        constraints cMin, cMin
        fill "#000000", 0.029999999329447746
        cornerRadius 0
        strokeWeight 1


when not defined(js):
  windowFrame = vec2(530, 185)

startFidget()
