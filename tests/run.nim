import os, strformat, cligen;

let examplesDir = getCurrentDir()

var runList: seq[string]

proc compileNative() =
  for folder in runList:
    let file = folder.lastPathPart
    let cmd = &"nim c --hints:off --verbosity:0 {folder}/{file}.nim"
    echo cmd
    if execShellCmd(cmd) != 0:
      echo "[error] ", folder
      quit(1)
    else:
      echo "[ok] ", folder

proc runNative() =
  for folder in runList:
    setCurrentDir(".." / folder)
    let exeUrl = folder.lastPathPart
    if execShellCmd(exeUrl) != 0:
      echo "[error] Starting ", exeUrl
      quit()
    setCurrentDir(examplesDir)

proc compileJS() =
  for folder in runList:
    let file = folder.lastPathPart
    let cmd = &"nim js --hints:off --verbosity:0 -d:genhtml {folder}/{file}.nim"
    echo cmd
    if execShellCmd(cmd) != 0:
      echo "[error] ", folder
      quit()
    else:
      echo "[ok] ", folder

proc runJS() =
  for folder in runList:
    let file = folder.lastPathPart
    var exeDir = os.getAppDir().parentDir
    let fileUrl = &"file:///{exeDir}/{folder}/{file}.html"
    when defined(windows):
      if execShellCmd(&"start chrome {fileUrl}") != 0:
        echo "[error] Starting Chrome: ", fileUrl
        quit()
    when defined(osx):
      echo "here"
      if execShellCmd(&"open {fileUrl}") != 0:
        echo "[error] Starting Chrome: ", fileUrl
        quit()

proc genHTML() =
  for folder in runList:
    ## Writes the needed index.html file.
    let
      (dir, name, extension) = folder.splitFile
    let indexPath = &"{dir}/{name}/{name}.html"
    writeFile(indexPath, &"""<html>
<head>
<script src="{name}.js"></script>
</head>
<body></body>
</html>""")

proc main(
  compile: bool = false,
  native: bool = false,
  js: bool = false,
  run: bool = false,
  genhtml: bool = false,
) =
  runList.add "tests/autolayoutcomplex"
  runList.add "tests/autolayouthorizontal"
  runList.add "tests/autolayouttext"
  runList.add "tests/autolayoutvertical"
  runList.add "tests/bars"
  runList.add "tests/constraints"
  runList.add "tests/exportorder"
  runList.add "tests/fontmetrics"
  runList.add "tests/hovers"
  runList.add "tests/images"
  runList.add "tests/inputs"
  runList.add "tests/inputsandoutputs"
  runList.add "tests/inputtest"
  runList.add "tests/masks"
  runList.add "tests/pixelscaling"
  runList.add "tests/pluginexport"
  runList.add "tests/textalign"
  runList.add "tests/textalignexpand"
  runList.add "tests/textalignfixed"
  runList.add "tests/textandinputs"

  runList.add "examples/areas"
  runList.add "examples/demo"
  runList.add "examples/minimal"
  runList.add "examples/padofcode"
  runList.add "examples/padoftext"
  # TODO: finish runList.add "examples/todo"

  if not(compile or native or js or run):
    echo "Usage:"
    echo "  run --compile --native --js --run"

  if compile and native:
    compileNative()
  if run and native:
    runNative()
  if compile and js:
    compileJS()
  if run and js:
    runJS()
  if genhtml:
    genHTML()
  # compileWasm()
  # runWasm()


dispatch(main)
