import ../../src/fidget
import ../../src/fidget/dom2

import print
import random
import math


type
  Area = ref object
    title: string
    label: string
    queryCode: string
    expanded: bool
    heightOuput: int
    heightCode: int
    editing: bool

var
  areas = newSeq[Area]()
  editingArea: Area

areas.add Area(
  queryCode: "active unique by day",
  heightCode: 200,
  heightOuput: 200
)

areas.add Area(
  queryCode: "post_submit unique by hour",
  expanded: false,
  heightCode: 200,
  heightOuput: 100
)

areas.add Area(
  queryCode: "comments = comment_submit unique by week",
  label: "comments",
  heightCode: 200,
  heightOuput: 300
)



drawMain = proc() =
  var totalPageHeight = 120
  for area in areas:
    totalPageHeight += area.heightOuput
    if area.expanded:
      totalPageHeight += area.heightCode

  totalPageHeight = max(totalPageHeight, dom2.window.innerHeight)
  let width = 1000

  frame "main":
    box 0, 0, dom2.window.innerWidth, totalPageHeight
    rectangle "#F7F7F9"

    group "center":
      box (int(parent.box.w) - width) / 2, 0, width, totalPageHeight
      rectangle "#FFFFFF"

      var atY = 60

      for i, area in areas.mpairs:
        group "area":

          var height = area.heightOuput
          if area.expanded:
            height += area.heightCode

          box 0, atY, root.box.w, height

          rectangle "codeExpander":
            box -26, 0, 16, 16
            fill "#AEB5C0"

            onHover:
              fill "#FF4400"

            onClick:
              print "click"
              area.expanded = not area.expanded
              print area.expanded
              mouse.use()

          rectangle "reRun":
            box width + 10, 0, 16, 16
            fill "#AEB5C0"
            onHover:
              fill "#FF4400"

            onClick:
              print "rerun"
              mouse.use()

          var innerAtY = 0
          if area.expanded:
            group "codeEditor":
              box 0, 0, width, area.heightCode
              innerAtY += area.heightCode
              rectangle "codeBg":
                box 0, 0, width, area.heightCode
                if editingArea == area:
                  fill "#e0e0f0"
                else:
                  fill "#edeff3"

              group "codeText":
                box 20, 20, width-40, area.heightCode-40
                fill "#000000"
                characters area.queryCode

              onClick:
                print "edit", area.queryCode
                editingArea = area
                mouse.use()

              onClickOutside:
                if editingArea == area:
                  editingArea = nil

              onKey:
                if editingArea == area:
                  if keyboard.keyCode == 13:
                    area.queryCode.add "\n"
                  else:
                    area.queryCode.add keyboard.keyString
                  print area.queryCode
                  keyboard.use()

          group "resultsOutput":
            box 0, innerAtY, width, area.heightOuput
            rectangle "#FFFFFF"

            innerAtY += area.heightOuput

          atY += innerAtY

startFidget()
