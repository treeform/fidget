import os, strformat, strutils

var runList: seq[string]

proc javaScript(folder: string) =
  let file = folder.lastPathPart
  if execShellCmd(&"nim js ../{folder}/{file}.nim") != 0:
    echo "[error] ", folder
    quit()
  else:
    echo "[ok] ", folder
    runList.add folder

javaScript "examples/areas"
javaScript "examples/demo"
javaScript "examples/constraints"
javaScript "examples/minimal"
javaScript "examples/padofcode"
javaScript "examples/padoftext"
javaScript "examples/todo"

javaScript "tests/bars"
javaScript "tests/hovers"
javaScript "tests/inputs"
javaScript "tests/inputtest"
javaScript "tests/pluginexport"
javaScript "tests/textalign"
javaScript "tests/textandinputs"

for folder in runList:
  let file = folder.lastPathPart
  var exeDir = os.getAppDir().parentDir
  let fileUrl = &"file:///{exeDir}/{folder}/{file}.html"
  if execShellCmd(&"start chrome {fileUrl}") != 0:
    echo "[error] Starting Chrome: ", fileUrl
    quit()


echo "success"
