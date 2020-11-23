## This example show how to have real time cairo using glfw backend
import staticglfw, opengl, math
import schema, render, pixie
use("https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/")

let
  w: int32 = 400
  h: int32 = 400

var
  window: Window
  frameIndex = 0
  lock = false

proc display() =
  ## Called every frame by main while loop

  drawCompleteFrame(figmaFile.document.children[0].children[frameIndex])

  # update texture with new pixels from surface
  var dataPtr = addr ctx.data[0]
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, GLsizei w, GLsizei h, GL_RGBA, GL_UNSIGNED_BYTE, dataPtr);

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
