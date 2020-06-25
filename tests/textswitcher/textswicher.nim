import fidget

var showText = true
var inputVar = ""

proc drawMain() =

  if showText:
    text "foo1":
      box 100, 100, 100, 100
      fill "#2c3e50"
      binding inputVar
    text "foo2":
      box 100, 100, 100, 100
      fill "#95a5a6"
      if inputVar == "":
        characters "type here"
  else:
    group "foo1":
      box 100, 100, 100, 100
      strokeWeight 2
      stroke "#ecf0f1"
      cornerRadius 10
      fill "#7f8c8d"

  if buttonPress[ESCAPE]:
    showText = not showText
    echo "is text ", showText

startFidget(drawMain)
