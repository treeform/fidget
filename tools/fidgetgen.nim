import httpclient, strutils, json, os, ospaths, strformat, tables, chroma, parseopt
import print, vmath

var
  figmaKey: string
  fileKey: string
  boxStack: seq[Rect]
  jsonRes: JsonNode
  jsonDoc: JsonNode
  fetchUrl: string
  outputFile: string
  generatedCode: string

proc f(js: JsonNode): string =
  var n = js.getFloat()
  fmt"{n:<0.3f}"

proc replaceEnd(s, ending, replacement: string): string =
  if s.endsWith(ending):
    return s[0 ..^ ending.len] & replacement
  return s

proc colorFmt(colorNode: JsonNode, opacity: float = 1.0): string =
  var colorValue = color(
    colorNode["r"].getFloat(),
    colorNode["g"].getFloat(),
    colorNode["b"].getFloat())

  if opacity == 1.0:
    # just the hex color then
    return fmt""""{colorValue.toHtmlHex()}""""
  else:
    # opacity later
    return fmt""""{colorValue.toHtmlHex()}", {opacity:<0.3f}"""


proc pathToName(path: string): string =
  result = ""
  for p in path.split("/"):
    result.add p.capitalizeAscii()


var codeIdTable = newTable[string, string]()
proc walkerCode(jsonDoc: JsonNode) =
  for frame in jsonDoc["children"][0]["children"]:
    let frameName = frame["name"].getStr().toLowerAscii()
    if frameName.endsWith(".code"):
      var code = frame["children"][0]["characters"].getStr()
      code = code.replace("“", "\"").replace("”", "\"")
      codeIdTable[frame["id"].getStr()] = code


var nodeIdTable = newTable[string, JsonNode]()
proc walkIds(parent: JsonNode) =
  if "id" in parent:
    nodeIdTable[parent["id"].getStr()] = parent
  if "children" in parent:
    for node in parent["children"]:
      walkIds(node)


proc walker(node: JsonNode, indent: string = "") =
  var indent = indent

  template say(what: untyped) =
    if $what == "":
      generatedCode.add "\n"
    else:
      generatedCode.add indent
      generatedCode.add $what
      generatedCode.add "\n"

  var nodeType = node["type"].getStr().toLowerAscii()
  var isInstance = nodeType == "instance"

  # SKIP .code and .noexport frames
  let frameName = node["name"].getStr().toLowerAscii()
  if nodeType == "frame" and (frameName.endsWith(".code") or
      frameName.endsWith(".noexport")):
    return

  if nodeType == "document" or nodeType == "canvas":
    for kid in node["children"]:
      walker(kid, indent)
    return

  if nodeType == "boolean_operation":
    nodeType = "group"

  if nodeType in ["vector", "regular_polygon"]:
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

  if indent == "" and (nodeType != "frame" or nodeType != "component"):
    #say "# skipping " & nodeType & " " & $node["name"]
    return

  var nodeName = node["name"].getStr()
  var nodeId = node["id"].getStr()
  var visible = true
  if "visible" in node:
    visible = node["visible"].getBool()
  if nodeName == "hover:":
    say "onHover:"
    indent.add "  "
    visible = true

  elif nodeName == "down:":
    say "onDown:"
    indent.add "  "
    visible = true

  if not visible:
    return

  say &"{nodeType} \"{nodeName}\": # {nodeId}"
  indent.add "  "
  boxStack.add Rect()
  defer: discard boxStack.pop()

  var
    constraintsVertical = "TOP"
    constraintsHorizontal = "LEFT"
  if "constraints" in node:
    constraintsVertical = node["constraints"]["vertical"].getStr()
    constraintsHorizontal = node["constraints"]["horizontal"].getStr()


  var box = Rect()
  boxStack[^1] = box
  if nodeName.endsWith("_root"):
    constraintsVertical = "ROOT"
    constraintsHorizontal = "ROOT"

  var transRect: Rect
  let relativeTransform = node["relativeTransform"]
  let size = node["size"]

  transRect.x = relativeTransform[0][2].getFloat()
  transRect.y = relativeTransform[1][2].getFloat()
  transRect.w = size["x"].getFloat()
  transRect.h = size["y"].getFloat()


  # let scale = vec2(
  #   relativeTransform[0][0].getFloat(),
  #   relativeTransform[1][1].getFloat()
  # )
  # if scale != vec2(1, 1):
  #   say &"scale {scale.x}, {scale.y}"
  #print scale

  let rotation = arccos(relativeTransform[0][0].getFloat())
  if rotation != 0:
    say &"rotation {rotation/PI*180}"
    var
      rotatedPos = vec3(transRect.xy, 0)
      sizeToRotate = vec3(-transRect.wh/2, 0)
      unroateMat = rotate(-rotation, vec3(0,0,1))
      sizeUnrotated = unroateMat * sizeToRotate
      unroatedPos = rotatedPos - sizeUnrotated + sizeToRotate
    transRect.xy = unroatedPos.xy


  box = transRect
  boxStack[^1] = box

  var comment =  "# " & constraintsVertical & " " & constraintsHorizontal
  if comment == "# TOP LEFT":
    # top left is most comment don't spam it everywhere
    comment = ""

  proc f(n: float): string =
    $int(n)

  var parBox: Rect
  if boxStack.len > 1:
    parBox = boxStack[^2]
  var curBox = box
  #curBox.x -= parBox.x
  #curBox.y -= parBox.y

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
      y.add " + " & f(curBox.y - (parBox.h / 2))
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
    of "ROOT": ## for .root frames
      y = "0"
      h = "root.box.h"
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
      x.add " + " & f(curBox.x - (parBox.w / 2))
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
    of "ROOT": ## for .root frames
      x = "0"
      w = "root.box.w"
    else:
      assert false

  say fmt"box {x}, {y}, {w}, {h} {comment}".replace(" - 0,", ",").replace(" - 0 ", " ").replace("+ -", "- ")

  if isInstance and "componentId" in node:
    let coponentId =  node["componentId"].getStr()
    say "# componentId " & coponentId
    # let componentId = $jsonRes["components"][node["componentId"].getStr()]["name"]
    # if componentId.startsWith("\"icon"):
    #   # TODO: This should go away once components are handled better
    #   say "image " & componentId
    # else:
    #   say "# componentId " & componentId
    let component = nodeIdTable[coponentId]
    if "exportSettings" in component:
      if component["exportSettings"].len > 0:
        say "image " & $component["name"]
        return

  if "cornerRadius" in node:
    say "cornerRadius " & $node["cornerRadius"]

  if "fills" in node:
    for fill in node["fills"]:
      if "color" in fill:
        let colorNode = fill["color"]
        var opacity = 1.0
        if "opacity" in fill:
          opacity = fill["opacity"].getFloat()
        # say "fill color(" &
        #   f(colorNode["r"]) & ", " &
        #   f(colorNode["g"]) & ", " &
        #   f(colorNode["b"]) & ", " &
        #   opacity & ")"
        say "fill " & colorFmt(colorNode, opacity)
      break

  if "backgroundColor" in node:
    let colorNode = node["backgroundColor"]
    if colorNode["a"].getFloat() > 0:
      # only say fill color if its not transperant
      say "fill color(" &
        f(colorNode["r"]) & ", " &
        f(colorNode["g"]) & ", " &
        f(colorNode["b"]) & ", " &
        f(colorNode["a"]) & ")"

  if "strokeWeight" in node:
    var hasStroke = false
    if node["strokeWeight"].getFloat() > 0:
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
            hasStroke = true
    if hasStroke:
      say "strokeWeight " & $node["strokeWeight"]

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
      return

  if "transitionNodeID" in node:
    #say "transitionNodeID " & $node["transitionNodeID"]
    #say "code \"\"\"" & codeIdTable[node["transitionNodeID"].getStr()] & "\"\"\""

    var code = codeIdTable[node["transitionNodeID"].getStr()]
    say "# code"
    for line in code.split("\n"):
      say line

  if "children" in node:
    for kid in node["children"]:
      walker(kid, indent)



