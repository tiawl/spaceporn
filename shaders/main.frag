#version 450

layout (binding = 0) uniform uniform_buffer_object_vk
{
  float time;
} uniforms;

layout (location = 0) in vec3 frag_color;

layout (location = 0) out vec4 out_color;

void main ()
{
  float time = mod (uniforms.time, 2.0);
  if (time > 1.0)
  {
    time = 2.0 - time;
  }

  out_color = vec4 (time * (1. - frag_color) + (1. - time) * frag_color, 1.0);
}
