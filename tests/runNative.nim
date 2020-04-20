import os, strformat

let examplesDir = getCurrentDir()

var runList: seq[string]

proc native(folder: string) =
  let file = folder.lastPathPart
  if execShellCmd(&"nim c ../{folder}/{file}.nim") != 0:
    echo "[error] ", folder
    quit()
  else:
    echo "[ok] ", folder
    runList.add(folder)

native "examples/areas"
native "examples/demo"
native "examples/constraints"
native "examples/minimal"
native "examples/padofcode"
native "examples/padoftext"
# TODO: finish native "examples/todo"

native "tests/bars"
native "tests/hovers"
native "tests/inputs"
native "tests/inputtest"
native "tests/pluginexport"
native "tests/textalign"
native "tests/textandinputs"


for folder in runList:
  setCurrentDir(".." / folder)
  let exeUrl = folder.lastPathPart
  if execShellCmd(exeUrl) != 0:
    echo "[error] Starting ", exeUrl
    quit()
  setCurrentDir(examplesDir)

echo "success"
