#import json, jsons, print, tables, chroma, vmath, cairo

import chroma, os, schema, render, print, flippy, strutils, strformat

use("https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/")

assert figmaFile.document != nil, "Empty document?"

var framesHtml = """
<style>
img { border: 2px solid gray; }
</style>
"""

for frame in figmaFile.document.children[0].children:
  #if frame.name notin ["shadow", "glow", "shadow_inner", "glow_inner", "text_shadow"]: continue
  #if frame.name notin ["autoLayoutComplex"]: continue
  #if not frame.name.startsWith("frame"): continue
  #if frame.name notin ["rect", "round_rect", "rotation", "rotation_pivot", "rotations", "rotation_polygon", "rotation_anti"]: continue
  let image = drawCompleteFrame(frame)
  print "write frame", frame.name
  image.save("frames/" & frame.name & ".png")

  #if existsFile(&"frames/masters/{frame.name}.png"):
  if true:
    var master = loadImage(&"frames/masters/{frame.name}.png")
    for x in 0 ..< master.width:
      for y in 0 ..< master.height:
        let
          m = master.getRgbaUnsafe(x, y)
          u = image.getRgbaUnsafe(x, y)
        var
          c: ColorRGBA
        let diff = min((abs(m.r.int - u.r.int) + abs(m.g.int - u.g.int) + abs(m.b.int - u.b.int)), 255).uint8
        c.r = diff
        c.g = diff
        c.b = diff
        c.a = 255
        image.putRgbaUnsafe(x, y, c)
    image.save("frames/diffs/" & frame.name & ".png")

  framesHtml.add(&"""<h4>{frame.name}</h4><img src="{frame.name}.png"><img src="masters/{frame.name}.png"><img src="diffs/{frame.name}.png"><br>""")

  #break

writeFile("frames/index.html", framesHtml)
