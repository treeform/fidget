
function q(str: string): string {
  return JSON.stringify(str)
}

function titleCase(str) {
  str = str.toLowerCase().split(' ');
  for (var i = 0; i < str.length; i++) {
    str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
  }
  return str.join(' ');
}

function toHtmlColor(color): string {
  return "#" +
  ("0" + (Math.floor(color.r*255.5)).toString(16)).slice(-2) +
  ("0" + (Math.floor(color.g*255.5)).toString(16)).slice(-2) +
  ("0" + (Math.floor(color.b*255.5)).toString(16)).slice(-2) ;
}

let fontStyleMapping = {
  Thin: 100,
  ThinItalic: 100,
  ExtraLight: 200,
  ExtraLightItalic: 200,
  Light: 300,
  LightItalic: 300,
  Regular: 400,
  RegularItalic: 400,
  Medium: 500,
  MediumItalic: 500,
  SemiBold: 600,
  SemiBoldItalic: 600,
  Bold: 700,
  BoldItalic: 700,
  ExtraBold: 800,
  ExtraBoldItalic: 800,
  Black: 900,
  BlackItalic: 900,
}

var text = ""
var indent = 0
var at = {x:0, y:0}
var atStack = []

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

function visitStroke(fill) {
  // text += ind() + `fill color(${fill.color.r}, ${fill.color.g}, ${fill.color.b}, ${fill.opacity})\n`
  if(fill.color != undefined){
    if(fill.opacity != 1) {
      text += ind() + `stroke ${JSON.stringify(toHtmlColor(fill.color))}, ${fill.opacity}\n`
    } else {
      text += ind() + `stroke ${JSON.stringify(toHtmlColor(fill.color))}\n`
    }
  }
}

function visitEffect(effect: Effect) {
  // text += ind() + JSON.stringify(effect) + "\n"
  if (effect.type == "DROP_SHADOW" && effect.visible) {
    text += ind() + `dropShadow ${effect.radius}, ${effect.offset.x}, ${effect.offset.y}, ${JSON.stringify(toHtmlColor(effect.color))}, ${effect.color.a}\n`
  } else if (effect.type == "INNER_SHADOW" && effect.visible) {
    text += ind() + `innerShadow ${effect.radius}, ${effect.offset.x}, ${effect.offset.y}, ${JSON.stringify(toHtmlColor(effect.color))}, ${effect.color.a}\n`
  }
}

function visit(node) {

  if(!node.visible){
    return
  }

  text += ind() + node.type.toLowerCase() + " \"" + node.name + "\":\n"
  indent += 1

  //text += ind() + `# relativeTransform ${node.relativeTransform}\n`
  //text += ind() + `# ${node.x} ${node.y}\n`
  text += ind() + `box ${node.x-at.x}, ${node.y-at.y}, ${node.width}, ${node.height}\n`


  if (node.constraints) {
    text += ind() + `constraints c${titleCase(node.constraints.horizontal)}, c${titleCase(node.constraints.vertical)}\n`
  }

  if (node.type == "INSTANCE"){
    text += ind() + `image ${q(node.name + ".png")}\n`
    indent -= 1
    return
  }

 if (node.exportSettings.length > 0){
    // text += ind() + `exportSettings ${JSON.stringify(node.exportSettings)}\n`
    text += ind() + `image ${q(node.name + ".png")}\n`
    indent -= 1
    return
  }

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

  if(node.strokes != undefined && node.strokes != figma.mixed){
    for(let stroke of node.strokes){
      visitStroke(stroke)
    }
  }

  if(node.cornerRadius != undefined && node.cornerRadius != figma.mixed){
    if (node.cornerRadius != 0){
      text += ind() + `cornerRadius ${node.cornerRadius}\n`
    }
  }

  if(node.strokeWeight != undefined) {
    if (node.strokeWeight != 0 && node.strokes.length != 0) {
      text += ind() + `strokeWeight ${node.strokeWeight}\n`
    }
  }


  if(node.effects != undefined){
    for(let effect of node.effects){
      visitEffect(effect)
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

    console.log(node)
    console.log(node.lineHeight)

    let fontFamily = JSON.stringify(node.fontName.family)
    var lineHeight = 0
    if (node.lineHeight.unit == "PIXELS"){
      lineHeight = node.lineHeight.value
    }
    let fontWeight = fontStyleMapping[node.fontName.style]

    //text += ind() + "???" + JSON.stringify(node.getRangeLineHeight(0, 1)) + "\n"
    //text += ind() + `lineHeight ${node.lineHeight.unit} ${node.lineHeight.value}\n`

    var h = 0
    if (node.textAlignHorizontal == "LEFT") h = -1
    if (node.textAlignHorizontal == "RIGHT") h = 1
    var v = 0
    if (node.textAlignVertical == "TOP") v = -1
    if (node.textAlignVertical == "BOTTOM") v = 1
    text += ind() + `font ${fontFamily}, ${node.fontSize}, ${fontWeight}, ${lineHeight}, ${h}, ${v}\n`

    text += ind() + "characters " + JSON.stringify(node.characters) + "\n"
  }

  if (node.children) {
    if(node.type == "GROUP"){
      atStack.push({x:at.x, y:at.y})
      at.x = node.x
      at.y = node.y
    }

    node.children.forEach(visit)

    if(node.type == "GROUP"){
      at = atStack.pop()
    }
  }
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
