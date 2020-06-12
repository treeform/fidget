import fidget

loadFont("Ubuntu", "Ubuntu.ttf")
setTitle("Inputs and Outputs")

var data = @[
  @["Fidget", "Fidget", "Fidget"],
  @["Fidget", "Fidget", "Fidget"],
  @["Fidget", "Fidget", "Fidget"],
]

proc drawMain() =

  frame "inputsAndOutputs":
    box 0, 0, 800, 400
    fill "#ffffff"
    layout lmHorizontal
    counterAxisSizingMode csAuto
    horizontalPadding 40
    verticalPadding 40
    itemSpacing 80
    group "outputs":
      box 440, 40, 320, 320
      layoutAlign laCenter
      text "output":
        box 220, 220, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hRight, vBottom
        characters data[0][0]
      text "output":
        box 220, 110, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hRight, vCenter
        characters data[1][0]
      text "output":
        box 220, 0, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hRight, vTop
        characters data[2][0]
      text "output":
        box 110, 220, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hCenter, vBottom
        characters data[0][1]
      text "output":
        box 110, 110, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hCenter, vCenter
        characters data[1][1]
      text "output":
        box 110, 0, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hCenter, vTop
        characters data[2][1]
      text "output":
        box 0, 220, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vBottom
        characters data[0][2]
      text "output":
        box 0, 110, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vCenter
        characters data[1][2]
      text "output":
        box 0, 0, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vTop
        characters data[2][2]
      rectangle "bg":
        box 220, 220, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 220, 110, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 220, 0, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 110, 220, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 110, 110, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 110, 0, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 0, 220, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 0, 110, 100, 100
        fill "#bdd3e8"
      rectangle "bg":
        box 0, 0, 100, 100
        fill "#bdd3e8"
    group "inputs":
      box 40, 40, 320, 320
      layoutAlign laCenter
      text "input":
        box 220, 220, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hRight, vBottom
        binding data[0][0]
      text "input":
        box 220, 110, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hRight, vCenter
        binding data[1][0]
      text "input":
        box 220, 0, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hRight, vTop
        binding data[2][0]
      text "input":
        box 110, 220, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hCenter, vBottom
        binding data[0][1]
      text "input":
        box 110, 110, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hCenter, vCenter
        binding data[1][1]
      text "input":
        box 110, 0, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hCenter, vTop
        binding data[2][1]
      text "input":
        box 0, 220, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vBottom
        binding data[0][2]
      text "input":
        box 0, 110, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vCenter
        binding data[1][2]
      text "input":
        box 0, 0, 100, 100
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vTop
        binding data[2][2]
      rectangle "bg":
        box 220, 220, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 220, 110, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 220, 0, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 110, 220, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 110, 110, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 110, 0, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 0, 220, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 0, 110, 100, 100
        fill "#abf1e5"
      rectangle "bg":
        box 0, 0, 100, 100
        fill "#abf1e5"

startFidget(
  drawMain,
  w = 800,
  h = 400,
)
