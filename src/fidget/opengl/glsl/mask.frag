#version 410

in vec2 pos;
in vec2 uv;
in vec4 color;

uniform sampler2D rgbaTex;

out vec4 fragColor;

void main() {
  fragColor = texture(rgbaTex, uv).rgba * color;
}
