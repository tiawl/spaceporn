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

float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

float smin(float a, float b, float k, uint p)
{
    float h = max(k - abs(a - b), 0.) / k;
    float H = 1.;
    while (p > 0u)
    {
      H *= h;
      p -= 1u;
    }
    return min(a, b) - H * k * (1. /4.);
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
