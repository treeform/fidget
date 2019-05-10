import ../../src/fidget

import print
import random
import math


var
  textValue = """
mov ax, bx # move stuff here
ax
bx
zk
se
mn
mmm mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
q!2
"""

drawMain = proc() =

  window.title = "Pad of Text"

  frame "main":
    box 10, 10, parent.box.w-20, 1000
    font "Helvetica Neue", 20.0, 400.0, 25, -1, -1
    rectangle "#F7F7F9"

    text "input":
      box 0, 0, parent.box.w, 1000
      fill "#000000"
      binding textValue

startFidget()
