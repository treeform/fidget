import fidget, random

setTitle("Auto Layout Horizontal")

var widths: seq[int]
for i in 0 ..< 7:
  widths.add(27)

proc drawMain() =
  frame "autoLayoutHorizontal":
    box 0, 0, 400, 400
    fill "#ffffff"
    fill "#ffffff"
    frame "autoFrame":
      box 58, 178, 284, 44
      fill "#cee5fb"
      fill "#cee5fb"
      layout lmHorizontal
      counterAxisSizingMode csAuto
      horizontalPadding 7
      verticalPadding 7
      itemSpacing 10
      rectangle "area1":
        box 247, 7, widths[0], 30
        fill "#90caff"
      rectangle "area2":
        box 207, 7, widths[1], 30
        fill "#379fff"
      rectangle "area3":
        box 167, 7, widths[2], 30
        fill "#007ff4"
      rectangle "area4":
        box 127, 7, widths[3], 30
        fill "#0074df"
      rectangle "area6":
        box 87, 7, widths[4], 30
        fill "#005fb7"
      rectangle "area5":
        box 47, 7, widths[5], 30
        fill "#0062bd"
      rectangle "area7":
        box 7, 7, widths[6], 30
        fill "#00407b"

  for i in 0 ..< 7:
    widths[i] = max(widths[i] + rand(-1 .. 2), 10)

startFidget(drawMain, w = 400, h = 400)
