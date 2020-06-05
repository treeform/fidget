import fidget

# import hashes

# echo 1.hash
# echo 1.0.hash
# echo "one".hash
# echo (1, 1.0, "one").hash


# https://www.figmafreebies.com/download/grada-free-figma-ui-kit/

loadFont("Montserrat", "data/Montserrat-Regular.ttf")
loadFont("Montserrat Bold", "data/Montserrat-Bold.ttf")
loadFont("Material Icons", "data/MaterialIcons-Regular.ttf")

proc drawMain() =

  setTitle("Fidget: Grada UI")

  frame "Form Elements":
    box 0, 0, 840, 1320
    constraints cMin, cMin
    fill "#30363d"
    fill "#30363d"
    group "Input":
      box 120, 230, 275, 83
      rectangle "Rectangle":
        box 0, 18, 275, 40
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 3
      text "Type here...":
        box 15, 28, 252, 22
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Type here..."
      text "Default Input":
        box 0, 0, 82, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Default Input"
      text "Field Instructions go right here":
        box 0, 65, 252, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vCenter
        characters "Field Instructions go right here"
    group "Input":
      box 120, 1014, 275, 186
      rectangle "Rectangle":
        box 0, 18, 275, 143
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 3
      text "Type here...":
        box 15, 28, 252, 125
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Type here..."
      text "Textarea":
        box 0, 0, 267, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Textarea"
      text "180 Characters Left":
        box 0, 168, 267, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "180 Characters Left"
    group "Deactivated Input":
      box 120, 911, 275, 83
      rectangle "Rectangle":
        box 0, 18, 275, 40
        constraints cMin, cMin
        stroke "#747d88"
        cornerRadius 3
        strokeWeight 1
      text "Type here...":
        box 15, 28, 252, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Type here..."
      text "Deactivated Input":
        box 0, 0, 267, 18
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Deactivated Input"
      text "Field Instructions go right here":
        box 0, 65, 267, 18
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Field Instructions go right here"
    group "Valid Input":
      box 120, 333, 275, 83
      rectangle "Rectangle":
        box 0, 18, 275, 40
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 3
      rectangle "Rectangle":
        box 0, 18, 4, 40
        constraints cMin, cMin
        fill "#6fcf97"
      text "Lorem Ipsum":
        box 15, 28, 252, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Lorem Ipsum"
      text "FOCUS / Hover / Valid Input":
        box 0, 0, 156, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "FOCUS / Hover / Valid Input"
      text "Good job!":
        box 0, 65, 49, 18
        constraints cMin, cMin
        fill "#6fcf97"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Good job!"
    group "Invalid Input":
      box 120, 436, 275, 83
      rectangle "Rectangle":
        box 0, 18, 275, 40
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 3
      rectangle "Rectangle":
        box 0, 18, 4, 40
        constraints cMin, cMin
        fill "#cf6f8a"
      text "Lorem Ipsum":
        box 15, 28, 252, 22
        constraints cMin, cMin
        fill "#f27474"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Lorem Ipsum"
      text "Invalid Input":
        box 0, 0, 77, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Invalid Input"
      text "This input is invalid":
        box 0, 65, 96, 18
        constraints cMin, cMin
        fill "#cf6f8a"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "This input is invalid"
    group "Select":
      box 120, 539, 275, 83
      rectangle "Rectangle":
        box 0, 18, 275, 40
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 3
      text "keyboard_arrow_down":
        box 235, 18, 40, 40
        constraints cMin, cMin
        fill "#747d88"
        font "Material Icons", 24, 400, 0, hCenter, vCenter
        characters "keyboard_arrow_down"
      text "Choose something":
        box 15, 28, 220, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Choose something"
      text "Select Input":
        box 0, 0, 73, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Select Input"
      text "Field Instructions go right here":
        box 0, 65, 155, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Field Instructions go right here"
    group "Select Expanded":
      box 120, 642, 275, 239
      rectangle "Rectangle":
        box 0, 18, 275, 40
        constraints cMin, cMin
        fill "#ffffff"
      text "keyboard_arrow_down":
        box 235, 18, 40, 40
        constraints cMin, cMin
        fill "#747d88"
        font "Material Icons", 24, 400, 0, hCenter, vCenter
        characters "keyboard_arrow_down"
      text "Choose something":
        box 15, 28, 220, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Choose something"
      rectangle "Rectangle":
        box 0, 58, 275, 180
        constraints cMin, cMin
        fill "#ffffff"
        #dropShadow 0, 0, -1, "#ffffff", 0.800000011920929
      text "An option here":
        box 15, 79, 252, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "An option here"
      rectangle "Rectangle 2":
        box 0, 113, 275, 32
        constraints cMin, cMin
        fill "#f27a54"
      text "Another option":
        box 15, 119, 252, 22
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Another option"
      text "Awesome option here":
        box 15, 159, 252, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Awesome option here"
      text "Last option around":
        box 15, 199, 252, 22
        constraints cMin, cMin
        fill "#747d88"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "Last option around"
      text "Select Input Expanded":
        box 0, 0, 134, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Select Input Expanded"
    group "Range Slider":
      box 445, 230, 275, 83
      rectangle "Rectangle":
        box 0, 36, 275, 4
        constraints cMin, cMin
        fill "#747d88"
      rectangle "Rectangle":
        box 49, 36, 176, 4
        constraints cMin, cMin
        fill "#f27a54"
        #dropShadow 10, 0, 5, "#cf6f8a", 0.15000000596046448
      text "Range Slider":
        box 0, 0, 275, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Range Slider"
      group "Group":
        box 20, 28, 54, 55
        rectangle "Rectangle":
          box 25, 0, 4, 20
          constraints cMin, cMin
          fill "#ffffff"
          cornerRadius 3
        text "$20":
          box 0, 37, 54, 18
          constraints cMin, cMin
          fill "#ffffff"
          font "Montserrat", 10, 700, 18, hCenter, vTop
          characters "$20"
      group "Group":
        box 195, 28, 64, 55
        rectangle "Rectangle":
          box 30, 0, 4, 20
          constraints cMin, cMin
          fill "#ffffff"
          cornerRadius 3
        text "$300":
          box 0, 37, 64, 18
          constraints cMin, cMin
          fill "#ffffff"
          font "Montserrat", 10, 700, 18, hCenter, vTop
          characters "$300"
    group "Radio Buttons":
      box 445, 333, 275, 50
      group "Group":
        box 0, 28, 86, 22
        rectangle "Rectangle":
          box 0, 0, 20, 20
          constraints cMin, cMin
          fill "#ffffff"
          cornerRadius 10
        text "I will":
          box 30, 0, 56, 22
          constraints cMin, cMin
          fill "#cbcfd4"
          font "Montserrat", 14, 400, 22, hLeft, vTop
          characters "I will"
      group "Group":
        box 92, 28, 133, 22
        rectangle "Rectangle":
          box 0, 0, 20, 20
          constraints cMin, cMin
          fill "#ffffff"
          cornerRadius 10
        rectangle "Rectangle":
          box 5, 5, 10, 10
          constraints cMin, cMin
          fill "#30363d"
          cornerRadius 10
        text "I won’t":
          box 30, 0, 103, 22
          constraints cMin, cMin
          fill "#cbcfd4"
          font "Montserrat", 14, 400, 22, hLeft, vTop
          characters "I won’t"
      text "Radio Buttons":
        box 0, 0, 275, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Radio Buttons"
    group "Checkbox Buttons":
      box 445, 436, 275, 50
      group "Group":
        box 0, 28, 102, 22
        rectangle "Rectangle":
          box 0, 0, 20, 20
          constraints cMin, cMin
          fill "#ffffff"
          cornerRadius 3
        # vector "Vector":
        #   box 3.782470703125, 9.0606689453125, 11, 8
        #   constraints cMin, cMin
        #   fill "#30363d"
        text "Design":
          box 30, 0, 72, 22
          constraints cMin, cMin
          fill "#cbcfd4"
          font "Montserrat", 14, 400, 22, hLeft, vTop
          characters "Design"
      group "Group":
        box 108, 28, 167, 22
        rectangle "Rectangle":
          box 0, 0, 20, 20
          constraints cMin, cMin
          fill "#ffffff"
          cornerRadius 3
        text "Deverlopment":
          box 30, 0, 137, 22
          constraints cMin, cMin
          fill "#cbcfd4"
          font "Montserrat", 14, 400, 22, hLeft, vTop
          characters "Deverlopment"
      text "Checkbox Buttons":
        box 0, 0, 275, 18
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 10, 400, 18, hLeft, vTop
        characters "Checkbox Buttons"
    group "Primary":
      box 445, 644, 205, 40
      rectangle "Rectangle":
        box 0, 0, 205, 40
        constraints cMin, cMin
        fill "#f27a54"
        cornerRadius 20
      text "Primary Call to Action":
        box 50, 14, 142, 13
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 10, 700, 0, hLeft, vCenter
        characters "Primary Call to Action"
      text "backup":
        box 10, 0, 40, 40
        constraints cMin, cMin
        fill "#ffffff"
        font "Material Icons", 24, 400, 0, hCenter, vCenter
        characters "backup"
    group "Primary":
      box 445, 714, 200, 40
      rectangle "Rectangle":
        box 0, 0, 200, 40
        constraints cMin, cMin
        fill "#f27a54"
        cornerRadius 20
      text "Primary Call to Action":
        box 17, 14, 146, 13
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 10, 700, 0, hCenter, vCenter
        characters "Primary Call to Action"
      text "keyboard_arrow_right":
        box 155, 0, 40, 40
        constraints cMin, cMin
        fill "#ffffff"
        font "Material Icons", 24, 400, 0, hCenter, vCenter
        characters "keyboard_arrow_right"
    group "Primary":
      box 445, 914, 200, 40
      rectangle "Rectangle":
        box 0, 0, 200, 40
        constraints cMin, cMin
        stroke "#ffffff"
        cornerRadius 20
        strokeWeight 1
      text "Primary Call to Action":
        box 4, 14, 170, 13
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 10, 700, 0, hCenter, vCenter
        characters "Primary Call to Action"
      text "keyboard_arrow_right":
        box 155, 0, 40, 40
        constraints cMin, cMin
        fill "#ffffff"
        font "Material Icons", 24, 400, 0, hCenter, vCenter
        characters "keyboard_arrow_right"
    group "Group":
      box 445, 784, 151, 30
      rectangle "Rectangle":
        box 0, 0, 151, 30
        constraints cMin, cMin
        fill "#f27a54"
        cornerRadius 20
      text "Small Call to Action":
        box 12, 9, 130, 13
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 10, 700, 0, hLeft, vCenter
        characters "Small Call to Action"
    group "Group":
      box 445, 984, 151, 30
      rectangle "Rectangle":
        box 0, 0, 151, 30
        constraints cMin, cMin
        stroke "#ffffff"
        cornerRadius 20
        strokeWeight 1
      text "Small Call to Action":
        box 0, 9, 151, 13
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 10, 700, 0, hCenter, vCenter
        characters "Small Call to Action"
    group "Secondary":
      box 445, 844, 222, 40
      rectangle "Rectangle":
        box 0, 0, 222, 40
        constraints cMin, cMin
        stroke "#ffffff"
        cornerRadius 20
        strokeWeight 1
      text "Secondary Call to Action":
        box 50, 14, 165, 13
        constraints cMin, cMin
        fill "#ffffff"
        font "Montserrat", 10, 700, 0, hLeft, vCenter
        characters "Secondary Call to Action"
      text "assessment":
        box 10, 0, 40, 40
        constraints cMin, cMin
        fill "#ffffff"
        font "Material Icons", 24, 400, 0, hCenter, vCenter
        characters "\uE85C"
    group "Group 2":
      box 445, 534, 275, 22
      rectangle "Rectangle":
        box 0, 0, 40, 20
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 10
      rectangle "Rectangle":
        box 20, 0, 20, 20
        constraints cMin, cMin
        fill "#f27a54"
        cornerRadius 10
        dropShadow 10, 0, 5, "#cf6f8a", 0.15000000596046448
      text "This one is turned on":
        box 50, 0, 225, 22
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "This one is turned on"
    group "Group 2.1":
      box 445, 574, 275, 22
      rectangle "Rectangle":
        box 0, 0, 40, 20
        constraints cMin, cMin
        fill "#747d88"
        cornerRadius 10
      rectangle "Rectangle":
        box 0, 0, 20, 20
        constraints cMin, cMin
        fill "#ffffff"
        cornerRadius 10
      text "This one is turned off":
        box 50, 0, 225, 22
        constraints cMin, cMin
        fill "#cbcfd4"
        font "Montserrat", 14, 400, 22, hLeft, vTop
        characters "This one is turned off"
    text "Form Elements":
      box 129, 89, 582, 64
      constraints cMin, cMin
      fill "#f27a54"
      font "Montserrat", 64, 700, 22, hCenter, vCenter
      characters "Form Elements"

startFidget(drawMain, w = 840, h = 1320)
