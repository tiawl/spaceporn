# include "noiseanimation.glsl"

vec4 nebulae(vec2 uv, bool dith)
{
  uint octaves = 2u;
  uv = dualfbm(uv, octaves);

  float d = distance(uv, vec2(0.5)) * 0.4;

  float n = pscloud_alpha(uv * DUST_SIZE, octaves);
  float n2 = psfbm(uv * DUST_SIZE + vec2(1, 1), octaves);
  float n_lerp = n2 * n;
  float n_dust = pscloud_alpha(uv * DUST_SIZE, octaves);
  float n_dust_lerp = n_dust * n_lerp;

  float n_alpha = psfbm(uv * ceil(DUST_SIZE * 0.05) - vec2(1, 1), octaves);
  float a_dust = step(n_alpha , n_dust_lerp * 1.8);

  if (dith)
  {
    n_dust_lerp *= 0.95;
    n_lerp *= 0.95;
    d*= 0.98;
  }

  float a = step(n2, 0.1 + d);
  float a2 = step(n2, 0.115 + d);

  float col_value = 0.0;
  if (a2 > a) {
    col_value = floor(n_dust_lerp * 35.0) / NB_COL;
  } else {
    col_value = floor(n_dust_lerp * 14.0) / NB_COL;
  }

  return vec4(vec3(col_value), a2);
}
