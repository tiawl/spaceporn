#version 450

layout (location = 0) in vec3 frag_color;

layout (location = 0) out vec4 out_color;

void main ()
{
  out_color = vec4 (0.0, 0.75, 0.5, 1.0);
}
