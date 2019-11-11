// atlas.es.vert
precision mediump float;

attribute vec3 vertexPosition;
attribute vec2 vertexUv;
attribute vec4 vertexColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;
uniform mat4 superTrans;

varying vec2 uv;
varying vec4 color;

void main() {
  uv = vertexUv;
  color = vertexColor;
  gl_Position = proj * vec4(vertexPosition, 1.0);
}
