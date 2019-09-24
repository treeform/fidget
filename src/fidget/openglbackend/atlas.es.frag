precision mediump float;

varying vec2 uv;
varying vec4 color;

uniform sampler2D rgbaTex;

void main() {
  gl_FragColor = texture2D(rgbaTex, uv).rgba * color;
  //gl_FragColor += vec4(1,1,1,1);
}
