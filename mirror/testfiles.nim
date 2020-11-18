import chroma, os, schema, render, print, flippy, strutils, strformat, cligen,
    mirror

var files = @[
  (
    "https://www.figma.com/file/livQgJR90bQW8KREsMigrX",
    "Driving - Navigation"
  )
  # (
  #   "https://www.figma.com/file/7leI8PHWQjsj5VwPpF7MsW",
  #   "Grada UI Widgets"
  # ),
  # (
  #   "https://www.figma.com/file/Cto22A31tUso9On23AIpM7",
  #   "Crew Dragon Flight Control UI"
  # ),
  # (
  #   "https://www.figma.com/file/2Xx3HqDhwVy4EuI68PjM2D",
  #   "TeamBuilder"
  # ),
  # (
  #   "https://www.figma.com/file/AzRTd8mpSIKbD8vgVg40RW",
  #   "Uber Light UI Kit"
  # ),
]

var framesHtml = """
<style>
img { border: 2px solid gray; max-height: 500px; max-width: 500px}
</style>
"""
proc main(r = "", l = 10000) =
  var count = 0
  for (url, mainFrame) in files:
    if count >= l: continue
    if r != "" and not mainFrame.startsWith(r): continue

    schema.use(url)
    let frame = figmaFile.document.children[0].findByName(mainFrame)
    let image = drawCompleteFrame(frame)
    image.save("testfiles/" & frame.name & ".png")
    echo " *** ", frame.name, " *** "
    count += 1

    if existsFile(&"testfiles/masters/{frame.name}.png"):
      var master = loadImage(&"testfiles/masters/{frame.name}.png")
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
      image.save("testfiles/diffs/" & frame.name & ".png")
    else:
      echo &"testfiles/masters/{frame.name}.png does not exist!"

    framesHtml.add(&"""<h4>{frame.name}</h4><img src="{frame.name}.png"><img src="masters/{frame.name}.png"><img src="diffs/{frame.name}.png"><br>""")
  writeFile("testfiles/index.html", framesHtml)

dispatch(main)
