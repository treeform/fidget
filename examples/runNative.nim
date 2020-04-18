import os, strformat

let examplesDir = getCurrentDir()

proc compile(folder: string) =
  if execShellCmd(&"nim c {folder}/{folder}.nim") != 0:
    echo "[error] ", folder
    quit()
  else:
    echo "[ok] ", folder

proc run(folder: string) =
  setCurrentDir(folder)
  let exeUrl = &"{folder}"
  if execShellCmd(exeUrl) != 0:
    echo "[error] Starting ", exeUrl
    quit()
  setCurrentDir(examplesDir)


compile "areas"
compile "bars"
compile "demo"
compile "constraints"
compile "pluginexport"
compile "textalign"
compile "hovers"
compile "inputs"
compile "minimal"
compile "padofcode"
compile "padoftext"
compile "textandinputs"


run "areas"
run "bars"
run "demo"
run "constraints"
run "pluginexport"
run "textalign"
run "hovers"
run "inputs"
run "minimal"
run "padofcode"
run "padoftext"
run "textandinputs"

# TODO: finish
# native "todo"

echo "success"
