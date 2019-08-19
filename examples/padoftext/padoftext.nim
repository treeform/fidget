import ../../src/fidget

import print
import random
import math

when not defined(js):
  import fidget/backendopengl, typography, tables
  fonts["Ubuntu"] = readFontSVG("libs/fidget/examples/Ubuntu.svg")


var
  textValue = """
fsdfasdf asdf asdfasdf asdf asdfasdfa sd                                                                                                                        hi there.
"""

drawMain = proc() =

  window.title = "Pad of Text"

  frame "main":
    box 100, 100, parent.box.w - 200, parent.box.h
    font "Ubuntu", 20.0, 400.0, 25, -1, -1
    rectangle "#F7F7F9"

    text "input":
      box 0, 0, parent.box.w, parent.box.h
      fill "#000000"
      multiline true
      binding textValue

startFidget()
