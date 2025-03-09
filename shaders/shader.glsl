@header package shaders
@header import sg "../sokol-odin/sokol/gfx"

@vs vs

in vec2 pos;
in vec4 col;

out vec4 color;

void main () {
  gl_Position = vec4(pos, 0, 1);
  color = col;
}
@end

@fs fs
in vec4 color;
out vec4 frag_color;

void main () {
  frag_color = color;
}
@end

@program main vs fs
