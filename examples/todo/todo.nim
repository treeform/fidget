import fidget

loadFont("IBM Plex Sans Regular", "../data/IBMPlexSans-Regular.ttf")
loadFont("IBM Plex Sans Bold", "../data/IBMPlexSans-Bold.ttf")

var todoItems: seq[string]
var newItem: string

todoItems = @["clean the house", "get milk"]

proc drawMain() =
  setTitle("Fidget Example")

  frame "todoApp":
    box 0, 0, 473, 798
    constraints cMin, cMin
    fill "#ffffff"
    rectangle "bg":
      box 0, 0, 946, 1596
      constraints cMin, cMin
      fill "#dff6fe"
      cornerRadius 0

    frame "mainFrame":
      box 46, 132, 382, 535
      constraints cMin, cMin
      rectangle "bg":
        box 0, 0, 382, 535
        constraints cMin, cMin
        fill "#f6f6f6"
        stroke "#ffffff"
        cornerRadius 0
        strokeWeight 2
      text "title":
        box 94, 114, 211, 42
        constraints cMin, cMin
        fill "#000000"
        font "IBM Plex Sans Regular", 32, 200, 0, hLeft, vCenter
        characters "FIDGET TO DO"

      var y = 193
      var deleteIndex = -1
      for i, todoItem in todoItems:
        group "todoItem":
          box 30, y, 309, 44
          group "removeButton":
            box 281, 6, 28, 31
            rectangle "bg":
              box 0, 0, 28, 31
              constraints cScale, cScale
              fill "#fd7476"
              cornerRadius 10
            text "minusText":
              box 0, 0, 28, 31
              constraints cScale, cScale
              fill "#ffffff"
              font "IBM Plex Sans Regular", 22, 200, 0, hCenter, vCenter
              characters "-"
            onClick:
              deleteIndex = i

          rectangle "textBg":
            box 0, 0, 261, 44
            constraints cScale, cScale
            fill "#ffffff"
            stroke "#d3d3d3"
            cornerRadius 0
            strokeWeight 2
          text "text":
            box 0, 0, 261, 44
            constraints cScale, cScale
            fill "#000000"
            font "IBM Plex Sans Regular", 16, 200, 0, hCenter, vCenter
            characters todoItem
          y += 75

      if deleteIndex > -1:
        todoItems.delete(deleteIndex)

      group "addItem":
        box 30, y, 309, 44
        group "addButton":
          box 281, 6, 28, 31
          rectangle "Rectangle 25":
            box 0, 0, 28, 31
            constraints cMin, cMin
            fill "#79fd7a"
            cornerRadius 10
          text "+":
            box 0, 0, 28, 31
            constraints cMin, cMin
            fill "#ffffff"
            font "IBM Plex Sans Regular", 22, 200, 0, hCenter, vCenter
            characters "+"

          onClick:
            todoItems.add newItem
            newItem = ""

        rectangle "bg":
          box 0, 0, 261, 44
          constraints cMin, cMin
          fill "#ffffff"
          stroke "#d3d3d3"
          cornerRadius 0
          strokeWeight 2
        text "addText":
          box 0, 0, 261, 44
          constraints cScale, cScale
          fill "#000000", 0.20000000298023224
          font "IBM Plex Sans Regular", 16, 200, 0, hCenter, vCenter
          placeholder "add new item..."
          binding newItem

startFidget(drawMain)
