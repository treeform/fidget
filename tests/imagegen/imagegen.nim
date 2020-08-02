import chroma, fidget, flippy

# Generate an image - color palette.
var f = newImage(600, 300, 4)
for x in 0 ..< f.width:
  for y in 0 ..< f.height:
    f.putRgba(x, y, hsl(
      x.float/f.width.float*360,
      y.float/f.height.float*100,
      50
    ).color.rgba)
f.save("data/generated.png")

# Display the generated image in a window.
setTitle("Image viewer")
proc drawMain() =
  group "image":
    box 0, 0, f.width, f.height
    image "generated.png"
startFidget(drawMain, w = f.width, h = f.height)
