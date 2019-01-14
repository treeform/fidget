## Performs a treeway merge of
## Generated UI file
## Prevously Genrated UI file
## Real UI file with custom Midifications

import strutils, print

type Node = ref object
  indent: int
  line: string
  kids: seq[Node]
  used: bool


proc countIndent(line: string): int =
  for i in 0..100:
    if i >= line.len or line[i] != ' ':
      return i


proc toTree(fileName: string): Node =
  var lines = readFile(fileName).splitLines()
  result = Node()
  result.indent = -1
  var nodeStack = newSeq[Node]()
  nodeStack.add result

  for line in lines:
    var lineNode = Node()
    lineNode.line = line.strip()
    lineNode.indent = countIndent(line)

    if lineNode.line == "":
      lineNode.indent = nodeStack[^1].indent
      nodeStack[^1].kids.add(lineNode)
      continue

    while nodeStack[^1].indent >= lineNode.indent:
      discard nodeStack.pop()

    if nodeStack[^1].indent < lineNode.indent:
      nodeStack[^1].kids.add(lineNode)
      nodeStack.add lineNode



proc `$`(node: Node): string =
  if node.indent != -1:
    if node.line.len != 0:
      for i in 0..<(node.indent):
        result.add ' '
      result.add node.line
    result.add '\n'
  if node.kids.len > 0:
    for kid in node.kids:
      result.add $kid


var
  oldTree = toTree("fidget/generated.old.nim")
  newTree = toTree("fidget/generated.new.nim")
  userTree = toTree("fidget/combined.nim")


proc subDiff(userTree, oldTree, newTree: Node) =
  for userNode in userTree.kids:
    var
      foundOldIdx: int
      foundNewIdx: int

      foundOldNode: Node
      foundNewNode: Node

    # look for old line that matches user line
    for i, oldNode in oldTree.kids:
      if userNode.line == oldNode.line:
        foundOldNode = oldNode
        foundOldIdx = i
        break

    # look for new line that matches user line
    for i, newNode in newTree.kids.mpairs:
      if userNode.line == newNode.line:
        foundNewNode = newNode
        foundNewIdx = i
        break

    if foundOldNode != nil and foundNewNode != nil:
      # if no changes, go down the tree
      subDiff(userNode, foundOldNode, foundNewNode)
      foundNewNode.used = true

    elif foundOldNode != nil and foundNewNode == nil:
      # a normal change happend, old == user, but new is different
      userNode.line = newTree.kids[foundOldIdx].line
      newTree.kids[foundOldIdx].used = true

    elif foundOldNode == nil and foundNewNode != nil:
      # both user and figam added some thing (rare)
      foundNewNode.used = true
    else:
      # used edited stuff (normal), keep user changes
      print "keep", userNode.line
      discard

  var prevUsedIdx = 0
  for i, newNode in newTree.kids:
    if newNode.used:
      prevUsedIdx = i
    else:
      for i, oldNode in oldTree.kids.mpairs:
        if newNode.line == oldNode.line:
          newNode.used = true
          break
      if not newNode.used:
        # new stuff got added
        print "prev", newTree.kids[prevUsedIdx].line
        print "add ", newNode.line
        userTree.kids.insert(newNode, prevUsedIdx + 1)

subDiff(userTree, oldTree, newTree)

#echo userTree
var text = $(userTree)
writeFile("fidget/combined.nim", text.strip() & '\n')