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

float hash(vec2 s, uint hash_seed)
{
  float res;
  uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
  uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
  res = float(p) * (1.0 / float(0xffffffffu));
  return res;
}

float smax(float a, float b, float k)
{
  float h = max(k - abs(a - b), 0.);
  return max(a, b) + h * h * 0.25 / k;
}

float voronoi(vec2 UV, float smoothness, uint seed)
{
  vec3 col;
  vec2 i = floor(UV);
  vec2 f = fract(UV);
  vec2 displacement;
  vec2 p;

  float dist = 8.;
  float tmp;
  float h;

  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      p = vec2(x, y);
      displacement = vec2(hash(i + p, seed), hash(i + p, seed + 1u));
      tmp = length(p + displacement - f);

      col = 0.5 + 0.5 * sin(hash(i + p, seed + 2u) * 2.5 + 3.5 + vec3(2.));
      h = smoothstep(0., 1., 0.5 + 0.5 * (dist - tmp) / smoothness);
      dist = mix(dist, tmp, h) - h * (1. - h) * smoothness / (1. + 3. * smoothness);
    }
  }
  return 1. - dist;
}

float circles(vec2 UV, float r, uint seed)
{
  vec2 center = round(UV);
  vec2 cell_center;
  vec2 displacement;
  float radius;
  float dist = 0.0;

  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      cell_center = center + vec2(x, y);
      displacement = vec2(hash(cell_center, seed), hash(cell_center, seed + 1u)) - vec2(0.5);
      radius = r / 2.0 + hash(cell_center, seed + 2u) * r;
      dist = smax(dist, radius - length(UV + displacement - cell_center), 0.3);
    }
  }

  return dist;
}

float fbmCircles(vec2 UV, uint seed)
{
  float strength = 1.;
  float new;
  float dist = -1.;
  uint octaves = 2u;
  for (uint i = 0u; i < octaves; i++)
  {
    // Evaluate new octave
    new = strength * circles(UV, 0.5, seed + i);

    // Add
    dist = smax(dist, new, 0.3 * strength);

    // Prepare new octave
    UV *= 2.;
    strength *= 0.5;
  }
  return dist;
}

float fbmVoronoi(vec2 UV, uint seed)
{
  return voronoi(1.5 * UV, 0.3, seed) * 0.625      // first octave
    + voronoi(3. * UV, 0.3, seed + 1u) * 0.25     // second octave
    + voronoi(6. * UV, 0.3, seed + 2u) * 0.125;  // third octave
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord / iResolution.y;
  vec2 UV = 10.0 * uv;

  float dist = max(fbmCircles(UV, 0u), fbmCircles(UV, 5u));

  float fv = fbmVoronoi(uv, 2u);
  fv *= fv * 1.5;
  dist = smax(-1., dist, 3.2);
  dist = floor(dist * fv * 18.) / 18.;
  fragColor = vec4(vec3(dist), 1.0);
}
