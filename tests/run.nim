import cligen, os, strformat

let examplesDir = getCurrentDir()

var runList: seq[string]

proc compileNative() =
  for folder in runList:
    let file = folder.lastPathPart
    let cmd = &"nim c --hints:off --verbosity:0 {folder}/{file}.nim"
    echo cmd
    if execShellCmd(cmd) != 0:
      quit "[error] " & folder
    else:
      echo "[ok] " & folder

proc compileTestOneFrame() =
  for folder in runList:
    let file = folder.lastPathPart
    let cmd = &"nim c --hints:off --verbosity:0 -d:testOneFrame {folder}/{file}.nim"
    echo cmd
    if execShellCmd(cmd) != 0:
      quit "[error] " & folder
    else:
      echo "[ok] " & folder

proc runNative() =
  for folder in runList:
    setCurrentDir(folder)
    let exeUrl = folder.lastPathPart
    when defined(windows):
      if execShellCmd(exeUrl & ".exe") != 0:
        quit "[error] Starting " & exeUrl & ".exe"
    else:
      if execShellCmd(exeUrl) != 0:
        quit "[error] Starting " & exeUrl
    setCurrentDir(examplesDir)

proc compileJS() =
  for folder in runList:
    let file = folder.lastPathPart
    let cmd = &"nim js --hints:off --verbosity:0 {folder}/{file}.nim"
    echo cmd
    if execShellCmd(cmd) != 0:
      quit "[error] " & folder
    else:
      echo "[ok] " & folder
    # write html file
    let(dir, name, _) = folder.splitFile
    let indexPath = &"{dir}/{name}/{name}.html"
    writeFile(indexPath, &"""<script src="{name}.js"></script>""")

proc runJS() =
  for folder in runList:
    let file = folder.lastPathPart
    var exeDir = os.getAppDir().parentDir
    let fileUrl = &"file:///{exeDir}/{folder}/{file}.html"
    when defined(windows):
      if execShellCmd(&"start chrome {fileUrl}") != 0:
        quit "[error] Starting Chrome: " & fileUrl
    else:
      if execShellCmd(&"open {fileUrl}") != 0:
        quit "[error] Starting Chrome: " & fileUrl

proc compileWasm() =
  for folder in runList:
    let file = folder.lastPathPart
    if not existsDir(folder / "wasm"):
      createDir(folder / "wasm")
    echo folder / "data"
    let inner =
      if existsDir(folder / "data"):
        echo "using data folder"
        &"-o {folder}/wasm/{file}.html --preload-file {folder}/data@data/ --shell-file src/shell_minimal.html -s ALLOW_MEMORY_GROWTH=1"
      else:
        &"-o {folder}/wasm/{file}.html --shell-file src/shell_minimal.html -s ALLOW_MEMORY_GROWTH=1"
    let cmd = &"nim c -d:emscripten --gc:arc --hints:off --verbosity:0 --passL:\"{inner}\" {folder}/{file}.nim"
    echo cmd
    if execShellCmd(cmd) != 0:
      quit "[error] " & folder

proc runWasm() =
  for folder in runList:
    let file = folder.lastPathPart
    var exeDir = os.getAppDir().parentDir
    let fileUrl = &"http://localhost:1337/{folder}/wasm/{file}.html"
    when defined(windows):
      if execShellCmd(&"start chrome {fileUrl}") != 0:
        quit "[error] Starting Chrome: " & fileUrl
    else:
      if execShellCmd(&"open {fileUrl}") != 0:
        quit "[error] Starting Chrome: " & fileUrl

proc runClean() =
  for folder in runList:
    if existsDir(folder / "wasm"):
      removeDir(folder / "wasm")
    let file = folder.lastPathPart
    if existsFile(folder / file & ".html"):
      removeFile(folder / file & ".html")
    if existsFile(folder / file & ".js"):
      removeFile(folder / file & ".js")
    if existsFile(folder / file & ".exe"):
      removeFile(folder / file & ".exe")

proc main(
  compile: bool = false,
  native: bool = false,
  js: bool = false,
  run: bool = false,
  wasm: bool = false,
  clean: bool = false,
  testOneFrame: bool = false,
) =

  if not wasm:
    runList.add "tests/httpget"
    runList.add "examples/hn"

  if not js:
    runList.add "tests/imagegen"
    runList.add "tests/imagestatic"

  runList.add "tests/autolayouttext"
  runList.add "tests/autolayoutcomplex"
  runList.add "tests/autolayouthorizontal"
  runList.add "tests/autolayoutvertical"
  runList.add "tests/bars"
  runList.add "tests/constraints"
  runList.add "tests/exportorder"
  runList.add "tests/fontmetrics"
  runList.add "tests/hovers"
  runList.add "tests/images"
  runList.add "tests/inputtoggle"
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

  if not(compile or native or js or run or wasm or clean):
    echo "Usage:"
    echo "  run --compile --native --js --run"

  if compile and native:
    if testOneFrame:
      compileTestOneFrame()
    else:
      compileNative()
  if run and native:
    runNative()
  if compile and js:
    compileJS()
  if run and js:
    runJS()
  if compile and wasm:
    compileWasm()
  if run and wasm:
    runWasm()
  if clean:
    runClean()

  if testOneFrame:
    let (outp, _) = execCmdEx("git diff *.png")
    if len(outp) != 0:
      echo outp
      quit("Output does not match")

dispatch(main)
