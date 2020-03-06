## Backend null is a dummy backend used for testing / dec gen
## Not a real backend will not draw anything


import uibase, times


proc draw*(group: Group) =
  ## Draws the group


proc redraw*() =
  ## Request the screen to be redrawn next
  if not requestedFrame:
    requestedFrame = true


proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard


proc openBrowserWithText*(text: string) =
  ## Opens a new window with just this text on it
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


proc `title=`*(win: uibase.Window, title: string) =
  ## Sets window url
  win.innerTitle = title


proc `title`*(win: uibase.Window): string =
  ## Gets window url
  return win.innerTitle


proc `url=`*(win: uibase.Window, url: string) =
  ## Sets window url
  win.innerUrl = url


proc `url`*(win: uibase.Window): string =
  ## Gets window url
  return win.innerUrl


proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads a font.
  discard
