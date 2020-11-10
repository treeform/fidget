#import json, jsons, print, tables, chroma, vmath, cairo

import schema, render, print, flippy, strutils, strformat

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
  #if not frame.name.startsWith("rect"): continue
  if frame.name notin ["rect", "round_rect", "rotation", "rotation_pivot", "rotations", "rotation_polygon", "rotation_anti"]: continue
  let image = drawCompleteFrame(frame)
  print "write frame", frame.name
  image.save("frames/" & frame.name & ".png")

  framesHtml.add(&"""<h4>{frame.name}</h4><img src="{frame.name}.png"><img src="masters/{frame.name}.png"><br>""")

  #break

writeFile("frames/index.html", framesHtml)
