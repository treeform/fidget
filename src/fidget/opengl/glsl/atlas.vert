// atlas.vert
#version 410

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec2 vertexUv;
layout(location = 2) in vec4 vertexColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;
uniform mat4 superTrans;

out vec2 uv;
out vec4 color;
out vec2 screen;

void main() {
  uv = vertexUv;
  color = vertexColor;
  screen = vertexPosition.xy;
  gl_Position = proj * vec4(vertexPosition, 1.0);
}
