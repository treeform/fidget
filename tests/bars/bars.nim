import bumpy, fidget, math, random

# Create an array of 30 bars.
var bars = newSeq[float](30)
for i, bar in bars:
  bars[i] = rand(1.0)

proc drawMain() =
  # Set the window title.
  setTitle("Fidget Bars Example")

  # Use simple math to layout things.
  let h = bars.len * 60 + 20
  let barW = root.box.w - 100

  frame "main":
    box 0, 0, int root.box.w, max(int root.box.h, h)
    fill "#F7F7F9"

    group "center":
      box 50, 0, barW, float max(int root.box.h, h)
      fill "#FFFFFF"

      # Draw a list of bars using a simple for loop.
      for i, bar in bars.mpairs:
        group "bar":
          box 20, 20 + 60 * i, barW, 60

          # If current box is not on screen, don't draw children.
          if current.screenBox.overlaps(scrollBox):

            # Draw the decrement button to make the bar go down.
            rectangle "dec":
              box 0, 0, 40, 40
              fill "#AEB5C0"
              onHover:
                fill "#FF4400"
              onClick:
                bar -= 0.1
                if bar < 0.0: bar = 0.0

            # Draw the increment button to make the bar go up.
            rectangle "inc":
              box barW-80, 0, 40, 40
              fill "#AEB5C0"
              onHover:
                fill "#FF4400"
              onClick:
                bar += 0.1
                if bar > 1.0: bar = 1.0

            # Draw the bar itself.
            group "bar":
              box 60, 0, barW - 80*2, 40
              fill "#F7F7F9"
              rectangle "barFg":
                box 0, 0, (barW - 80*2) * float(bar), 40
                fill "#46D15F"

startFidget(drawMain)
