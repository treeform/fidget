import fidget

var
  textValue: string
  beEdit = false

loadFont("IBM Plex Sans Regular", "IBMPlexSans-Regular.ttf")

setTitle("Inputs Example")

proc drawMain() =
  frame "main":
    box 100, 100, 500, 30
    fill "#F7F7F9"

    text "input":
      box 0, 0, 500, 30
      fill "#000000"
      font "IBM Plex Sans Regular", 16.0, 400.0, 30, hLeft, vCenter
      if beEdit:
        #placeholder "[Enabled, type here]"
        binding textValue
      else:
        characters "[Please enabled]"

  group "button":
    box 100, 20, 160, 30
    fill "#46D15F"

    text "text":
      box 10, 0, parent.box.w, parent.box.h
      fill "#FFFFFF"
      font "IBM Plex Sans Regular", 16.0, 400.0, 30, hLeft, vCenter
      characters "Switch to input:" & $beEdit

    onHover:
      mouse.cursorStyle = Pointer

    onClick:
      beEdit = not beEdit

      echo "textValue is ", repr(textValue), " s ", keyboard.state

startFidget(drawMain)
