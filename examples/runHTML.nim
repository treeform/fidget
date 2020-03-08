import os, strformat

proc javaScript(folder: string) =
  if execShellCmd(&"nim js {folder}/{folder}.nim") != 0:
    echo "[error] ", folder
    quit()
  else:
    echo "[ok] ", folder

    var exeDir = os.getAppDir()
    let fileUrl = &"file:///{exeDir}/{folder}/{folder}.html"
    if execShellCmd(&"start chrome {fileUrl}") != 0:
      echo "[error] Starting Chrome: ", fileUrl
      quit()

javaScript "areas"
javaScript "bars"
javaScript "demo"
javaScript "constraints"
javaScript "pluginexport"
javaScript "textalign"
javaScript "hovers"
javaScript "inputs"
javaScript "minimal"
javaScript "padofcode"
javaScript "padoftext"
javaScript "textandinputs"
javaScript "todo"
