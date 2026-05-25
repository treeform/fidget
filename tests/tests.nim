import os

let command = "nim c -r tests/run.nim --compile --native --js"
echo command
if execShellCmd(command) != 0:
  quit "tests failed"
