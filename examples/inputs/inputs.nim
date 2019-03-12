import ../../src/fidget

import print
import random
import math


var
  textValue: string
  beEdit = false

drawMain = proc() =

  window.title = "Inputs Example"

  frame "main":
    box 100, 100, 500, 30
    rectangle "#F7F7F9"

    text "input":
      box 4, 5, 500, 30
      fill "#000000"
      font "Helvetica Neue", 16.0, 400.0, 15, -1, -1
      if beEdit:
        placeholder "[enabled, type here]"
        editableText true
        binding textValue
      else:
        characters "[please enabled]"

  group "button":
    box 100, 20, 160, 30
    rectangle "#46D15F"
    text "text":
      box 10, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"
      font "Helvetica Neue", 16.0, 400.0, 15, -1, 0
      characters "switch to input:" & $beEdit

    onHover:
      mouse.cursorStyle = Pointer

    onClick:
      beEdit = not beEdit

startFidget()
