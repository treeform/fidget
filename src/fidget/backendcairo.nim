## Cairo backend uses cairo and glfw3 libarires to provide graphics and input

import uibase, times

import glfw3 as glfw, ../../cairo/src/cairo, math, vmath, opengl, chroma
import random


var
  w = 1024
  h = 1024
  surface = imageSurfaceCreate(FORMAT.argb32, w, h)
  frameCount = 0
  window: Window
  ctx = surface.newContext()


proc setSource(ctx: Context, color: Color) =
  ctx.setSource(
    color.b,
    color.g,
    color.r,
    color.a
  )

proc rectangle(ctx: Context, box: Box) =
  ctx.rectangle(
    box.x,
    box.y,
    box.w,
    box.h
  )

proc draw*(group: Group) =
  ## Redraws the whole screen
  if group.fill.a > 0:
    #echo group.box, group.fill
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


proc startFidget*() =
  ## Starts cairo backend

  proc display() =
    ## Called every frame by main while loop

    setupRoot()

    root.box.x = float 0
    root.box.y = float 0
    root.box.w = float w
    root.box.h = float h

    scrollBox.x = float 0
    scrollBox.y = float 0
    scrollBox.w = float w
    scrollBox.h = float h

    drawMain()

    # update texture with new pixels from surface
    var dataPtr = surface.imageSurfaceGetData()
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr)

    # draw a quad over the whole screen
    glClear(GL_COLOR_BUFFER_BIT)
    glBegin(GL_QUADS);
    glTexCoord2d(0.0, 0.0); glVertex2d(-1.0, +1.0)
    glTexCoord2d(1.0, 0.0); glVertex2d(+1.0, +1.0)
    glTexCoord2d(1.0, 1.0); glVertex2d(+1.0, -1.0)
    glTexCoord2d(0.0, 1.0); glVertex2d(-1.0, -1.0)
    glEnd();

    inc frameCount
    glfw.SwapBuffers(window)

  if glfw.Init() == 0:
    quit("Failed to Initialize GLFW")
  window = glfw.CreateWindow(cint w, cint h, "Real time GLFW/Cairo example", nil, nil)
  glfw.MakeContextCurrent(window)
  loadExtensions()

  # allocate a texture and bind it
  var dataPtr = surface.imageSurfaceGetData()
  glTexImage2D(GL_TEXTURE_2D, 0, 3, GLsizei w, GLsizei h, 0, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  glEnable(GL_TEXTURE_2D);

  while glfw.WindowShouldClose(window) == 0:
    glfw.PollEvents()
    display()
