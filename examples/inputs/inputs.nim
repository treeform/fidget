import ../../src/fidget

import print
import random
import math


var
  textValue: string
  beEdit = false

window.title = "Inputs Example"

drawMain = proc() =

  frame "main":
    box 100, 100, 500, 30
    rectangle "#F7F7F9"

    text "input":
      box 0, 0, 500, 30
      fill "#000000"
      font "Helvetica Neue", 16.0, 400.0, 15, -1, -1
      if beEdit:
        placeholder "[Enabled, type here]"
        binding textValue
      else:
        characters "[Please enabled]"

  group "button":
    box 100, 20, 160, 30
    rectangle "#46D15F"
    text "text":
      box 10, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"
      font "Helvetica Neue", 16.0, 400.0, 15, -1, 0
      characters "Switch to input:" & $beEdit

    onHover:
      mouse.cursorStyle = Pointer

    onClick:
      beEdit = not beEdit

  echo "textValue is ", repr(textValue), " s ", keyboard.state

startFidget()
