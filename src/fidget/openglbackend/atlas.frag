// atlas.frag
#version 410

precision mediump float;

in vec2 uv;
in vec4 color;
in vec2 screen;
out vec4 fragColor;

uniform vec2 screenSize;
uniform vec2 textureSize;

uniform sampler2D rgbaTex;
uniform sampler2D rgbaMask;

void main() {
  // fragColor = texture(rgbaTex, uv).rgba * color;
  // ivec2 s = textureSize2D(rgbaMask, 0);
  // if (screen.x < s.x && screen.y < s.y) {
  //   fragColor.a *= texture(rgbaMask, screen/s).r;
  // } else {
  //   fragColor.a = 0;
  // }

  fragColor = texture(rgbaTex, uv).rgba * color;
  vec2 s = textureSize; // textureSize2D(rgbaMask, 0);
  fragColor.a *= texture(rgbaMask, vec2(screen.x/s.x, 1 - screen.y/s.y)).a;
}
