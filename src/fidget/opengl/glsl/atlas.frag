#version 410

in vec2 pos;
in vec2 uv;
in vec4 color;

uniform vec2 windowFrame;
uniform sampler2D atlasTex;
uniform sampler2D maskTex;

out vec4 fragColor;

void main() {
  fragColor = texture(atlasTex, uv).rgba * color;
  vec2 normalizedPos = vec2(pos.x / windowFrame.x, 1 - pos.y / windowFrame.y);
  fragColor.a *= texture(maskTex, normalizedPos).r;
}
