import ../../src/fidget
import random
import math

when defined(js):
  loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.ttf")
else:
  loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.svg")

drawMain = proc() =
  # Set the window title.
  window.title = "Fidget Bars Example"

  font "IBM Plex Sans Regular", 16.0, 400.0, 15, -1, -1

  var i = 0
  for y in 0 ..< 100:
    for x in 0 ..< 100:
      if float(x) * 200.0 < root.box.w:
        if x mod 4 == 0:
          group "group-" & $i:
            box x*200, y*40, 200, 40
            fill "#FF0000"
            inc i
        elif x mod 4 == 1:
          text "text-" & $i:
            box x*200, y*40, 200, 40
            fill "#00FF00"
            editableText false
            characters "the text is " & $i
            inc i
        elif x mod 4 == 2:
          text "input-" & $i:
            box x*200, y*40, 200, 40
            fill "#0000FF"
            editableText true
            characters "the input is " & $i
            inc i
        else:
          text "textarea-" & $i:
            box x*200, y*40, 200, 40
            fill "#FF00FF"
            editableText true
            multiline true
            characters "the textarea is " & $i
            inc i

startFidget()
