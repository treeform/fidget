// atlas.frag
#version 410
precision mediump float;

in vec2 uv;
in vec4 color;
in vec2 screen;
out vec4 fragColor;

uniform vec2 windowFrame;

uniform sampler2D rgbaTex;
uniform sampler2D rgbaMask;

void main() {
  fragColor = texture(rgbaTex, uv).rgba * color;
  vec2 s = windowFrame;
  fragColor.a *= texture(rgbaMask, vec2(screen.x/s.x, 1 - screen.y/s.y)).a;
}
