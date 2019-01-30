#nim c -r -d:ssl --verbosity:0 "c:\Users\me\Dropbox\p\istrolid2\fidget\fetcher.nim" > fidget/generated.nim; tools\dos2unix fidget/generated.nim

import httpclient, strutils, json, os, strformat, tables

type
  Rect* = object
    x*, y*, w*, h*: float

let
  fimgaKey = paramStr(1)
  fileKey = paramStr(2)

var client = newHttpClient()
client.headers = newHttpHeaders({"X-FIGMA-TOKEN": fimgaKey})
var jsonText = client.getContent("https://api.figma.com/v1/files/" & fileKey)

var jsonRes = parseJson(jsonText)
var jsonDoc = jsonRes["document"]

var boxStack = newSeq[Rect]()

writeFile("fidget/ui.json", pretty jsonDoc)


proc f(js: JsonNode): string =
  var n = js.getFloat()
  fmt"{n:<0.3f}"

proc pathToName(path: string): string =
  result = ""
  for p in path.split("/"):
    result.add p.capitalizeAscii()


var codeIdTable = newTable[string, string]()
proc walkerCode(jsonDoc: JsonNode) =
  for frame in jsonDoc["children"][0]["children"]:
    if frame["name"].getStr().startsWith("code:"):
      codeIdTable[frame["id"].getStr()] = frame["children"][0]["characters"].getStr()


