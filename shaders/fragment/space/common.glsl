# include "common.glsl"
# include "hash.glsl"

float psnoise(vec2 coords, uint noise_seed)
{
  vec2 i = floor(coords);
  vec2 f = fract(coords);
  f = f * f * (3. - 2. * f);

  float a = hash(i, noise_seed);
  float b = hash(i + vec2(1., 0.), noise_seed);
  float c = hash(i + vec2(0., 1.), noise_seed);
  float d = hash(i + vec2(1.), noise_seed);

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float psfbm(vec2 coords, uint octaves, uint noise_seed)
{
  float value = 0.;
  float scale = 0.5;

  uint i;
  for (i = 0u; i < octaves; i++)
  {
    value += psnoise(coords, noise_seed) * scale;
    coords *= 2.;
    scale *= 0.5;
  }

  return value;
}

float pscircleNoise(vec2 coords, uint noise_seed)
{
  float coords_y = floor(coords.y);
  coords.x += coords_y * 0.31;
  vec2 f = fract(coords);
  float h = hash(vec2(floor(coords.x), floor(coords_y)), noise_seed);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0., r, m * 0.75);
}

float pscloud_alpha(vec2 coords, uint octaves, uint noise_seed)
{
  float c_noise = 0.;

  int iters = 2;
  int i;
  for (i = 0; i < iters; i++)
  {
    c_noise += pscircleNoise(coords * 0.5 + (float(i + 1)) + vec2(-0.3, 0.),
      noise_seed);
  }
  float fbm = psfbm(coords + c_noise, octaves, noise_seed);

  return fbm;
}

vec2 dualfbm(vec2 p, uint octaves)
{
  vec2 p2 = p * 0.4;
  vec2 basis = vec2(psfbm(p2 - time * 0.3, octaves, seed),
    psfbm(p2 + time * 0.4, octaves, seed));
  basis = (basis - 0.5) * 3.;
  p += basis;

  return p;
}
