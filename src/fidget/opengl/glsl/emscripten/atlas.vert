#version 100

precision highp float;

attribute vec2 vertexPos;
attribute vec2 vertexUv;
attribute vec4 vertexColor;

uniform mat4 proj;

varying vec2 pos;
varying vec2 uv;
varying vec4 color;

void main() {
  pos = vertexPos;
  uv = vertexUv;
  color = vertexColor;
  gl_Position = proj * vec4(vertexPos, 0.0, 1.0);
}
