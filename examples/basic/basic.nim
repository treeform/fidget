import ../../src/fidget
import print
import vmath

when not defined(js):
  import typography, tables
  fonts["IBM Plex Sans Regular"] = readFontSvg("basic/assets/IBMPlexSans-Regular.svg")
  fonts["IBM Plex Sans Bold"] = readFontSvg("basic/assets/IBMPlexSans-Bold.svg")

drawMain = proc() =
  window.title = "Fidget Example"
  component "iceUI":
    box 0, 0, 530, 185
    group "input":
      box 260, 15, 253, 30
      rectangle "bg":
        box 0, 0, 250, 30
        constraints cMin, cMin
        fill "#ffffff", 0.3700000047683716
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1
      text "text":
        box 9, 0, 244, 30
        constraints cMin, cMin
        fill "#bdc3c7"
        strokeWeight 1
        font "IBM Plex Sans Regular", 12, 200, 0, -1, 0
        characters "Start typing here"




windowFrame = vec2(530, 185)
startFidget()
