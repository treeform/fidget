import fidget, figmatests

var screen = 0

proc drawMain() =
  frame "main":
    onKey:
      if keyboard.keyString == " ":
        inc screen
    case screen:
      of 0: frameTest1Square_root()
      of 1: frameTest2StretchySquare_root()
      of 2: frameTest3CenterSquare_root()
      of 3: frameTest4MultiSquare_root()
      of 4: frameTest5DoubleStretch_root()
      of 5: frameTest6TextBasic_root()
      of 6: frameTest7TextAlign_root()
      of 7: frameTest8TextInput_root()
      of 8: frameTest9Images_root()
      of 9: frameTest10Rotations_root()
      else:
        screen = 0
        frameTest1Square_root()

echo "Press space bar to advance to next scene."

startFidget(drawMain)
