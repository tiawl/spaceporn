# include "header.glsl"

float pprand(float size, vec2 sizeModifier, vec2 coord, uint noise_seed)
{
  coord = mod(coord, sizeModifier * round(size));
  return hash(coord, noise_seed);
}

float ppnoise(float size, vec2 sizeModifier, vec2 coord, uint noise_seed)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = pprand(size, sizeModifier, i, noise_seed);
  float b = pprand(size, sizeModifier, i + vec2(1.0, 0.0), noise_seed);
  float c = pprand(size, sizeModifier, i + vec2(0.0, 1.0), noise_seed);
  float d = pprand(size, sizeModifier, i + vec2(1.0, 1.0), noise_seed);

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) + (c - a) * cubic.y *
    (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float ppfbm(float size, vec2 sizeModifier, vec2 coord, uint octaves,
  uint noise_seed)
{
  float value = 0.0;
  float scale = 0.5;

  for(uint i = 0u; i < octaves; i++)
  {
    value += ppnoise(size, sizeModifier, coord, noise_seed) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float ppcircleNoise(float size, vec2 sizeModifier, vec2 uv, uint noise_seed)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h =
    pprand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)), noise_seed);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float ppcloud_alpha(float size, vec2 sizeModifier, float time_speed, vec2 uv,
  uint octaves, uint noise_seed)
{
  float c_noise = 0.0;

  int iters = 9;
  for (int i = 0; i < iters; i++)
  {
    c_noise += ppcircleNoise(size, sizeModifier,
      (uv * size * 0.3) + (float(i + 1) + 10.0) +
        (vec2(time * time_speed, 0.0)), noise_seed);
  }
  float fbm = ppfbm(size, sizeModifier,
    uv * size + c_noise + vec2(time * time_speed, 0.0), octaves, noise_seed);

  return fbm;
}
