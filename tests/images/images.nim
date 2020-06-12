import fidget

setTitle("Images")

# Photo from: https://unsplash.com/photos/64ldgzW158M
# by Kyle Mackie @macrz

proc drawMain() =
  frame "images":
    box 0, 0, 400, 400
    fill "#ffffff"
    group "img1":
      box 260, 260, 100, 100
      image "img1.png"
    group "img2":
      box 260, 150, 100, 100
      image "img2.png"
    group "img3":
      box 260, 40, 100, 100
      image "img3.png"
    group "img4":
      box 150, 260, 100, 100
      image "img4.png"
    group "img5":
      box 150, 150, 100, 100
      image "img5.png"
    group "img6":
      box 150, 40, 100, 100
      image "img6.png"
    group "img7":
      box 40, 260, 100, 100
      image "img7.png"
    group "img8":
      box 40, 150, 100, 100
      image "img8.png"
    group "img9":
      box 40, 40, 100, 100
      image "img9.png"

startFidget(drawMain, w = 400, h = 400)
