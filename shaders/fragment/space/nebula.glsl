# include "space/common.glsl"

vec4 hfnebula(vec2 coords, bool dith)
{
  coords *= HFNEBULA_SIZE;

  const uint octaves = 6u;
  coords = dualfbm(coords, octaves);

  float n_alpha = psfbm(coords * 2., octaves, seed);
  float n_nebula = pscloud_alpha(coords, octaves, seed + 1u);
  float n_alpha2 = psfbm(coords * 2., octaves, seed + 2u);
  float n_nebula2 = pscloud_alpha(coords, octaves, seed + 3u);
  float n_nebula_lerp = n_nebula2 * n_nebula;

  if (dith)
  {
    n_nebula_lerp *= 0.95;
  }

  n_nebula_lerp = min(n_nebula_lerp * n_nebula_lerp * n_nebula_lerp * 8., 0.9);

  if (dith)
  {
    n_nebula_lerp *= 1.1;
  }

  float col_value = floor(n_nebula_lerp * NB_COLS) / NB_COLS;
  return vec4(vec3(col_value), 1.);
}

vec4 lfnebula(vec2 coords, bool dith)
{
  coords *= LFNEBULA_SIZE;

  const uint octaves = 2u;
  coords = dualfbm(coords, octaves);

  float d = distance(coords, vec2(0.5)) * 0.4;

  float n = pscloud_alpha(coords, octaves, seed);
  float n2 = psfbm(coords + vec2(1.), octaves, seed + 1u);
  float n_lerp = n2 * n;
  float n_nebula = pscloud_alpha(coords, octaves, seed + 2u);
  float n_nebula_lerp = n_nebula * n_lerp;

  float n_alpha = psfbm(coords - vec2(1.), octaves, seed + 3u);
  float a_nebula = step(n_alpha, n_nebula_lerp * 1.8);

  if (dith)
  {
    n_nebula_lerp *= 0.95;
    d *= 0.98;
  }

  float col_value = floor(n_nebula_lerp * 2. * NB_COLS) / NB_COLS;
  return vec4(vec3(col_value), 1.);
}

vec4 nebula(vec2 coords, bool dith)
{
  return max(lfnebula(coords, dith), hfnebula(coords, dith))
    * 0.8 * (sin(time * 2500.) * 0.015 + 1.);
}
