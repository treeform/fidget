import fidget

proc frameTest1Square_root*() =
  frame "test1Square_root": # 1:2
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 1:3
      box 100, 100, 300, 300
      fill "#65F8DE"

proc frameTest2StretchySquare_root*() =
  frame "test2StretchySquare_root": # 1:4
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 1:5
      box 100, 100, parent.box.w - 200, parent.box.h - 200 # TOP_BOTTOM LEFT_RIGHT
      fill "#65F8B2"

proc frameTest3CenterSquare_root*() =
  frame "test3CenterSquare_root": # 1:6
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 1:7
      box parent.box.w/2 - 150, parent.box.h/2 - 150, 300, 300 # CENTER CENTER
      fill "#68F865"

proc frameTest4MultiSquare_root*() =
  frame "test4MultiSquare_root": # 1:9
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 1:10
      box 100, 100, parent.box.w - 200, parent.box.h - 200 # TOP_BOTTOM LEFT_RIGHT
      fill "#65F8DE"

    rectangle "Rectangle": # 1:11
      box 200, 200, parent.box.w - 400, parent.box.h - 400 # TOP_BOTTOM LEFT_RIGHT
      fill "#65BAF8"

    rectangle "Rectangle 2": # 1:12
      box 75, 75, 50, 50
      fill "#F88865"

    rectangle "Rectangle 2.1": # 1:13
      box parent.box.w - 125, 75, 50, 50 # TOP RIGHT
      fill "#F88865"

    rectangle "Rectangle 2.2": # 1:14
      box parent.box.w - 125, parent.box.h - 125, 50, 50 # BOTTOM RIGHT
      fill "#F88865"

    rectangle "Rectangle 2.3": # 1:15
      box 75, parent.box.h - 125, 50, 50 # BOTTOM LEFT
      fill "#F88865"

proc frameTest5DoubleStretch_root*() =
  frame "test5DoubleStretch_root": # 1:16
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle 2": # 1:19
      box 100, 100, 50, parent.box.h - 300 # TOP_BOTTOM LEFT
      fill "#F88865"

    rectangle "Rectangle 2.1": # 1:20
      box 200, 100, parent.box.w - 300, 50 # TOP LEFT_RIGHT
      fill "#F88865"

    rectangle "Rectangle 2.2": # 1:21
      box parent.box.w - 144, 200, 44, parent.box.h - 300 # TOP_BOTTOM RIGHT
      fill "#F88865"

    rectangle "Rectangle 2.3": # 1:22
      box 100, parent.box.h - 150, parent.box.w - 300, 50 # BOTTOM LEFT_RIGHT
      fill "#F88865"

    rectangle "Rectangle 3": # 1:23
      box 0, 0, 100, 100
      fill "#ECECEC"

    rectangle "Rectangle 3.1": # 1:24
      box 0, parent.box.h - 100, 100, 100 # BOTTOM LEFT
      fill "#ECECEC"

    rectangle "Rectangle 3.2": # 1:25
      box parent.box.w - 95, parent.box.h - 100, 100, 100 # BOTTOM RIGHT
      fill "#ECECEC"

    rectangle "Rectangle 3.3": # 1:26
      box parent.box.w - 100, 0, 100, 100 # TOP RIGHT
      fill "#ECECEC"

proc frameTest6TextBasic_root*() =
  frame "test6TextBasic_root": # 8:2
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 8:6
      box 108, 64, 283, 86
      fill "#F2F2F2"

    rectangle "Rectangle 2": # 8:7
      box 108, 134, 283, 16
      fill "#E3E3E3"

    rectangle "Rectangle 2.1": # 8:8
      box 108, 64, 283, 18
      fill "#E3E3E3"

    text "Test Text": # 8:5
      box 108, 64, 283, 86
      fill "#000000"
      font "Helvetica Neue", 72.0, 400.0, 81, hLeft, vTop
      characters "Test Text"

    rectangle "Rectangle": # 8:9
      box 108, 173, 197, 60
      fill "#F2F2F2"

    rectangle "Rectangle 2.2": # 8:10
      box 108, 221, 197, 12
      fill "#E3E3E3"

    rectangle "Rectangle 2.3": # 8:11
      box 108, 173, 197, 12
      fill "#E3E3E3"

    text "Test Text": # 8:12
      box 108, 173, 197, 60
      fill "#000000"
      font "Helvetica Neue", 50.0, 400.0, 55, hLeft, vTop
      characters "Test Text"

    rectangle "Rectangle": # 8:25
      box 108, 256, 79, 24
      fill "#F2F2F2"

    rectangle "Rectangle 2.4": # 8:26
      box 108, 275, 79, 5
      fill "#E3E3E3"

    rectangle "Rectangle 2.5": # 8:27
      box 108, 256, 79, 4
      fill "#E3E3E3"

    text "Test Text": # 8:28
      box 108, 256, 79, 24
      fill "#000000"
      font "Helvetica Neue", 20.0, 400.0, 20, hLeft, vTop
      characters "Test Text"

