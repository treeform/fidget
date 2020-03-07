import fidget
import print
import vmath

loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.svg")
loadFont("IBM Plex Sans Bold", "../data/IBMPlexSans-Bold.svg")

var
  textInputVar = ""
  checkBoxValue: bool
  radioBoxValue: bool
  selectedTab = "Controls"

proc basicText() =
  frame "basicText":
    box 130, 0, 400, 185
    constraints cMin, cMin
    fill "#ffffff"
    cornerRadius 0
    strokeWeight 1
    rectangle "bg":
      box 0, 0, 400, 185
      constraints cMin, cMin
      fill "#ffffff"
      cornerRadius 0
      strokeWeight 1
    text "∑":
      box 22, 122, 17, 42
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 0
      font "IBM Plex Sans Regular", 32, 200, 0, -1, -1
      characters "∑"
    text "∞":
      box 25, 118, 19, 16
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 0
      font "IBM Plex Sans Regular", 12, 200, 0, -1, -1
      characters "∞"
    group "label":
      box 20, 15, 100, 30
      text "Bold Title":
        box 0, 0, 100, 30
        constraints cMin, cMin
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Bold", 12, 200, 0, -1, 0
        characters "Bold Title"
    group "label":
      box 20, 45, 362, 74
      text "p":
        box 0, 0, 362, 74
        constraints cMin, cMin
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, -1, -1
        lineHeight 16
        characters "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean vestibulum nunc quis velit euismod, a laoreet dolor efficitur. Proin et tincidunt ipsum. Fusce dapibus justo a ante commodo pellentesque. "
    group "label":
      box 157, 151, 225, 19
      text "p":
        box 0, 0, 225, 19
        constraints cMax, cMax
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, 1, -1
        characters "- Velit Euismod"
    text "n=0":
      box 21, 160, 25, 13
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans Regular", 10, 200, 0, -1, -1
      characters "n=0"
    text "x":
      box 40, 130, 12, 29
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans Regular", 22, 200, 0, -1, -1
      characters "x"
    text "n":
      box 50, 125, 8, 18
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans Regular", 14, 200, 0, -1, -1
      characters "n"
    text "=":
      box 65, 135, 10, 21
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans Regular", 16, 200, 0, -1, -1
      characters "="
    text "1":
      box 98, 128, 9, 18
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans Regular", 14, 200, 0, -1, -1
      characters "1"
    text "1 - x":
      box 88, 148, 39, 18
      constraints cMin, cMin
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans Regular", 14, 200, 0, -1, -1
      characters "1 - x"
    rectangle "Rectangle 9":
      box 86, 146, 34, 2
      constraints cMin, cMin
      fill "#46607e"
      cornerRadius 0
      strokeWeight 1

proc basicControls() =
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

proc drawMain() =
  window.title = "Fidget Example"
  component "iceUI":
    orgBox 0, 0, 530, 185
    box root.box
    constraints cMin, cMin
    rectangle "bg":
      box 0, 0, 530, 185
      constraints cMin, cMin
      fill "#ffffff"
      cornerRadius 0
      strokeWeight 1

    group "verticalTabs":
      box 0, 0, 130, 185
      constraints cMin, cStretch
      rectangle "bg":
        box 0, 0, 130, 185
        constraints cMin, cStretch
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
        onClick:
          selectedTab = "Text"
        text "text":
          box 25, 0, 105, 30
          constraints cMin, cMin
          fill "#46607e"
          strokeWeight 1
          font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
          characters "Text"
      group "tab":
        box 0, 15, 130, 30
        onClick:
          selectedTab = "Controls"
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

    case selectedTab:
      of "Controls":
        basicControls()
      of "Text":
        basicText()

    group "shadow":
      box 0, 0, 530, 3
      constraints cStretch, cMin
      rectangle "l1":
        box 0, 0, 530, 1
        constraints cStretch, cMin
        fill "#000000", 0.10000000149011612
        cornerRadius 0
        strokeWeight 1
      rectangle "l2":
        box 0, 1, 530, 1
        constraints cStretch, cMin
        fill "#000000", 0.07000000029802322
        cornerRadius 0
        strokeWeight 1
      rectangle "l3":
        box 0, 2, 530, 1
        constraints cStretch, cMin
        fill "#000000", 0.029999999329447746
        cornerRadius 0
        strokeWeight 1

when not defined(js):
  windowFrame = vec2(530, 185)

startFidget(drawMain)
