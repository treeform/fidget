## A bunch of nice looking controls.

import fidget

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")
loadFont("IBM Plex Sans Bold", "IBMPlexSans-Bold.ttf")

var
  textInputVar = ""
  checkBoxValue: bool
  radioBoxValue: bool
  selectedTab = "Controls"
  selectedButton = @["This"]
  pipDrag = false
  pipPos = 89
  progress = 20.0
  dropDownOpen = false

proc basicText() =
  frame "autoLayoutText":
    box 130, 0, root.box.w - 130, 491
    fill "#ffffff"
    layout lmVertical
    counterAxisSizingMode csFixed
    horizontalPadding 30
    verticalPadding 30
    itemSpacing 10
    text "p2":
      box 30, 361, 326, 100
      fill "#000000"
      font "IBM Plex Sans", 14, 400, 20, hLeft, vTop
      characters "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title2":
      box 30, 319, 326, 32
      fill "#000000"
      font "IBM Plex Sans", 20, 400, 32, hLeft, vTop
      characters "Lorem Ipsum"
      textAutoResize tsHeight
      layoutAlign laStretch
    text "imgCaption":
      box 30, 289, 326, 20
      fill "#9c9c9c"
      font "IBM Plex Sans", 14, 400, 20, hCenter, vTop
      characters "Lorem ipsum dolor sit ame"
      textAutoResize tsHeight
      layoutAlign laStretch
    rectangle "imgPlaceholder":
      box 125.5, 182, 135, 97
      fill "#5C8F9C"
      layoutAlign laCenter
    text "p1":
      box 30, 72, 326, 100
      fill "#000000"
      font "IBM Plex Sans", 14, 400, 20, hLeft, vTop
      characters "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title1":
      box 30, 30, 326, 32
      fill "#000000"
      font "IBM Plex Sans", 20, 400, 32, hLeft, vTop
      characters "Lorem Ipsum"
      textAutoResize tsHeight
      layoutAlign laStretch

proc basicControls() =

  group "dropdown":
    box 260, 115, 100, 20
    fill "#72bdd0"
    cornerRadius 5
    strokeWeight 1
    onHover:
      fill "#5C8F9C"
    onClick:
      dropDownOpen = not dropDownOpen
    instance "arrow":
      box 80, 0, 20, 20
      if dropDownOpen:
        rotation -90
      image "arrow.png"
    text "text":
      box 0, 0, 80, 20
      fill "#ffffff"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "Dropdown"

    if dropDownOpen:
      frame "dropDown":
        box 0, 30, 100, 100
        fill "#ffffff"
        cornerRadius 5
        layout lmVertical
        counterAxisSizingMode csAuto
        horizontalPadding 0
        verticalPadding 0
        itemSpacing 0
        clipContent true
        for buttonName in reverse(@["Nim", "UI", "in", "100%", "Nim"]):
          group "button":
            box 0, 80, 100, 20
            layoutAlign laCenter
            fill "#72bdd0"
            onHover:
              fill "#5C8F9C"
            onClick:
              dropDownOpen = false
            text "text":
              box 0, 0, 100, 20
              fill "#ffffff"
              font "IBM Plex Sans", 12, 400, 0, hCenter, vCenter
              characters buttonName

  group "progress":
    box 260, 149, 250, 12
    fill "#ffffff"
    stroke "#70bdcf"
    cornerRadius 5
    strokeWeight 1
    rectangle "fill":
      progress = selectedButton.len / 5 * 100
      box 2, 2, clamp(int((parent.box.w/3.0 - 4) * (progress/100)), 1, parent.box.w.int), 8
      fill "#9fe7f8"
      cornerRadius 5

  group "checkbox":
    box 152, 85, 91, 20
    onClick:
      checkBoxValue = not checkBoxValue
    rectangle "square":
      box 0, 2, 16, 16

      if checkBoxValue:
        fill "#9FE7F8"
      else:
        fill "#ffffff"
      stroke "#70bdcf"
      cornerRadius 5
      strokeWeight 1
    text "text":
      box 21, 0, 70, 20

      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      characters "Checkbox"

  group "radiobox":
    box 152, 115, 91, 20
    onClick:
      radioBoxValue = not radioBoxValue
    rectangle "circle":
      box 0, 2, 16, 16
      if radioBoxValue:
        fill "#9FE7F8"
      else:
        fill "#ffffff"
      stroke "#72bdd0"
      cornerRadius 8
      strokeWeight 1
    text "text":
      box 21, 0, 70, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      characters "Radiobox"

  group "slider":
    box 260, 90, 250, 10
    onClick:
      pipDrag = true
    if pipDrag:
      pipPos = int(mouse.pos.x/3.0 - current.screenBox.x/3.0)
      pipPos = clamp(pipPos, 1, 240)
      pipDrag = buttonDown[MOUSE_LEFT]
    rectangle "pip":
      box pipPos, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, pipPos, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, 250, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  frame "segmentedControl":
    box 260, 55, 250, 20
    fill "#72bdd0"
    cornerRadius 5
    layout lmHorizontal
    counterAxisSizingMode csAuto
    horizontalPadding 0
    verticalPadding 0
    itemSpacing 0
    for buttonName in reverse(@["This", "is", "a", "segmented", "button"]):
      group "Button":
        box 0, 0, buttonName.len * 9 + 10, 20
        layoutAlign laCenter
        if buttonName in selectedButton:
          fill "#ffffff", 0.5
        onHover:
          fill "#5C8F9C"
        onClick:
          if buttonName in selectedButton:
            selectedButton.del(selectedButton.find(buttonName))
          else:
            selectedButton.add(buttonName)
        text "text":
          box 0, 0, buttonName.len * 9 + 10, 20
          fill "#ffffff"
          font "IBM Plex Sans", 12, 400, 0, hCenter, vCenter
          characters buttonName
      rectangle "separator":
        box 0, 0, 1, 20
        fill "#ffffff", 0.5

  group "button":
    box 150, 55, 90, 20
    cornerRadius 5
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "Button"

  group "input":
    box 260, 15, 250, 30
    text "text":
      box 9, 8, 232, 15
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      binding textInputVar
    text "textPlaceholder":
      box 9, 8, 232, 15
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      if textInputVar == "":
        characters "Start typing here"
    rectangle "bg":
      box 0, 0, 250, 30
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "label":
    box 150, 15, 100, 30
    text "Text field:":
      box 0, 0, 100, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      characters "Text field:"