proc walker(node: JsonNode, indent: string = "") =
  var indent = indent
  boxStack.add Rect()
  template say(what: untyped) =
    if $what == "":
      echo ""
    else:
      echo indent, $what

  var nodeType = node["type"].getStr().toLowerAscii()
  var isInstance = nodeType == "instance"

  if nodeType == "document" or nodeType == "canvas":
    for kid in node["children"]:
      walker(kid, indent)
    discard boxStack.pop()
    return

  if nodeType in ["boolean_operation", "vector"]:
    discard boxStack.pop()
    return

  if indent == "":
    if "visible" in node and node["visible"].getBool() == false:
      return
    say ""
    # only create procs if at top level
    if nodeType == "frame":
      say ""
      say "proc " & nodeType & node["name"].getStr().pathToName() & "*() ="
      indent.add "  "
    elif nodeType == "component":
      say ""
      say "proc " & nodeType & node["name"].getStr().pathToName() & "*() ="
      indent.add "  "
  else:
    say ""
    if nodeType == "frame":
      # frame inside a frame?
      nodeType = "component"

  if node["name"].getStr().startsWith("code:"):
    return

  if indent == "" and (nodeType != "frame" or nodeType != "component"):
    say "# skipping " & nodeType & " " & $node["name"]
    return

  say nodeType & " " & $node["name"] & ":" #, " & $node["id"] & ":"
  indent.add "  "

  if "cornerRadius" in node:
    say "cornerRadius " & $node["cornerRadius"]

  if "fills" in node:
    for fill in node["fills"]:
      if "color" in fill:
        let colorNode = fill["color"]
        var opacity = "1.0"
        if "opacity" in fill:
          opacity = f(fill["opacity"])
        say "fill color(" &
          f(colorNode["r"]) & ", " &
          f(colorNode["g"]) & ", " &
          f(colorNode["b"]) & ", " &
          opacity & ")"

  if "backgroundColor" in node:
    let colorNode = node["backgroundColor"]
    say "fill color(" &
      f(colorNode["r"]) & ", " &
      f(colorNode["g"]) & ", " &
      f(colorNode["b"]) & ", " &
      f(colorNode["a"]) & ")"

  if "strokes" in node:
    for stroke in node["strokes"]:
      if "color" in stroke:
        let colorNode = stroke["color"]
        var opacity = "1.0"
        if "opacity" in stroke:
          opacity = f(stroke["opacity"])
        say "stroke color(" &
          f(colorNode["r"]) & ", " &
          f(colorNode["g"]) & ", " &
          f(colorNode["b"]) & ", " &
          opacity & ")"
  if "strokeWeight" in node:
    if node["strokes"].len > 0:
      say "strokeWeight " & $node["strokeWeight"]

  if "transitionNodeID" in node:
    #say "transitionNodeID " & $node["transitionNodeID"]
    say "code \"\"\"" & codeIdTable[node["transitionNodeID"].getStr()] & "\"\"\""

  if "absoluteBoundingBox" in node:
    var
      constraintsVertical = "TOP"
      constraintsHorizontal = "LEFT"
    if "constraints" in node:
      constraintsVertical = node["constraints"]["vertical"].getStr()
      constraintsHorizontal = node["constraints"]["horizontal"].getStr()

    var boxNode = node["absoluteBoundingBox"]
    var box = Rect()

    box.x = boxNode["x"].getFloat()
    box.y = boxNode["y"].getFloat()
    box.w = boxNode["width"].getFloat()
    box.h = boxNode["height"].getFloat()
    boxStack[^1] = box

    let comment =  "# " & constraintsVertical & " " & constraintsHorizontal

    proc f(n: float): string =
      $int(n)

    var parBox = boxStack[^2]
    var curBox = box
    curBox.x -= parBox.x
    curBox.y -= parBox.y

    var
      x: string = f(curBox.x)
      y: string = f(curBox.y)
      w: string = f(curBox.w)
      h: string = f(curBox.h)

    case constraintsVertical:
      of "TOP":
        discard
      of "BOTTOM":
        y = "parent.box.h"
        if parBox.h - curBox.y != 0: y.add " - " & f(parBox.h - curBox.y)
      of "TOP_BOTTOM":
        h = "parent.box.h"
        if parBox.h - curBox.h != 0: h.add " - " & f(parBox.h - curBox.h)
      of "CENTER":
        y = "parent.box.h/2"
        if curBox.h/2 != 0: y.add " - " & f(curBox.h/2)
      of "SCALE":
        y = "parent.box.h * " & f(curBox.y) & "/" & f(parBox.h)
        h = "parent.box.h * " & f(curBox.h) & "/" & f(parBox.h)
        if curBox.y == 0:
          y = "0"
        if curBox.h == 0:
          h = "0"
        if curBox.y/parBox.h == 1:
          y = "parent.box.h"
        if curBox.h/parBox.h == 1:
          h = "parent.box.h"
      else:
        assert false

    case constraintsHorizontal:
      of "LEFT":
        discard
      of "RIGHT":
        x = "parent.box.w"
        if parBox.w - curBox.x != 0: x.add " - " & f(parBox.w - curBox.x)
      of "LEFT_RIGHT":
        w = "parent.box.w"
        if parBox.w - curBox.w != 0: w.add " - " & f(parBox.w - curBox.w)
      of "CENTER":
        x = "parent.box.w/2"
        if curBox.w/2 != 0: x.add " - " & f(curBox.w/2)
      of "SCALE":
        x = "parent.box.w * " & f(curBox.x) & "/" & f(parBox.w)
        w = "parent.box.w * " & f(curBox.w) & "/" & f(parBox.w)
        if curBox.x == 0:
          x = "0"
        if curBox.w == 0:
          w = "0"
        if curBox.x/parBox.w == 1:
          x = "parent.box.w"
        if curBox.w/parBox.w == 1:
          w = "parent.box.w"
      else:
        assert false

    say fmt"box {x}, {y}, {w}, {h} {comment}".replace(" - 0,", ",").replace(" - 0 ", " ")

  if isInstance and "componentId" in node:
    let componentId = $jsonRes["components"][node["componentId"].getStr()]["name"]
    if componentId.startsWith("\"icon"):
      # TODO: This should go away once components are handled better
      say "image " & componentId
    else:
      say "componentId " & componentId

  if nodeType == "text":

    # old way
    # say "textAlignHorizontal HAlignMode." & node["style"]["textAlignHorizontal"].getStr().toLowerAscii().capitalizeAscii()
    # var vmode = node["style"]["textAlignVertical"].getStr().toLowerAscii().capitalizeAscii()
    # if vmode == "Center": vmode = "Middle"
    # say "textAlignVertical VAlignMode." & vmode
    # say "fontFamily " & $node["style"]["fontFamily"]
    # say "fontSize " & $node["style"]["fontSize"].getFloat()
    # say "textLineHeight " & $int(node["style"]["lineHeightPx"].getFloat() - 3)

    proc asNum(textAlign: string): int =
      case textAlign:
        of "LEFT": -1
        of "CENTER": 0
        of "RIGHT": 1
        of "TOP": -1
        of "BOTTOM": 1
        else: 0

    var
      textAlignHorizontal = asNum(node["style"]["textAlignHorizontal"].getStr())
      textAlignVertical = asNum(node["style"]["textAlignVertical"].getStr())
      fontFamily = $node["style"]["fontFamily"]
      fontSize = $node["style"]["fontSize"].getFloat()
      fontWeight = $node["style"]["fontWeight"].getFloat()
      lineHeightPx = $int(node["style"]["lineHeightPx"].getFloat() - 3)

    say "font " & fontFamily & ", " & $fontSize & ", " & fontWeight & ", " & $lineHeightPx & ", " & $textAlignHorizontal & ", " & $textAlignVertical

    if "characters" in node:
      say "characters " & $node["characters"]

  if "exportSettings" in node:
    if node["exportSettings"].len > 0:
      say "image " & $node["name"]
      discard boxStack.pop()
      return

  if "children" in node:
    for kid in node["children"]:
      walker(kid, indent)

  discard boxStack.pop()



echo "import ../../fidget/src/fidget"
walkerCode(jsonDoc)
walker(jsonDoc)
