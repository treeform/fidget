import fidget

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
  queryCode: "1+1",
  heightCode: 200,
  heightOuput: 200
)

areas.add Area(
  queryCode: "1*3*32",
  expanded: false,
  heightCode: 200,
  heightOuput: 100
)

areas.add Area(
  queryCode: "one three two",
  label: "text",
  heightCode: 200,
  heightOuput: 300
)

proc drawMain() =
  var totalPageHeight = 120
  for area in areas:
    totalPageHeight += area.heightOuput
    if area.expanded:
      totalPageHeight += area.heightCode

  totalPageHeight = max(totalPageHeight, root.box.h.int)
  let width = 1000

  frame "main":
    box 0, 0, root.box.w, totalPageHeight
    fill "#F7F7F9"

    group "center":
      box (int(parent.box.w) - width) / 2, 0, width, totalPageHeight
      fill "#FFFFFF"

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
              area.expanded = not area.expanded
              mouse.consume()

          rectangle "reRun":
            box width + 10, 0, 16, 16
            fill "#AEB5C0"
            onHover:
              fill "#FF4400"

            onClick:
              mouse.consume()

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
                editingArea = area
                mouse.consume()

              onClickOutside:
                if editingArea == area:
                  editingArea = nil

          group "resultsOutput":
            box 0, innerAtY, width, area.heightOuput
            fill "#FFFFFF"

            innerAtY += area.heightOuput

          atY += innerAtY

startFidget(drawMain)