proc frameTest7TextAlign_root*() =
  frame "test7TextAlign_root": # 8:29
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 8:42
      box 100, 100, 300, 300
      fill "#F2F2F2"

    text "right top": # 8:43
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hLeft, vTop
      characters "right top"

    text "center top": # 8:45
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hCenter, vTop
      characters "center top"

    text "left top": # 8:44
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hRight, vTop
      characters "left top"

    text "right center": # 8:46
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hLeft, vCenter
      characters "right center"

    text "center": # 8:47
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hCenter, vCenter
      characters "center"

    text "left center": # 8:48
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hRight, vCenter
      characters "left center"

    text "right bottom": # 8:49
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hLeft, vBottom
      characters "right bottom"

    text "center bottom": # 8:50
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hCenter, vBottom
      characters "center bottom"

    text "left bottom": # 8:51
      box 100, 100, 300, 300
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hRight, vBottom
      characters "left bottom"

proc frameTest8TextInput_root*() =
  frame "test8TextInput_root": # 8:52
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 8:53
      box 100, 190, 300, 60
      fill "#F2F2F2"

    text "enter your name:": # 8:58
      box 100, 171, 114, 19
      fill "#000000"
      font "Helvetica Neue", 14.0, 400.0, 13, hLeft, vTop
      characters "enter your name:"

    text "Name": # 8:63
      box 116, 190, 274, 60
      fill "#000000"
      font "Helvetica Neue", 28.0, 400.0, 29, hLeft, vCenter
      characters "Name"

    rectangle "Rectangle 2": # 8:64
      box 220, 60, 60, 60
      fill "#F88865"

proc frameTest10Rotations_root*() =
  frame "test10Rotations_root": # 9:8
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    rectangle "Rectangle": # 9:13
      rotation 45.00000098057549
      box 8, 291, 200, 200
      fill "#C4C4C4", 0.450

    rectangle "Rectangle": # 9:14
      rotation 15.00000300355992
      box 98, 201, 200, 200
      fill "#C4C4C4", 0.150

    rectangle "Rectangle": # 9:15
      rotation 30.00000178116811
      box 50, 250, 200, 200
      fill "#C4C4C4", 0.300

proc frameTest9Images_root*() =
  frame "test9Images_root": # 8:65
    box 0, 0, root.box.w, root.box.h # ROOT ROOT
    fill color(1.000, 1.000, 1.000, 1.000)

    component "wrapper": # 9:7
      box parent.box.w/2 - 400, 0, 800, 1217 # TOP CENTER

      rectangle "testBg": # 9:0
        box parent.box.w/2 - 400, 0, 800, 1217 # TOP CENTER
        image "testBg"

      text "All that is gold does not glitter, Not all those who wander are lost; The old that is strong does not wither, Deep roots are not reached by the frost. From the ashes, a fire shall be woken, A light from the shadows shall spring; Renewed shall be blade that was broken, The crownless again shall be king.": # 9:1
        box parent.box.w/2 - 185, 224, 369, 262 # TOP CENTER
        fill "#000000", 0.700
        font "Helvetica Neue", 20.0, 400.0, 20, hCenter, vCenter
        characters "All that is gold does not glitter,\nNot all those who wander are lost;\nThe old that is strong does not wither,\nDeep roots are not reached by the frost.\nFrom the ashes, a fire shall be woken,\nA light from the shadows shall spring;\nRenewed shall be blade that was broken,\nThe crownless again shall be king."

      group "testLogo": # 9:6
        box 341, 52, 117, 117
        image "testLogo"
