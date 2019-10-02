// let nodeCount = 0
// const nodeTypeCounts: Map<NodeType, number> = new Map

function q(str: string) {
  return JSON.stringify(str)
}

function titleCase(str) {
  str = str.toLowerCase().split(' ');
  for (var i = 0; i < str.length; i++) {
    str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
  }
  return str.join(' ');
}

function toHtmlColor(color){
 return "#" +
  ("0" + (color.r*255).toString(16)).slice(-2) +
  ("0" + (color.g*255).toString(16)).slice(-2) +
  ("0" + (color.b*255).toString(16)).slice(-2) ;
}

var text = ""
var indent = 0


function ind() {
  return "  ".repeat(indent)
}

function visitFill(fill) {
  // text += ind() + `fill color(${fill.color.r}, ${fill.color.g}, ${fill.color.b}, ${fill.opacity})\n`
  if(fill.color != undefined){
    if(fill.opacity != 1) {
      text += ind() + `fill ${JSON.stringify(toHtmlColor(fill.color))}, ${fill.opacity}\n`
    } else {
      text += ind() + `fill ${JSON.stringify(toHtmlColor(fill.color))}\n`
    }
  }
}

function visit(node) {
  text += ind() + node.type.toLowerCase() + " \"" + node.name + "\":\n"
  indent += 1

  //text += ind() + `relativeTransform ${node.relativeTransform}\n`
  text += ind() + `box ${node.x}, ${node.y}, ${node.width}, ${node.height}\n`

  if (node.constraints) {
    text += ind() + `constraints c${titleCase(node.constraints.horizontal)}, c${titleCase(node.constraints.vertical)}\n`
  }

  if (node.type == "INSTANCE"){
    text += ind() + `image ${q(node.name + ".png")}\n`
    indent -= 1
    return
  }

  //text += ind() + `exportSettings ${node.exportSettings}\n`

  if (node.type == "FRAME"){
    for(let fill of node.backgrounds){
      visitFill(fill)
    }
  }

  if(node.fills != undefined && node.fills != figma.mixed){
    for(let fill of node.fills){
      visitFill(fill)
    }
  }

  if (node.type == "TEXT"){

    // text += ind() + "textAlignHorizontal h" + titleCase(node.textAlignHorizontal) + "\n"
    // text += ind() + "textAlignVertical v" + titleCase(node.textAlignVertical) + "\n"

    // if (node.textStyleId) {
    //   text += ind() + "textStyleId " + node.textStyleId + "\n"
    // } else {
    //   text += ind() + "fontSize " + node.fontSize + "\n"
    //   text += ind() + "fontName \"" + node.fontName.family + " " + node.fontName.style + "\"\n"
    // }

    let fontFamily = JSON.stringify(node.fontName.family + " " + node.fontName.style)
    var lineHeight = 0
    if (node.lineHeight.unit == "PIXELS"){
      lineHeight = node.lineHeight.value
    }
    //text += ind() + `lineHeight ${node.lineHeight.unit} ${node.lineHeight.value}\n`
    var h = 0
    if (node.textAlignHorizontal == "LEFT") h = -1
    if (node.textAlignHorizontal == "RIGHT") h = 1
    var v = 0
    if (node.textAlignVertical == "TOP") h = -1
    if (node.textAlignVertical == "BOTTOM") h = 1
    text += ind() + `font ${fontFamily}, ${node.fontSize}, 200, ${lineHeight}, ${h}, ${v}\n`

    text += ind() + "characters " + JSON.stringify(node.characters) + "\n"
  }

  if (node.children) node.children.forEach(visit)
  indent -= 1

}

for(const node of figma.currentPage.selection ){
  indent = 0
  visit(node)
  text += "\n"
}

figma.showUI(`
  <span style="white-space:pre-wrap;font-family:monospace">${text}</span>
`, {width: 500, height: 600})
