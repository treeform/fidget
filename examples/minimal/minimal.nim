import fidget

proc drawMain() =
  frame "main":
    box 0, 0, 620, 140
    for i in 0 .. 4:
      group "block":
        box 20+i*120, 20, 100, 100
        fill "#2B9FEA"

when defined(js) or defined(ios) or defined(android):
  startFidget(drawMain)
else:
  startFidget(drawMain, w = 620, h = 140)
