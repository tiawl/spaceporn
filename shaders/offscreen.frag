#version 450
#extension GL_EXT_debug_printf : enable
// debugPrintfEXT("My float is %f", myfloat);

layout (binding = 0) uniform offscreen_uniform_buffer_object_vk
{
  float seed;
} uniforms;

layout (location = 0) out vec4 out_color;

void main ()
{
  if (uniforms.seed < 0.5)
  {
    out_color = vec4 (0.75, 0.0, 0.0, 1.0);
  } else if (uniforms.seed < 1.5) {
    out_color = vec4 (0.0, 0.75, 0.0, 1.0);
  } else if (uniforms.seed < 2.5) {
    out_color = vec4 (0.0, 0.0, 0.75, 1.0);
  } else if (uniforms.seed < 3.5) {
    out_color = vec4 (0.75, 0.5, 0.0, 1.0);
  } else if (uniforms.seed < 4.5) {
    out_color = vec4 (0.75, 0.0, 0.5, 1.0);
  } else if (uniforms.seed < 5.5) {
    out_color = vec4 (0.5, 0.75, 0.0, 1.0);
  } else if (uniforms.seed < 6.5) {
    out_color = vec4 (0.0, 0.75, 0.5, 1.0);
  } else if (uniforms.seed < 7.5) {
    out_color = vec4 (0.5, 0.0, 0.75, 1.0);
  } else if (uniforms.seed < 8.5) {
    out_color = vec4 (0.0, 0.5, 0.75, 1.0);
  } else {
    out_color = vec4 (0.5, 0.5, 0.5, 1.0);
  }
}
