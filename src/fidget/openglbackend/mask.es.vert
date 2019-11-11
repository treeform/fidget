// mask.es.vert
#version 300

attribute vec3 vertexPosition;
attribute vec2 vertexUv;
attribute vec4 vertexColor;

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
