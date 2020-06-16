import fidget, flippy, chroma, random, tables, hashes
import fidget/opengl/context, fidget/opengl/base

# Generate an image.
var f = newImage(600, 300, 4)

# Display the generated image in a window.
setTitle("Image static viewer.")
proc drawMain() =

  # Generate new static.
  for x in 0 ..< f.width:
    for y in 0 ..< f.height:
      let v = rand(0..255).uint8
      f.putRgba(x, y, rgba(v, v, v, 255))

  # Put or update the static.
  if hash("static") notin ctx.entries:
    ctx.putImage("static", f)
  else:
    ctx.updateImage("static", f)

  ctx.drawImage("static")

startFidget(drawMain, w = f.width, h = f.height, mainLoopMode = RepaintOnFrame)
