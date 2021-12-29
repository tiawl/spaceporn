# include "noiseanimation.glsl"

vec4 dust(vec2 uv, bool dith)
{
  uint octaves = 8u;
  uv = dualfbm(uv, octaves);

  float n_alpha = psfbm(uv * ceil(DUST_SIZE * 0.5) + uv * 2., octaves);
  float n_dust = pscloud_alpha(uv * DUST_SIZE, octaves);
  float n_dust2 = psfbm(uv * ceil(DUST_SIZE * 0.2) - uv * 2., octaves);
  float n_dust_lerp = n_dust2 * n_dust;

  if (dith)
  {
    n_dust_lerp *= 0.95;
  }

  float a_dust = step(n_alpha , n_dust_lerp * 2.8);
  n_dust_lerp = pow(n_dust_lerp, 3.2) * 56.0;
  if (dith)
  {
    n_dust_lerp *= 1.1;
  }

  float col_value = floor(n_dust_lerp) / NB_COL;
  return vec4(vec3(col_value), a_dust);
}
