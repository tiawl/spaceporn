# include "header.glsl"

float pprand(float size, vec2 sizeModifier, vec2 coord, uint noise_seed,
  vec2 center)
{
  coord = mod(coord, sizeModifier * round(size)) + center;
  return hash(coord, noise_seed);
}

float ppnoise(float size, vec2 sizeModifier, vec2 coord, uint noise_seed,
  vec2 center)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);
  f = f * f * (3.0 - 2.0 * f);

  float a = pprand(size, sizeModifier, i, noise_seed, center);
  float b = pprand(size, sizeModifier, i + vec2(1.0, 0.0), noise_seed, center);
  float c = pprand(size, sizeModifier, i + vec2(0.0, 1.0), noise_seed, center);
  float d = pprand(size, sizeModifier, i + vec2(1.0, 1.0), noise_seed, center);

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float ppfbm(float size, vec2 sizeModifier, vec2 coord, uint octaves,
  uint noise_seed, vec2 center)
{
  float value = 0.0;
  float scale = 0.5;

  for(uint i = 0u; i < octaves; i++)
  {
    value += ppnoise(size, sizeModifier, coord, noise_seed, center) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float ppcircleNoise(float size, vec2 sizeModifier, vec2 uv, uint noise_seed,
  vec2 center)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = pprand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)),
    noise_seed, center);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float ppcloud_alpha(float size, vec2 sizeModifier, float time_speed, vec2 uv,
  uint octaves, uint noise_seed, vec2 center)
{
  float c_noise = 0.0;

  int iters = 9;
  for (int i = 0; i < iters; i++)
  {
    c_noise += ppcircleNoise(size, sizeModifier,
      (uv * size * 0.3) + (float(i + 1) + 10.0) +
        (vec2(time * time_speed, 0.0)), noise_seed, center);
  }
  float fbm = ppfbm(size, sizeModifier,
    uv * size + c_noise + vec2(time * time_speed, 0.0), octaves, noise_seed,
    center);

  return fbm;
}

vec2 rotate(vec2 vec, vec2 center, float angle)
{
  vec -= center;
  vec *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
  vec += center;
  return vec;
}

vec2 spherify(vec2 uv, vec2 center, float radius)
{
  vec2 centered = (uv - center) * 2.;
  float z = sqrt(radius * radius * 4. - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}
