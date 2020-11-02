#import json, jsons, print, tables, chroma, vmath, cairo

import schema, render, print, flippy

use("https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/")

assert figmaFile.document != nil, "Empty document?"

for frame in figmaFile.document.children[0].children:
  if frame.name notin ["shadow", "glow", "shadow_inner", "glow_inner", "text_shadow"]: continue
  #if frame.name notin ["text_shadow"]: continue
  drawCompleteFrame(frame)

  print "write frame", frame.name
  ctx.save("frames/" & frame.name & ".png")
