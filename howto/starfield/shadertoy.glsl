uvec3 pcg3d(uvec3 v)
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
float hash(vec2 s, uint hash_seed)
{
  float res;
  uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
  uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
  res = float(p) * (1. / float(0xffffffffu));
  return res;
}

float circles(vec2 p, float r, uint s)
{
  vec2 i = floor(p), f = fract(p), h, a;

  float d = 0., c, rad;
  for(int k = 0; k < 9; k++)
  {
    p = vec2(k % 3, k / 3) - 1.;
    rad = 0.2 + hash(i + p, s + 2u) * r;
    h = vec2(hash(i + p, s + 89u), hash(i + p, s + 52u));

    p += h - f;

    c = step(length(p), rad);// - rad;
    d = max(d, c);//smin(d, c, 0.3);
  }
  return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 UV = fragCoord / iResolution.y;
  float g = step(length(UV), 0.5);
  fragColor = vec4(vec3(circles(10. * UV, 0.5, 1u)), 1.);
}
