#import json, jsons, print, tables, chroma, vmath, cairo

import schema, render, print, flippy, strutils

use("https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/")

assert figmaFile.document != nil, "Empty document?"

for frame in figmaFile.document.children[0].children:
  #if frame.name notin ["shadow", "glow", "shadow_inner", "glow_inner", "text_shadow"]: continue
  #if frame.name notin ["component_master"]: continue
  #if not frame.name.startsWith("component"): continue
  let image = drawCompleteFrame(frame)
  print "write frame", frame.name
  image.save("frames/" & frame.name & ".png")

  #break
