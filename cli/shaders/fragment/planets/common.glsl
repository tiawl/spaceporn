# include "common.glsl"
# include "hash.glsl"

struct Planet
{
  uint type;
  vec2 center;
  float rotation;
  float radius;
  float time_speed;
  float plan;
  vec2 light_origin;
  uint turbulence;
  float ring;
  float ring_a;
  float cloud_cover;
  float cloud_stretch;
};

float pprand(float size, vec2 sizeModifier, vec2 coords, uint noise_seed,
  vec2 center)
{
  coords = mod(coords, sizeModifier * round(size)) + center;
  return hash(coords, noise_seed);
}

float ppnoise(float size, vec2 sizeModifier, vec2 coords, uint noise_seed,
  vec2 center)
{
  vec2 i = floor(coords);
  vec2 f = fract(coords);
  f = f * f * (3. - 2. * f);

  float a = pprand(size, sizeModifier, i, noise_seed, center);
  float b = pprand(size, sizeModifier, i + vec2(1., 0.), noise_seed, center);
  float c = pprand(size, sizeModifier, i + vec2(0., 1.), noise_seed, center);
  float d = pprand(size, sizeModifier, i + vec2(1.), noise_seed, center);

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float ppfbm(float size, vec2 sizeModifier, vec2 coords, uint octaves,
  uint noise_seed, vec2 center)
{
  float value = 0.;
  float scale = 0.5;

  for (uint i = 0u; i < octaves; i++)
  {
    value += ppnoise(size, sizeModifier, coords, noise_seed, center) * scale;
    coords *= 2.;
    scale *= 0.5;
  }

  return value;
}

float ppcircleNoise(float size, vec2 sizeModifier, vec2 coords,
  uint noise_seed, vec2 center)
{
  float coords_y = floor(coords.y);
  coords.x += coords_y * 0.31;
  vec2 f = fract(coords);
  float h = pprand(size, sizeModifier, vec2(floor(coords.x), floor(coords_y)),
    noise_seed, center);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0., r, m * 0.75);
}

float ppcloud_alpha(float size, vec2 sizeModifier, float time_speed,
  vec2 coords, uint octaves, uint noise_seed, vec2 center)
{
  float c_noise = 0.;

  int iters = 9;
  for (int i = 0; i < iters; i++)
  {
    c_noise += ppcircleNoise(size, sizeModifier,
      (coords * size * 0.3) + (float(i + 1) + 10.) +
        (vec2(time * time_speed, 0.)), noise_seed, center);
  }
  float fbm = ppfbm(size, sizeModifier,
    coords * size + c_noise + vec2(time * time_speed, 0.), octaves,
    noise_seed, center);

  return fbm;
}

vec2 spherify(vec2 coords, vec2 center, float radius)
{
  vec2 centered = (coords - center) * 2.;
  float z = sqrt(radius * radius * 4. - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.);
  return sphere * 0.5 + 0.5;
}
