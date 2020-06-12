import fidget, math

loadFont("IBM Plex Sans Regular", "IBMPlexSans-Regular.ttf")


var clip = true

proc drawMain() =

  font "IBM Plex Sans Regular", 12, 200, 16, hLeft, vTop

  frame "main":
    box 0, 0, int root.box.w, root.box.h

    text "noClipped":
      box 100, 80, 100, 20
      fill "#FF0000"
      textAlign hLeft, vTop
      characters "Not clipped"

    group "parent":
      box 100, 100, 100, 100
      fill "#0000FF"

      group "child":
        box 50, 50, 100, 100
        fill "#00FF00"

      text "childText":
        box 50, 50, 100, 100
        fill "#0000FF"
        textAlign hLeft, vTop
        characters "Some text here"

    text "noClipped":
      box 500, 80, 100, 20
      fill "#FF0000"
      textAlign hLeft, vTop
      characters "Clipped " & $clip
      onClick:
        clip = not clip

    group "clippedParent":
      clipContent clip
      box 500, 100, 100, 100
      fill "#0000FF"

      group "clippedChild":
        box 50, 50, 100, 100
        fill "#00FF00"

      text "childText":
        box 50, 50, 100, 100
        fill "#0000FF"
        textAlign hLeft, vTop
        characters "Some text here"

startFidget(drawMain)
