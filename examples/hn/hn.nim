import fidget, json, strformat, uri

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")

setTitle("Hacker News")

proc header() =
  component "header":
    box 0, 0, 596, 50
    fill "#f56400"
    layoutAlign laStretch
    group "logo":
      box 3, 3, 44, 44
      text "Y":
        box 2, 2, 40, 40
        fill "#ffffff"
        font "IBM Plex Sans", 30, 400, 0, hCenter, vCenter
        characters "Y"
      rectangle "border":
        box 0, 0, 44, 44
        stroke "#ffffff"
        strokeWeight 2
    text "title":
      box 58, 0, 178, 50
      fill "#ffffff"
      font "IBM Plex Sans", 30, 400, 0, hLeft, vCenter
      characters "Hacker News"

proc news(id: string) =
  var call = httpGet(&"https://hacker-news.firebaseio.com/v0/item/{id}.json")
  if call.status != Ready:
    return

  frame "news":
    box 0, 50, 596, 50
    fill "#f6f6ef"
    layoutAlign laStretch
    frame "firstLine":
      box 11, 7, 485, 18
      layout lmHorizontal
      counterAxisSizingMode csFixed
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 9
      text "domain":
        box 389, 0, 96, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        let uri = parseUri(call.json["url"].getStr())
        characters "(" & uri.hostname & ")"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "title":
        box 18, 0, 362, 18
        fill "#000000"
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters call.json["title"].getStr()
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "score":
        box 0, 0, 9, 18
        fill "#828282"
        font "IBM Plex Sans", 14, 700, 0, hLeft, vTop
        characters $call.json["score"].getInt()
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
    frame "secondLine":
      box 10, 26, 392, 18
      layout lmHorizontal
      counterAxisSizingMode csFixed
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 4
      text "comments":
        box 305, 0, 87, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters $call.json["descendants"].getInt() & " comments"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "bar":
        box 296, 0, 5, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters "|"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "hide":
        box 264, 0, 28, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters "hide"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "bar":
        box 255, 0, 5, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters "|"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "flag":
        box 227, 0, 24, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters "flag"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "bar":
        box 218, 0, 5, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters "|"
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter
      text "points":
        box 0, 0, 214, 18
        fill "#000000", 0.5
        font "IBM Plex Sans", 14, 400, 0, hLeft, vTop
        characters "by " & call.json["by"].getStr()
        textAutoResize tsWidthAndHeight
        layoutAlign laCenter

proc drawMain() =
  frame "Page":
    box 0, 0, parent.box.w, parent.box.h
    orgBox 0, 0, 696, 639
    fill "#ffffff"
    frame "main":
      box 50, 0, 596, 450
      constraints cStretch, cMin
      layout lmVertical
      counterAxisSizingMode csFixed
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 0

      var call = httpGet("https://hacker-news.firebaseio.com/v0/topstories.json")
      if call.status == Ready:
        var i = 0
        for id in call.json:
          news($id.getInt())
          if i > 15:
            break
          inc i
      header()
    rectangle "bg":
      box 50, 0, 596, 639
      constraints cStretch, cStretch
      fill "#f6f6ef"

startFidget(drawMain, w = 800, h = 800)
