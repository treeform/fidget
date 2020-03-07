import os, strformat

let examplesDir = getCurrentDir()

proc javaScript(folder: string) =
  if execShellCmd(&"nim js {folder}/{folder}.nim") != 0:
    echo "[error] ", folder
    quit()
  else:
    echo "[ok] ", folder

    let fileUrl = &"file:///C:/p/fidget/examples/{folder}/{folder}.html"
    if execShellCmd(&"start chrome {fileUrl}") != 0:
      echo "[error] Starting Chrome: ", fileUrl
      quit()

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

javaScript "areas"
javaScript "bars"
javaScript "basic"
javaScript "constraints"
javaScript "pluginexport"
javaScript "fonts"
javaScript "hovers"
javaScript "inputs"
javaScript "minimal"
javaScript "padofcode"
javaScript "padoftext"
javaScript "textandinputs"
javaScript "todo"

#native "areas"
native "bars"
native "basic"
native "constraints"
native "pluginexport"
native "fonts"
native "hovers"
native "inputs"
native "minimal"
native "padofcode"
native "padoftext"
native "textandinputs"
#native "todo"
