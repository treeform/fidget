## Cairo backend uses cairo and glfw3 libarires to provide graphics and input

import uibase, times

import glfw3 as glfw, math, vmath, opengl, chroma, print, os
import random


var
  # surface: Surface
  # ctx: Context
  frameCount = 0
  window: glfw.Window
  dpi*: float = 1.0
  windowFrame: Box
  viewPort: Box


proc draw*(group: Group) =
  ## Redraws the whole screen
  if group.fill.a > 0:

    if group.kind == "text":
      if group.text.len > 0:
        glBegin(GL_QUADS)
        glColor4f(group.fill.r, group.fill.g, group.fill.b, group.fill.a)
        proc drawRect(sx, sy, sw, sh: float) =
          let
            wf = windowFrame
            x = sx / wf.w*2 - 1.0
            y = -sy / wf.h*2 + 1.0
            w = sw / wf.w*2
            h = -sh / wf.h*2
          glVertex2d(x,     y + h)
          glVertex2d(x + w, y + h)
          glVertex2d(x + w, y)
          glVertex2d(x,     y)
        let b = group.screenBox
        drawRect(b.x, b.y, b.w, b.h)
        glEnd()
        # ctx.selectFontFace(group.textStyle.fontFamily, FONT_SLANT.normal, FONT_WEIGHT.normal)
        # ctx.setFontSize(group.textStyle.fontSize)
        # ctx.setSource(group.fill)
        # var extents = TextExtents()
        # ctx.textExtents(group.text, extents)
        # var x, y: float
        # case group.textStyle.textAlignHorizontal:
        #   of -1:
        #     x = group.screenBox.x
        #   of 0:
        #     x = group.screenBox.x + group.screenBox.w/2 - float(extents.width)/2
        #   of 1:
        #     x = group.screenBox.x + group.screenBox.w - extents.width

        # case group.textStyle.textAlignVertical:
        #   of -1:
        #     y = group.screenBox.y + extents.height
        #   of 0:
        #     y = group.screenBox.y + group.screenBox.h/2 - float(extents.height)/2
        #   of 1:
        #     y = group.screenBox.y + group.screenBox.h

        # ctx.moveTo(x, y)
        # ctx.showText(group.text)
    else:
      glBegin(GL_QUADS)
      glColor4f(group.fill.r, group.fill.g, group.fill.b, group.fill.a)
      proc drawRect(sx, sy, sw, sh: float) =
        let
          wf = windowFrame
          x = sx / wf.w*2 - 1.0
          y = -sy / wf.h*2 + 1.0
          w = sw / wf.w*2
          h = -sh / wf.h*2
        glVertex2d(x,     y + h)
        glVertex2d(x + w, y + h)
        glVertex2d(x + w, y)
        glVertex2d(x,     y)
      let b = group.screenBox
      drawRect(b.x, b.y, b.w, b.h)
      glEnd()


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

  # # update texture with new pixels from surface
  # let
  #   dataPtr = surface.imageSurfaceGetData()
  #   w = surface.width
  #   h = surface.height
  # glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr)



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


proc onResize(handle: glfw.Window, w, h: int32) {.cdecl.} =
  resize()
  display()


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

proc onMouseMove(window: glfw.Window, x: cdouble, y: cdouble) {.cdecl.} =
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

  glDisable(GL_CULL_FACE)

  discard SetCursorPosCallback(window, onMouseMove)
  discard SetMouseButtonCallback(window, onMouseButton)
  discard SetFramebufferSizeCallback(window, onResize)

  requestedFrame = true

  while glfw.WindowShouldClose(window) == 0:
    glfw.PollEvents()

    if requestedFrame:
      requestedFrame = false
      display()
    else:
      sleep(1)

    # reset one off events
    mouse.click = false
