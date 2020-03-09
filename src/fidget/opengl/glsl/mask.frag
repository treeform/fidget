// mask.frag
#version 410

#extension GL_EXT_gpu_shader4 : enable

precision mediump float;

in vec2 uv;
in vec4 color;
in vec2 screen;
layout(location = 0) out vec4 fragColor;

uniform sampler2D rgbaTex;

void main() {
  fragColor = texture(rgbaTex, uv).rgba * color;
}
