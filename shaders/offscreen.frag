#version 450

layout (binding = 0) uniform offscreen_uniform_buffer_object_vk
{
  float blue;
} uniforms;

layout (location = 0) out vec4 out_color;

void main ()
{
  out_color = vec4 (0.0, 0.75, uniforms.blue, 1.0);
}
