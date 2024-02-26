#version 450
#extension GL_EXT_debug_printf : enable
// debugPrintfEXT("My float is %f", myfloat);

layout (binding = 0) uniform offscreen_uniform_buffer_object_vk
{
  uint seed;
} uniforms;

layout (location = 0) out vec4 out_color;

// 3D hash function to simulate seeding:
// https://www.shadertoy.com/view/XlGcRh
uvec3 pcg3d (uvec3 v)
{
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return v;
}

// https://www.shadertoy.com/view/XlGcRh
float hash (vec2 s, uint hash_seed)
{
  float res;
  uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
  uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
  res = float(p) * (1. / float(0xffffffffu));
  return res;
}

void main ()
{
  out_color = vec4 (vec3 (hash (gl_FragCoord.xy / 200, uniforms.seed)), 1.0);
}
