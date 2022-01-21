# include "hash.glsl"
# include "header.glsl"

float sdCircle(vec2 p, float r)
{
  return length(p) - r;
}

float opRing(vec2 p, float r1, float r2)
{
  return abs(sdCircle(p, r1)) - r2;
}

float sdBox(vec2 p, vec2 b )
{
  vec2 d = abs(p) - b;
  return length(max(d, 0.)) + min(max(d.x, d.y), 0.);
}

float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

float ndot(vec2 a, vec2 b)
{
  return a.x * b.x - a.y * b.y;
}

float sdRhombus(vec2 p, vec2 b)
{
  p = abs(p);
  float h = clamp(ndot(b - 2. * p, b) / dot(b, b), -1., 1.);
  float d = length(p - .5 * b * vec2(1. - h, 1. + h));
  return d * sign(p.x * b.y + p.y * b.x - b.x * b.y);
}

float sdBezier(vec2 uv, vec2 A, vec2 B, vec2 C, float strength, float coeff)
{
  // Compute vectors
  vec2 v0 = C - A;
  vec2 v1 = B - A;
  vec2 v2 = uv - A;

  // Compute dot products
  float dot00 = dot(v0, v0);
  float dot01 = dot(v0, v1);
  float dot02 = dot(v0, v2);
  float dot11 = dot(v1, v1);
  float dot12 = dot(v1, v2);

  // Compute barycentric coordinates
  float invDenom = 1. / (dot00 * dot11 - dot01 * dot01);
  float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
  float v = (dot00 * dot12 - dot01 * dot02) * invDenom;

  // use the blinn and loop method
  float w = (1. - u - v);
  vec3 textureCoord = u * vec3(0., 0., 1.) + v * vec3(.5, 0., 1.) / strength
    + w * vec3(1.);

  return sign(textureCoord.x * textureCoord.x * coeff
    - textureCoord.y * textureCoord.z);
}

float psnoise(vec2 coord, uint noise_seed)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash(i, noise_seed);
  float b = hash(i + vec2(1.0, 0.0), noise_seed);
  float c = hash(i + vec2(0.0, 1.0), noise_seed);
  float d = hash(i + vec2(1.0, 1.0), noise_seed);

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float psfbm(vec2 coord, uint octaves, uint noise_seed)
{
  float value = 0.0;
  float scale = 0.5;

  for (uint i = 0u; i < octaves; i++)
  {
    value += psnoise(coord, noise_seed) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float pscircleNoise(vec2 uv, uint noise_seed)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = hash(vec2(floor(uv.x), floor(uv_y)), noise_seed);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float pscloud_alpha(vec2 uv, uint octaves, uint noise_seed)
{
  float c_noise = 0.0;

  int iters = 2;
  for (int i = 0; i < iters; i++)
  {
    c_noise +=
      pscircleNoise(uv * 0.5 + (float(i + 1)) + vec2(-0.3, 0.0), noise_seed);
  }
  float fbm = psfbm(uv + c_noise, octaves, noise_seed);

  return fbm;
}
