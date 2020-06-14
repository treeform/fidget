import fidget, json

loadFont("IBM Plex Sans Regular", "IBMPlexSans-Regular.ttf")

setTitle("What is my IP?")

proc drawMain() =

  text "text":
    box 0, 0, 300, 100
    font "IBM Plex Sans Regular", 26.0, 400.0, 26, hCenter, vCenter

    # Do an HTTP call.
    var call = httpGet("https://api.ipify.org/?format=json")
    if call.status == Ready:
      fill "#000000"
      characters call.json["ip"].getStr()
    elif call.status == Error:
      fill "#FF0000"
      characters "Error!"
    else:
      fill "#808080"
      characters "Loading..."

startFidget(drawMain, w = 300, h = 100)
