import vmath, base, context

base.start("fidget test")


var ctx = newContext()

base.drawFrame = proc() =
  proj = ortho(0, windowFrame.x, windowFrame.y, 0, -100, 100)

  ctx.drawImage("mainMenu.png", vec2(0, 0))
  ctx.drawImage("fleetA.png", vec2(500, 100))

  ctx.saveTransform()
  #ctx.translate(vec2(500, 500))

  ctx.scale(5.0)

  ctx.drawImage("circle100.png")

  ctx.restoreTransform()

  ctx.flip()


useDepthBuffer(false)

while base.running:
  base.tick()

base.exit()
