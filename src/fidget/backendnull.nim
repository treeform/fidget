## Backend null is a dummy backend used for testing / dec gen
## Not a real backend will not draw anything


import uibase, times


proc draw*(group: Group) =
  ## Redraws the whole screen


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
  ## Starts fidget UI library
  ## Null backend only draws drawMain() once

  let startTime = epochTime()
  setupRoot()
  drawMain()
  echo "drawMain walk took: ", epochTime() - startTime, "ms"