import fidget

loadFont("Ubuntu", "Ubuntu.ttf")
setTitle("Auto Layout Text")

proc drawMain() =
  frame "autoLayoutText":
    box 0, 0, parent.box.w, 491
    fill "#ffffff"
    layout lmVertical
    counterAxisSizingMode csFixed
    horizontalPadding 30
    verticalPadding 30
    itemSpacing 10
    text "p2":
      box 30, 361, 326, 100
      fill "#000000"
      font "Ubuntu", 14, 400, 20, hLeft, vTop
      characters "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title2":
      box 30, 319, 326, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vTop
      characters "Lorem Ipsum"
      textAutoResize tsHeight
      layoutAlign laStretch
    text "imgCaption":
      box 30, 289, 326, 20
      fill "#9c9c9c"
      font "Ubuntu", 14, 400, 20, hCenter, vTop
      characters "Lorem ipsum dolor sit ame"
      textAutoResize tsHeight
      layoutAlign laStretch
    rectangle "imgPlaceholder":
      box 125.5, 182, 135, 97
      fill "#88dc60"
      layoutAlign laCenter
    text "p1":
      box 30, 72, 326, 100
      fill "#000000"
      font "Ubuntu", 14, 400, 20, hLeft, vTop
      characters "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title1":
      box 30, 30, 326, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vTop
      characters "Lorem Ipsum"
      textAutoResize tsHeight
      layoutAlign laStretch

startFidget(drawMain, w = 400, h = 400)
