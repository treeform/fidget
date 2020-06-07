import fidget, random

setTitle("Auto Layout Vertical")

var heights: seq[int]
for i in 0 ..< 7:
  heights.add(27)

proc drawMain() =
  frame "autoLayout":
    box 0, 0, 400, 400
    fill "#ffffff"
    frame "autoFrame":
      box 100, 75, 200, 249
      layout lmVertical
      counterAxisSizingMode csAuto
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 10
      rectangle "area1":
        box 0, 222, 200, heights[0]
        fill "#90caff"
      rectangle "area2":
        box 0, 185, 200, heights[1]
        fill "#379fff"
      rectangle "area3":
        box 0, 148, 200, heights[2]
        fill "#007ff4"
      rectangle "area4":
        box 0, 111, 200, heights[3]
        fill "#0074df"
      rectangle "area5":
        box 0, 74, 200, heights[4]
        fill "#0062bd"
      rectangle "area6":
        box 0, 37, 200, heights[5]
        fill "#005fb7"
      rectangle "area7":
        box 0, 0, 200, heights[6]
        fill "#00407b"

  for i in 0 ..< 7:
    heights[i] = max(heights[i] + random(-1 .. 2), 10)

startFidget(drawMain, w = 400, h = 400)
