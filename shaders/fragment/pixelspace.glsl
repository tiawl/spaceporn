#include "header.glsl"

float psrand(vec2 coord)
{
  return fract(43757.5453 * sin(dot(coord, vec2(12.9898, 78.233))));
}

float psnoise(vec2 coord)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = psrand(i);
  float b = psrand(i + vec2(1.0, 0.0));
  float c = psrand(i + vec2(0.0, 1.0));
  float d = psrand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) + (c - a) * cubic.y *
    (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float psfbm(vec2 coord, uint octaves)
{
  float value = 0.0;
  float scale = 0.5;

  for(uint i = 0u; i < octaves; i++)
  {
    value += psnoise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float pscircleNoise(vec2 uv)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = psrand(vec2(floor(uv.x), floor(uv_y)));
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float pscloud_alpha(vec2 uv, uint octaves)
{
  float c_noise = 0.0;

  int iters = 2;
  for (int i = 0; i < iters; i++)
  {
    c_noise += pscircleNoise(uv * 0.5 + (float(i + 1)) + vec2(-0.3, 0.0));
  }
  float fbm = psfbm(uv + c_noise, octaves);

  return fbm;
}