proc writeVersion() =
  echo "v0.1"

proc writeHelp() =
  echo """fidgetgen url -o:outputfile
  --version, -v displays version
  --help, -h display help
  --output, -o output file
  """

import print

proc main() =

  var p = initOptParser()
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      fetchUrl = key
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
      of "output", "o": outputFile = val
    of cmdEnd: assert(false) # cannot happen
  if fetchUrl == "":
    # no url has been given, so we show the help:
    writeHelp()

  let keyHelp = " (see https://www.figma.com/developers/docs#authentication on how to get one)"
  if existsFile(".figma"):
    figmaKey = readFile(".figma").strip()
    if figmaKey == "":
      quit "Using .figma file but its empty and does not contain key!" & keyHelp
  elif existsFile(getHomeDir() & "/.figma"):
    figmaKey = readFile(getHomeDir() & "/.figma").strip()
    if figmaKey == "":
      quit "Using ~/.figma file but its empty and does not contain key!" & keyHelp
  else:
    quit "File .figma or ~/.figma with Figma Key not found"

  if fetchUrl.startsWith("https://www.figma.com/file/"):
    # if normal figma URL
    fileKey = fetchUrl.replace("https://www.figma.com/file/", "").split("/")[0]
  elif "/" notin fetchUrl:
    # just they key
    fileKey = fetchUrl
  else:
    quit "URL not recognised, expecting https://www.figma.com/file/***key***/ or just ***key***"

  if outputFile == "":
    quit "Output file expected. -o:/path/to/file"

  # Now will do the fetching

  var client = newHttpClient()
  client.headers = newHttpHeaders({"X-FIGMA-TOKEN": figmaKey})
  var jsonText = client.getContent("https://api.figma.com/v1/files/" & fileKey & "?geometry=paths")

  var jsonRes = parseJson(jsonText)
  var jsonDoc = jsonRes["document"]

  writeFile(outputFile.changeFileExt(".json"), pretty jsonDoc)

  generatedCode.add "import fidget\n\n"
  walkIds(jsonDoc)
  walkerCode(jsonDoc)
  walker(jsonDoc)

  writeFile(outputFile, generatedCode)

main()
