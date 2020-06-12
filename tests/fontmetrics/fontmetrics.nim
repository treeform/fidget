
import fidget

loadFont("Jura", "Jura-Regular.ttf")
loadFont("Lato", "Lato-Regular.ttf")
loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")
loadFont("Silver", "silver.ttf")
loadFont("Ubuntu", "Ubuntu.ttf")
loadFont("Changa", "Changa-Bold.ttf")
loadFont("Source Sans Pro", "SourceSansPro-Regular.ttf")

setTitle("Font Metrics")

proc drawMain() =
  frame "font_metrics_master":
    box 0, 0, 1200, 400
    constraints cMin, cMin
    fill "#ffffff"
    fill "#ffffff"
    group "row1":
      box 150, 10, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Jura", 8, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Jura", 12, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Jura", 16, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Jura", 18, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Jura", 32, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Jura", 20, 400, 32, hLeft, vTop
        characters "Figte"
    group "row2":
      box 150, 60, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans", 8, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans", 12, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans", 16, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans", 18, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans", 32, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans", 20, 400, 32, hLeft, vTop
        characters "Figte"
    group "row3":
      box 150, 110, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Silver", 8, 500, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Silver", 12, 500, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Silver", 16, 500, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Silver", 18, 500, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Silver", 32, 500, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Silver", 20, 500, 32, hLeft, vTop
        characters "Figte"
    group "row4":
      box 150, 160, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 8, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 12, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 16, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 18, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 32, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 20, 400, 32, hLeft, vTop
        characters "Figte"
    group "row5":
      box 150, 210, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Lato", 8, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Lato", 12, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Lato", 16, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Lato", 18, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Lato", 32, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Lato", 20, 400, 32, hLeft, vTop
        characters "Figte"
    group "row6":
      box 150, 260, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Source Sans Pro", 8, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Source Sans Pro", 12, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Source Sans Pro", 16, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Source Sans Pro", 18, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Source Sans Pro", 32, 400, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Source Sans Pro", 20, 400, 32, hLeft, vTop
        characters "Figte"
    group "row7":
      box 150, 310, 850, 32
      text "Figte":
        box 0, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Changa", 8, 700, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 150, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Changa", 12, 700, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 300, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Changa", 16, 700, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 450, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Changa", 18, 700, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 750, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Changa", 32, 700, 32, hLeft, vTop
        characters "Figte"
      text "Figte":
        box 600, 0, 100, 32
        constraints cMin, cMin
        fill "#000000"
        font "Changa", 20, 700, 32, hLeft, vTop
        characters "Figte"
    group "key":
      box 10, 10, 135, 332
      text "Changa-Bold.ttf":
        box 0, 300, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "Changa-Bold.ttf"
      text "SourceSansPro-Regular.ttf":
        box 0, 250, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "SourceSansPro-Regular.ttf"
      text "Ubuntu.ttf":
        box 0, 150, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "Ubuntu.ttf"
      text "Lato-Regular.ttf":
        box 0, 200, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "Lato-Regular.ttf"
      text "silver.ttf":
        box 0, 100, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "silver.ttf"
      text "IBMPlexSans-Regular.ttf":
        box 0, 50, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "IBMPlexSans-Regular.ttf"
      text "Jura-Regular.ttf":
        box 0, 0, 135, 32
        constraints cMin, cMin
        fill "#000000"
        font "Ubuntu", 10, 400, 32, hLeft, vTop
        characters "Jura-Regular.ttf"
    group "boxes":
      box 150, 10, 850, 332
      rectangle "Rectangle 94":
        box 0, 300, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 53":
        box 0, 0, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 88":
        box 750, 250, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 82":
        box 750, 200, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 76":
        box 750, 150, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 87":
        box 600, 250, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 81":
        box 600, 200, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 72":
        box 600, 150, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 86":
        box 450, 250, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 80":
        box 450, 200, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 68":
        box 450, 150, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 85":
        box 300, 250, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 79":
        box 300, 200, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 64":
        box 300, 150, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 84":
        box 150, 250, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 78":
        box 150, 200, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 60":
        box 150, 150, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 83":
        box 0, 250, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 77":
        box 0, 200, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 56":
        box 0, 150, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 75":
        box 750, 100, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 71":
        box 600, 100, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 67":
        box 450, 100, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 63":
        box 300, 100, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 59":
        box 150, 100, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 55":
        box 0, 100, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 74":
        box 750, 50, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 70":
        box 600, 50, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 66":
        box 450, 50, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 62":
        box 300, 50, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 58":
        box 150, 50, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 54":
        box 0, 50, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 93":
        box 750, 300, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 73":
        box 750, 0, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 92":
        box 600, 300, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 69":
        box 600, 0, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 91":
        box 450, 300, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 65":
        box 450, 0, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 90":
        box 300, 300, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 61":
        box 300, 0, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 89":
        box 150, 300, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1
      rectangle "Rectangle 57":
        box 150, 0, 100, 32
        constraints cMin, cMin
        stroke "#ff0000"
        strokeWeight 1

startFidget(drawMain, w = 1200, h = 400)
