import fidget

loadFont("Ubuntu", "data/Ubuntu.ttf")
setTitle("Auto Layout Text")

proc drawMain() =
  frame "pixelScaling":
    box 0, 0, root.box.w, 341
    fill "#ffffff"
    layout lmVertical
    counterAxisSizingMode csFixed
    horizontalPadding 5
    verticalPadding 5
    itemSpacing 10
    text "p2":
      box 5, 276, 190, 60
      fill "#000000"
      font "Ubuntu", 14, 400, 20, hLeft, vTop
      characters "The design stays low resolution though. But it displays all upscale!"
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title2":
      box 5, 234, 190, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vTop
      characters "Lorem Ipsum"
      textAutoResize tsHeight
      layoutAlign laStretch
    text "imgCaption":
      box 5, 204, 190, 20
      fill "#9c9c9c"
      font "Ubuntu", 14, 400, 20, hCenter, vTop
      characters "Lorem ipsum dolor sit ame"
      textAutoResize tsHeight
      layoutAlign laStretch
    rectangle "imgPlaceholder":
      box 32.5, 97, 135, 97
      fill "#88dc60"
      onHover:
        fill "#FF0000"
      layoutAlign laCenter
    text "p1":
      box 5, 47, 190, 40
      fill "#000000"
      font "Ubuntu", 14, 400, 20, hLeft, vTop
      characters "Everything scales to x1, x2, x3 to match pixel game asthenic."
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title1":
      box 5, 5, 190, 32
      fill "#000000"
      font "Ubuntu", 20, 400, 32, hLeft, vTop
      characters "Pixel Scale"
      textAutoResize tsHeight
      layoutAlign laStretch


startFidget(
  drawMain,
  w = 600,
  h = 341*3,
  pixelate = true,
  pixelScale = 3.0
)
