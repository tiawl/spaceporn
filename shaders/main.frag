#version 450

layout (binding = 0) uniform uniform_buffer_object_vk
{
  float time;
} uniforms;

layout (binding = 1) uniform sampler2D atlas;

layout (location = 0) out vec4 out_color;

void main ()
{
  vec2 uv = gl_FragCoord.xy / vec2 (800., 600.);
  float time = mod (uniforms.time, 2.0);
  if (time > 1.0)
  {
    time = 2.0 - time;
  }

  if (abs (uv.x) < 0.5 && abs (uv.y) < 0.5)
  {
    out_color = vec4 (vec3 (0.5 + 0.5 * cos (uniforms.time + uv.xyx + vec3 (0., 2., 4.))), 1.);
  } else {
    out_color = texture (atlas, gl_FragCoord.xy / vec2 (512.));
  }
}
