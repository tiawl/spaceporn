# include "space/common.glsl"

vec4 dust(vec2 coords, bool dith)
{
  coords *= DUST_SIZE;

  const uint octaves = 6u;
  coords = dualfbm(coords, octaves);

  float n_alpha = psfbm(coords * 2., octaves, seed);
  float n_dust = pscloud_alpha(coords, octaves, seed + 1u);
  float n_alpha2 = psfbm(coords * 2., octaves, seed + 2u);
  float n_dust2 = pscloud_alpha(coords, octaves, seed + 3u);
  float n_dust_lerp = n_dust2 * n_dust;

  if (dith)
  {
    n_dust_lerp *= 0.95;
  }

  n_dust_lerp = min(n_dust_lerp * n_dust_lerp * n_dust_lerp * 8., 0.9);

  if (dith)
  {
    n_dust_lerp *= 1.1;
  }

  float col_value = floor(n_dust_lerp * NB_COLS) / NB_COLS;
  return vec4(vec3(col_value), 1.);
}
