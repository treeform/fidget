## Backend null is a dummy backend used for testing / dec gen
## Not a real backend will not draw anything

import internal, tables, times, common

var
  windowTitle, windowUrl: string
  values = newTable[string, string]()

proc draw*(node: Node) =
  ## Draws the node

proc postDrawChildren*(node: Node) =
  ## Turns off clip masks and such

proc refresh*() =
  ## Request the screen be redrawn
  requestedFrame = true

proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard

proc startFidget*(
    draw: proc(),
    tick: proc() = nil,
    fullscreen = false,
    w: Positive = 1280,
    h: Positive = 800,
) =
  ## Starts fidget UI library
  drawMain = draw
  for i in 0 ..< 10:
    let startTime = epochTime()
    setupRoot()
    drawMain()
    echo "drawMain walk took: ", epochTime() - startTime, "ms"
  dumpTree(root)

proc getTitle*(): string =
  ## Gets window title
  windowTitle

proc setTitle*(title: string) =
  ## Sets window title
  windowTitle = title

proc getUrl*(): string =
  ## Gets window url
  windowUrl

proc setUrl*(url: string) =
  ## Sets window url
  windowUrl = url

proc loadFont*(name: string, pathOrUrl: string) =
  ## Loads a font.
  discard

proc setItem*(key, value: string) =
  ## Saves value in memory only.
  values[key] = value

proc getItem*(key: string): string =
  ## Gets a value in memory only.
  values[key]
