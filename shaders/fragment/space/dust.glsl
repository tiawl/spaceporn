# include "space/common.glsl"

vec4 dust(vec2 coords, bool dith)
{
  coords *= DUST_SIZE;

  uint octaves = 8u;
  coords = dualfbm(coords, octaves, seed);

  float n_alpha = psfbm(coords * ceil(0.5) + coords * 2., octaves, seed);
  float n_dust = pscloud_alpha(coords, octaves, seed);
  float n_alpha2 = psfbm(coords * ceil(0.2) + coords * 2., octaves,
    seed + 2u);
  float n_dust2 = pscloud_alpha(coords, octaves, seed + 2u);
  float n_dust_lerp = n_dust2 * n_dust;

  if (dith)
  {
    n_dust_lerp *= 0.95;
  }

  float a_dust = step(n_alpha , n_dust_lerp * 2.8);
  n_dust_lerp = pow(n_dust_lerp, 3.2) * 56.;
  if (dith)
  {
    n_dust_lerp *= 1.1;
  }

  float col_value = floor(n_dust_lerp) / NB_COLS;
  return vec4(vec3(col_value), a_dust);
}
