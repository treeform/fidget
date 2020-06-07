import fidget, random

setTitle("Auto Layout Complex")

proc drawMain() =
  frame "autoLayoutComplex":
    box 0, 0, 400, 400
    fill "#ffffff"
    frame "autoFrame":
      box 0, 0, 300, 400
      fill "#cee5fb"
      layout lmVertical
      counterAxisSizingMode csAuto
      horizontalPadding 10
      verticalPadding 10
      itemSpacing 10
      rectangle "area1":
        box 10, 326, 75, 64
        fill "#90caff"
      rectangle "area2":
        box 35, 277, 101, 39
        fill "#379fff"
        layoutAlign laMax
      rectangle "area3":
        box 10, 203, 126, 64
        fill "#007ff4"
        layoutAlign laStretch
      rectangle "area4":
        box 10, 156, 40, 37
        fill "#0074df"
      rectangle "area6":
        box 34.5, 96, 77, 50
        fill "#005fb7"
        layoutAlign laCenter
      rectangle "area5":
        box 10, 56, 126, 30
        fill "#0062bd"
        layoutAlign laMax
      rectangle "area7":
        box 47.5, 10, 51, 36
        fill "#00407b"
        layoutAlign laCenter

startFidget(drawMain, w = 400, h = 400)
