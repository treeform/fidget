## Cairo backend uses cairo and glfw3 libarires to provide graphics and input

import uibase, times

import glfw3 as glfw, quickcairo, math, vmath, opengl, chroma, print, os
import random


var
  surface: Surface
  ctx: Context
  frameCount = 0
  window: glfw.Window
  dpi*: float = 1.0
  windowFrame: Box
  viewPort: Box


proc setSource(ctx: Context, color: Color) =
  ctx.setSource(
    color.b,
    color.g,
    color.r,
    color.a
  )

proc rectangle(ctx: Context, box: Box) =
  ctx.rectangle(
    floor box.x,
    floor box.y,
    floor box.w,
    floor box.h
  )

proc draw*(group: Group) =
  ## Redraws the whole screen
  if group.fill.a > 0:

    if group.kind == "text":
      if group.text.len > 0:
        ctx.selectFontFace(group.textStyle.fontFamily, FONT_SLANT.normal, FONT_WEIGHT.normal)
        ctx.setFontSize(group.textStyle.fontSize)
        ctx.setSource(group.fill)
        var extents = TextExtents()
        ctx.textExtents(group.text, extents)
        var x, y: float
        case group.textStyle.textAlignHorizontal:
          of -1:
            x = group.screenBox.x
          of 0:
            x = group.screenBox.x + group.screenBox.w/2 - float(extents.width)/2
          of 1:
            x = group.screenBox.x + group.screenBox.w - extents.width

        case group.textStyle.textAlignVertical:
          of -1:
            y = group.screenBox.y + extents.height
          of 0:
            y = group.screenBox.y + group.screenBox.h/2 - float(extents.height)/2
          of 1:
            y = group.screenBox.y + group.screenBox.h

        ctx.moveTo(x, y)
        ctx.showText(group.text)
    else:
      ctx.rectangle(group.screenBox)
      ctx.setSource(group.fill)
      ctx.fill()

proc redraw*() =
  ## Request the screen to be redrawn next
  if not requestedFrame:
    requestedFrame = true


proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard


proc goto*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  rootUrl = url
  redraw()


proc display() =
  echo "display"
  ## Called every frame by main while loop

  setupRoot()

  root.box.x = float 0
  root.box.y = float 0
  root.box.w = windowFrame.w
  root.box.h = windowFrame.h

  scrollBox.x = float 0
  scrollBox.y = float 0
  scrollBox.w = root.box.w
  scrollBox.h = root.box.h

  drawMain()

  # update texture with new pixels from surface
  let
    dataPtr = surface.imageSurfaceGetData()
    w = surface.width
    h = surface.height
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr)

  # draw a quad over the whole screen
  glClear(GL_COLOR_BUFFER_BIT)
  glBegin(GL_QUADS);
  glTexCoord2d(0.0, 0.0)
  glVertex2d(-1.0, +1.0)
  glTexCoord2d(viewPort.w/float(w), 0.0)
  glVertex2d(+1.0, +1.0)
  glTexCoord2d(viewPort.w/float(w), viewPort.h/float(h))
  glVertex2d(+1.0, -1.0)
  glTexCoord2d(0.0, viewPort.h/float(h))
  glVertex2d(-1.0, -1.0)
  glEnd();

  inc frameCount
  glfw.SwapBuffers(window)


proc closestPowerOf2(v: int): int =
  ## returns closets power of 2 ... 2,4,8,16... that is higher then v
  result = 2
  while true:
    if v < result:
      return
    result *= 2


proc resize() =
  var cwidth, cheight: cint
  GetWindowSize(window, addr cwidth, addr cheight)
  windowFrame.w = float(cwidth)
  windowFrame.h = float(cheight)

  GetFramebufferSize(window, addr cwidth, addr cheight)
  viewPort.w = float(cwidth)
  viewPort.h = float(cheight)
  dpi = viewPort.w / windowFrame.w
  glViewport(0, 0, cwidth, cheight)

  var
    w = closestPowerOf2(int viewPort.w)
    h = closestPowerOf2(int viewPort.h)
  if surface == nil or w > surface.width or h > surface.height:

    print "resize", w, h
    # need to resize and re inint everything
    surface = imageSurfaceCreate(FORMAT.argb32, w, h)
    ctx = surface.newContext()

    # allocate a texture and bind it
    var dataPtr = surface.imageSurfaceGetData()
    glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
    glEnable(GL_TEXTURE_2D)


proc onResize(handle: glfw.Window, w, h: int32) {.cdecl.} =
  resize()
  redraw()


proc onMouseButton(window: glfw.Window, button: cint, action: cint, modifiers: cint) {.cdecl.} =
  if action == 0:
    mouse.down = false
    mouse.click = false
  else:
    mouse.click = true
    mouse.down = true
  # let button = button + 1
  # if button < buttonDown.len:
  #   if buttonDown[button] == false and setKey == true:
  #     buttonPress[button] = true
  #   buttonDown[button] = setKey
  redraw()

proc onMouseMove(window: glfw.Window; x: cdouble; y: cdouble) {.cdecl.} =
  # this does not fire when mouse is not in the window
  mouse.pos = vec2(x, y) * dpi
  redraw()

proc `title=`*(win: uibase.Window, title: string) =
  if win.innerTitle != title:
    win.innerTitle = title
    window.SetWindowTitle(title)


proc `title`*(win: uibase.Window): string =
  win.innerTitle


proc startFidget*() =
  ## Starts cairo backend
  if glfw.Init() == 0:
    quit("Failed to Initialize GLFW")
  window = glfw.CreateWindow(1000, 800, "Fidget glfw/cairo backend window.", nil, nil)
  glfw.MakeContextCurrent(window)
  loadExtensions()

  glfw.PollEvents()
  resize()

  discard SetCursorPosCallback(window, onMouseMove)
  discard SetMouseButtonCallback(window, onMouseButton)
  discard SetFramebufferSizeCallback(window, onResize)

  while glfw.WindowShouldClose(window) == 0:
    glfw.PollEvents()

    if requestedFrame:
      requestedFrame = false
      display()
    else:
      sleep(1)

    # reset one off events
    mouse.click = false
