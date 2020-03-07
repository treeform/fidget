import os, strformat

let examplesDir = getCurrentDir()

proc native(folder: string) =
  if execShellCmd(&"nim c {folder}/{folder}.nim") != 0:
    echo "[error] ", folder
    quit()
  else:
    echo "[ok] ", folder
    setCurrentDir(folder)
    let exeUrl = &"{folder}"
    if execShellCmd(exeUrl) != 0:
      echo "[error] Starting ", exeUrl
      quit()
    setCurrentDir(examplesDir)

native "areas"
native "bars"
native "demo"
native "constraints"
native "pluginexport"
native "textalign"
native "hovers"
native "inputs"
native "minimal"
native "padofcode"
native "padoftext"
native "textandinputs"

# TODO: finish
# native "todo"