proc basicImage() =
  frame "images":
    box 130, 0, 400, 400
    fill "#ffffff"
    group "img1":
      box 260, 260, 100, 100
      image "img1.png"
    group "img2":
      box 260, 150, 100, 100
      image "img2.png"
    group "img3":
      box 260, 40, 100, 100
      image "img3.png"
    group "img4":
      box 150, 260, 100, 100
      image "img4.png"
    group "img5":
      box 150, 150, 100, 100
      image "img5.png"
    group "img6":
      box 150, 40, 100, 100
      image "img6.png"
    group "img7":
      box 40, 260, 100, 100
      image "img7.png"
    group "img8":
      box 40, 150, 100, 100
      image "img8.png"
    group "img9":
      box 40, 40, 100, 100
      image "img9.png"

proc basicConstraints() =
  frame "constraints":
    # Got to specify orgBox for constraints to work.
    orgBox 0, 0, 400, 400
    # Then grow the normal box.
    box 130, 0, root.box.w - 130, root.box.h
    # Constraints will work on the difference between orgBox and box.
    fill "#ffffff"
    rectangle "Center":
      box 150, 150, 100, 100
      constraints cCenter, cCenter
      fill "#FFFFFF", 0.50
    rectangle "Scale":
      box 100, 100, 200, 200
      constraints cScale, cScale
      fill "#FFFFFF", 0.25
    rectangle "LRTB":
      box 40, 40, 320, 320
      constraints cStretch, cStretch
      fill "#70BDCF"
    rectangle "TR":
      box 360, 20, 20, 20
      constraints cMax, cMin
      fill "#70BDCF"
    rectangle "TL":
      box 20, 20, 20, 20
      constraints cMin, cMin
      fill "#70BDCF"
    rectangle "BR":
      box 360, 360, 20, 20
      constraints cMax, cMax
      fill "#70BDCF"
    rectangle "BL":
      box 20, 360, 20, 20
      constraints cMin, cMax
      fill "#70BDCF"

proc drawMain() =
  setTitle("Fidget Example")

  component "iceUI":
    orgBox 0, 0, 530, 185
    box root.box
    fill "#ffffff"

    group "shadow":
      orgBox 0, 0, 530, 3
      box 0, 0, root.box.w, 3
      rectangle "l1":
        box 0, 0, 530, 1
        constraints cStretch, cMin
        fill "#000000", 0.10
      rectangle "l2":
        box 0, 1, 530, 1
        constraints cStretch, cMin
        fill "#000000", 0.07
      rectangle "l3":
        box 0, 2, 530, 1
        constraints cStretch, cMin
        fill "#000000", 0.03

    frame "verticalTabs":
      box 0, 15, 130, 120
      layout lmVertical
      counterAxisSizingMode csAuto
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 0

      for tabName in ["Constraints", "Image", "Text", "Controls"]:
        group "tab":
          box 0, 0, 130, 30
          layoutAlign laCenter
          onHover:
            fill "#70bdcf", 0.5
          if selectedTab == tabName:
            fill "#70bdcf"
          onClick:
            selectedTab = tabName
          text "text":
            box 25, 0, 105, 30
            if selectedTab == tabName:
              fill "#ffffff"
            else:
              fill "#46607e"
            font "IBM Plex Sans", 12, 400, 12, hLeft, vCenter
            characters tabName

    rectangle "bg":
      box 0, 0, 130, 185
      constraints cMin, cStretch
      fill "#e5f7fe"

    case selectedTab:
      of "Controls":
        basicControls()
      of "Text":
        basicText()
      of "Image":
        basicImage()
      of "Constraints":
        basicConstraints()

startFidget(drawMain, w = 530, h = 300, pixelScale=1.0)
