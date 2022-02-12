# include "noiseanimation.glsl"

vec4 nebula(vec2 coords, bool dith)
{
  coords *= NEBULA_SIZE;

  uint octaves = 2u;
  uint neb_seed = seed + 1u;
  coords = dualfbm(coords, octaves, neb_seed);

  float d = distance(coords, vec2(0.5)) * 0.4;

  float n = pscloud_alpha(coords, octaves, neb_seed);
  float n2 = psfbm(coords + vec2(1.), octaves, neb_seed);
  float n_lerp = n2 * n;
  float n_dust = pscloud_alpha(coords, octaves, neb_seed);
  float n_dust_lerp = n_dust * n_lerp;

  float n_alpha = psfbm(coords * ceil(0.05) - vec2(1.), octaves,
    neb_seed);
  float a_dust = step(n_alpha , n_dust_lerp * 1.8);

  if (dith)
  {
    n_dust_lerp *= 0.95;
    d*= 0.98;
  }

  float a = step(n2, 0.1 + d);
  float a2 = step(n2, 0.115 + d);

  float col_value = 0.0;
  if (a2 > a) {
    col_value = floor(n_dust_lerp * 35.0) / NB_COLS;
  } else {
    col_value = floor(n_dust_lerp * 14.0) / NB_COLS;
  }

  return vec4(vec3(col_value), a2);
}
