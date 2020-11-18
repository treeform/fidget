import chroma, os, schema, render, print, flippy, strutils, strformat, cligen

proc main(r = "", l = 10000) =
  use("https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/")
  assert figmaFile.document != nil, "Empty document?"
  var framesHtml = """
  <style>
  img { border: 2px solid gray; }
  </style>
  """
  var count = 0
  for frame in figmaFile.document.children[0].children:
    if count >= l: continue
    if r != "" and not frame.name.startsWith(r): continue

    echo " *** ", frame.name, " *** "
    let image = drawCompleteFrame(frame)
    image.save("frames/" & frame.name & ".png")

    if existsFile(&"frames/masters/{frame.name}.png"):
      var master = loadImage(&"frames/masters/{frame.name}.png")
      for x in 0 ..< master.width:
        for y in 0 ..< master.height:
          let
            m = master.getRgbaUnsafe(x, y)
            u = image.getRgbaUnsafe(x, y)
          var
            c: ColorRGBA
          let diff = (m.r.int - u.r.int) + (m.g.int - u.g.int) + (m.b.int - u.b.int)
          c.r = abs(m.a.int - u.a.int).clamp(0, 255).uint8
          c.g = (diff/3).clamp(0, 255).uint8
          c.b = (-diff/3).clamp(0, 255).uint8
          c.a = 255
          image.putRgbaUnsafe(x, y, c)
      image.save("frames/diffs/" & frame.name & ".png")
      count += 1
    framesHtml.add(&"""<h4>{frame.name}</h4><img src="{frame.name}.png"><img src="masters/{frame.name}.png"><img src="diffs/{frame.name}.png"><br>""")
  writeFile("frames/index.html", framesHtml)

dispatch(main)
