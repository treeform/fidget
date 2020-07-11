import staticglfw, opengl

if init() == 0:
  quit("Failed to intialize GLFW.")

for openglVersion in [
  (1, 0),
  (1, 1),
  (1, 2),
  (1, 3),
  (1, 4),
  (1, 5),
  (2, 0),
  (2, 1),
  (3, 0),
  (3, 1),
  (3, 2),
  (3, 3),
  (4, 0),
  (4, 1),
  (4, 2),
  (4, 3),
  (4, 4),
  (4, 5),
  (4, 6),
]:

  windowHint(OPENGL_FORWARD_COMPAT, GL_TRUE.cint)
  windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)
  windowHint(CONTEXT_VERSION_MAJOR, openglVersion[0].cint)
  windowHint(CONTEXT_VERSION_MINOR, openglVersion[1].cint)

  windowHint(VISIBLE, GL_FALSE.cint)

  let window = createWindow(100, 100, "Test", nil, nil)
  if window.isNil:
    echo "ERROR: ", openglVersion
  else:
    echo "SUCCESS: ", openglVersion

  destroyWindow(window)
