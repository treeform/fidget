import chroma, fidget, fidget/opengl/base, fidget/opengl/context, fidget/uibase,
    flippy, vmath

var
  loaded: bool
  ctx: Context

var tests: seq[proc()]

tests.add(proc() =
  ctx.beginFrame(vec2(100, 100))
  ctx.translate(vec2(25, 25))
  ctx.fillRect(rect(0, 0, 50, 50), color(0, 1, 0, 1))
  ctx.endFrame()

  takeScreenshot(rect(0, 0, 100, 100)).save("translate.png")
)

tests.add(proc() =
  ctx.beginFrame(vec2(100, 100))
  ctx.scale(2)
  ctx.fillRect(rect(0, 0, 50, 50), color(1, 1, 0, 1))
  ctx.endFrame()

  takeScreenshot(rect(0, 0, 100, 100)).save("scale.png")
)

tests.add(proc() =
  ctx.beginFrame(vec2(100, 100))
  ctx.fillRoundedRect(rect(25, 25, 50, 50), color(1, 0, 0, 1), 5)
  ctx.strokeRoundedRect(rect(10, 10, 80, 80), color(0.5, 0.5, 0.5, 1), 2, 10)
  ctx.endFrame()

  takeScreenshot(rect(0, 0, 100, 100)).save("rounded.png")
)

tests.add(proc() =
  var passed: bool
  try:
    ctx.beginFrame(vec2(100, 100))
    ctx.beginFrame(vec2(100, 100))
  except:
    passed = true
    ctx.endFrame()

  if not passed:
    quit("Calling beginFrame before endFrame didn't fail as expected")
)

tests.add(proc() =
  try:
    ctx.endFrame()
    quit("Calling endFrame before beginFrame didn't fail as expected")
  except:
    discard
)

tests.add(proc() =
  ctx.beginFrame(vec2(100, 100))
  ctx.drawImage("bluestar.png")
  ctx.drawImage("bluestar.png", size = vec2(20, 20))
  ctx.endFrame()

  takeScreenshot(rect(0, 0, 100, 100)).save("image_basic.png")
)

tests.add(proc() =
  ctx.beginFrame(vec2(100, 100))
  ctx.drawImage("bluestar.png", scale = 0.5)
  ctx.endFrame()

  takeScreenshot(rect(0, 0, 100, 100)).save("image_scale.png")
)

tests.add(proc() =
  ctx.beginFrame(vec2(100, 100))
  ctx.drawSprite("bluestar.png", vec2(50, 50))
  ctx.endFrame()

  takeScreenshot(rect(0, 0, 100, 100)).save("sprite_basic.png")
)

tests.add(
  proc() =
  var passed: bool
  try:
    ctx.beginMask()
  except:
    passed = true

  if not passed:
    quit("Calling beginMask before beginFrame didn't fail as expected")
)

tests.add(
  proc() =
  var passed: bool
  try:
    ctx.beginFrame(vec2(100, 100))
    ctx.beginMask()
    ctx.beginMask()
  except:
    passed = true
    ctx.endMask()
    ctx.endFrame()

  if not passed:
    quit("Calling beginMask before endMask didn't fail as expected")
)

tests.add(
  proc() =
  try:
    ctx.endMask()
    quit("Calling endMask before beginMask didn't fail as expected")
  except:
    discard
)

tests.add(
  proc() =
  try:
    ctx.clearMask()
    quit("Calling clearMask before beginFrame didn't fail as expected")
  except:
    discard
)

var i: int
proc draw() =
  if not loaded:
    loaded = true
    ctx = newContext()

  ctx.clearTransform()
  tests[i]()
  inc(i)

  if i == len(tests):
    running = false

startFidget(draw, mainLoopMode = RepaintOnFrame)
