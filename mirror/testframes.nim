#import json, jsons, print, tables, chroma, vmath, cairo

import schema, render

use("https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/Fidget-Mirror-Test?node-id=0%3A1&viewport=952%2C680%2C1"
)

assert figmaFile.document != nil, "Empty document?"
drawNode(figmaFile.document)

# var
#   xc = 128.0
#   yc = 128.0
#   radius = 100.0
#   angle1 = 45.0  * PI / 180.0  # angles are specified
#   angle2 = 180.0 * PI / 180.0  # in radians

# ctx.setLineWidth(10.0)
# ctx.arc(xc, yc, radius, angle1, angle2)
# ctx.stroke()

# # draw helping lines
# ctx.setSourceRGBA(1.0, 0.2, 0.2, 0.6)
# ctx.setLineWidth(6.0)

# ctx.arc(xc, yc, 10.0, 0, 2*PI)
# ctx.fill()

# ctx.arc(xc, yc, radius, angle1, angle1)
# ctx.lineTo(xc, yc)
# ctx.arc(xc, yc, radius, angle2, angle2)
# ctx.lineTo(xc, yc)
# ctx.stroke()
