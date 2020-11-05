import staticglfw, opengl, math, schema, render, flippy, vmath, bumpy
export bumpy

var
  mainFrame*: string
  windowSizeFixed*: bool
  mousePos*: Vec2
  mouseButton*: bool
  callBacks: seq[proc()]

proc use*(url: string) =
  schema.use(url)

proc showPopup*(name: string) =
  discard

template onFrame*(body: untyped) =
  ## Called once for each frame drawn.
  block:
    callBacks.add proc() =
      body

template onClick*(name: string, body: untyped) =
  onFrame:
    if mouseButton:
      let node = findByName(mainFrame).findByName(name)
      if node.rect.overlap(mousePos):
        body
        mouseButton = false

template onEdit*(id: string, text: var string) =
  ## When text node is display or edited
  discard

template onChange*(name: string, body: untyped) =
  discard

template onDisplay*(name: string, expression: untyped) =
  ## When a text node is displayed and will continue to update.
  onFrame:
    var value: string = expression
    let node = findByName(mainFrame).findByName(name)
    if node.characters != value:
      node.dirty = true
      node.characters = value

proc findByName*(node: Node, name: string): Node =
  for c in node.children:
    if c.name == name:
      return c
    let found = c.findByName(name)
    if found != nil:
      return found

proc findByName*(name: string): Node =
  figmaFile.document.findByName(name)

proc rect*(node: Node): Rect =
  result.x = node.absoluteBoundingBox.x + framePos.x
  result.y = node.absoluteBoundingBox.y + framePos.y
  result.w = node.absoluteBoundingBox.width
  result.h = node.absoluteBoundingBox.height

proc onMouseButton(
  window: staticglfw.Window, button, action, modifiers: cint
) {.cdecl.} =

  let
    setKey = action != 0
  mouseButton = setKey

proc startFidget*() =
  ## This example show how to have real time cairo using glfw backend

  var
    w: int32 = 400
    h: int32 = 400


  if windowSizeFixed:
    let frameNode = findByName(mainFrame)
    assert frameNode != nil
    w = frameNode.absoluteBoundingBox.width.int32
    h = frameNode.absoluteBoundingBox.height.int32


  var
    window: Window
    frameIndex = 0
    lock = false

  proc display() =
    ## Called every frame by main while loop

    block:
      var x, y: float64
      window.getCursorPos(addr x, addr y)
      mousePos.x = x
      mousePos.y = y

    for cb in callBacks:
      cb()

    let mainNode = figmaFile.document.children[0].findByName(mainFrame)
    let image = drawCompleteFrame(mainNode)

    #image.save("frame.png")

    # update texture with new pixels from surface
    var dataPtr = addr image.data[0]
    glTexSubImage2D(
      GL_TEXTURE_2D,
      0,
      0,
      0,
      GLsizei image.width,
      GLsizei image.height,
      GL_RGBA,
      GL_UNSIGNED_BYTE,
      dataPtr
    )

    # draw a quad over the whole screen
    glClear(GL_COLOR_BUFFER_BIT)
    glBegin(GL_QUADS);
    glTexCoord2d(0.0, 0.0); glVertex2d(-1.0, +1.0)
    glTexCoord2d(1.0, 0.0); glVertex2d(+1.0, +1.0)
    glTexCoord2d(1.0, 1.0); glVertex2d(+1.0, -1.0)
    glTexCoord2d(0.0, 1.0); glVertex2d(-1.0, -1.0)
    glEnd();

    swapBuffers(window)

  # Init GLFW
  if init() == 0:
    raise newException(Exception, "Failed to Initialize GLFW")

  # Open window.
  window = createWindow(w, h, "Figma/Mirror", nil, nil)
  # Connect the GL context.
  window.makeContextCurrent()
  # This must be called to make any GL function work
  loadExtensions()

  # allocate a texture and bind it
  ctx = newImage(w, h, 4)
  var dataPtr = addr ctx.data[0]
  glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  glEnable(GL_TEXTURE_2D);

  discard window.setMouseButtonCallback(onMouseButton)

  # Run while window is open.
  while windowShouldClose(window) == 0:
    pollEvents()
    display()
    if window.getKey(KEY_RIGHT) == PRESS:
      if not lock:
        lock = true
        inc frameIndex
    if window.getKey(KEY_RIGHT) == RELEASE:
      lock = false

  # Destroy the window.
  window.destroyWindow()
  # Exit GLFW.
  terminate()
