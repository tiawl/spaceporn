# include "space/common.glsl"

vec4 nebula(vec2 coords, bool dith)
{
  coords *= NEBULA_SIZE;

  const uint octaves = 2u;
  coords = dualfbm(coords, octaves);

  float d = distance(coords, vec2(0.5)) * 0.4;

  float n = pscloud_alpha(coords, octaves, seed);
  float n2 = psfbm(coords + vec2(1.), octaves, seed + 1u);
  float n_lerp = n2 * n;
  float n_dust = pscloud_alpha(coords, octaves, seed + 2u);
  float n_dust_lerp = n_dust * n_lerp;

  float n_alpha = psfbm(coords - vec2(1.), octaves, seed + 3u);
  float a_dust = step(n_alpha, n_dust_lerp * 1.8);

  if (dith)
  {
    n_dust_lerp *= 0.95;
    d *= 0.98;
  }

  float col_value = floor(n_dust_lerp * 2. * NB_COLS) / NB_COLS;
  return vec4(vec3(col_value), 1.);
}
