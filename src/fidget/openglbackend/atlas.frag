#version 410

precision mediump float;

in vec2 uv;
in vec4 color;
out vec4 fragColor;

uniform sampler2D rgbaTex;

void main() {
  fragColor = texture(rgbaTex, uv).rgba * color;
  // if (fragColor.a < 0.5) {
  //   fragColor.a = 0.5;
  // }
}
