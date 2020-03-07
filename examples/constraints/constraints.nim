import ../../src/fidget
import vmath

when not defined(js):
  import typography, tables
  fonts["IBM Plex Sans Regular"] = readFontSvg("data/IBMPlexSans-Regular.svg")
  fonts["IBM Plex Sans Bold"] = readFontSvg("data/IBMPlexSans-Bold.svg")

drawMain = proc() =
  frame "ConstraintsFrame":
    orgBox 16, 16, 368, 153
    box root.box
    constraints cMin, cMin
    fill "#70bdcf"
    cornerRadius 0
    strokeWeight 1
    rectangle "LeftTop":
      box 20, 20, 20, 20
      constraints cMin, cMin
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "LeftBottom":
      box 20, 113, 20, 20
      constraints cMin, cMax
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "RightTop":
      box 328, 20, 20, 20
      constraints cMax, cMin
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "RightCenter":
      box 328, 67, 20, 20
      constraints cMax, cCenter
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "RightBottom":
      box 328, 113, 20, 20
      constraints cMax, cMax
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "LeftCenter":
      box 20, 67, 20, 20
      constraints cMin, cCenter
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "CenterTop":
      box 174, 20, 20, 20
      constraints cCenter, cMin
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "CenterBottom":
      box 174, 113, 20, 20
      constraints cCenter, cMax
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "CenterCenter":
      box 174, 67, 20, 20
      constraints cCenter, cCenter
      fill "#ffffff", 0.5
      cornerRadius 0
      strokeWeight 1
    rectangle "ScaleScale":
      box 40, 40, 288, 73
      constraints cScale, cScale
      fill "#ffffff", 0.25
      cornerRadius 0
      strokeWeight 1
    rectangle "BothBoth":
      box 40, 40, 288, 73
      constraints cStretch, cStretch
      fill "#ffffff", 0.25
      cornerRadius 0
      strokeWeight 1

when not defined(js):
  windowFrame = vec2(530, 185)

startFidget()
