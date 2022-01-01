# include "pixelplanets.glsl"

float light_borders(float d_light, float radius)
{
  float light = 1.;
  if (d_light > radius / 8.)
  {
    float p = (1. - d_light) / (1. - radius / 8.);
    p *= p;
    p *= p;
    p *= p;
    p *= p;
    light = p;
  }
  return light;
}

vec4 computeClouds(vec2 uv, Planet planet)
{
  const float cloud_curve = 1.3;
  const float size = 7.315;
  const float stretch = 3.;
  const float cloud_cover = 0.47;
  const uint octaves = 2u;

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;
  float d_to_center = distance(uv, planet.center);

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius);

  uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.0), planet.time_speed,
    uv * vec2(1.0, stretch), octaves, seed + planet.seed);

  vec3 col = vec3(0.956);
  if (c < cloud_cover + 0.03)
  {
    col = vec3(0.887);
  }

  d_light *= d_light * 0.4;
  col = col * light_borders(d_light, planet.radius);
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(col, step(cloud_cover, c));
}

vec4 computeLand(vec2 UV, vec2 uv, Planet planet)
{
  const float dither_size = 3.951;
  const float size = 4.6;
  const float river_cutoff = 0.368;
  const uint octaves = 5u;

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;
  bool dith = dither(dither_size, uv, UV);

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius);

  vec2 base_fbm_uv = uv * size + vec2(time * planet.time_speed, 0.0);

  float fbm1 =
    ppfbm(size, vec2(2.0, 1.0), base_fbm_uv, octaves, seed + planet.seed);
  float fbm2 = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv - planet.light_origin * fbm1, octaves, seed + planet.seed);
  float fbm3 = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv - planet.light_origin * 1.5 * fbm1, octaves, seed + planet.seed);
  float fbm4 = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv - planet.light_origin * 2.0 * fbm1, octaves, seed + planet.seed);

  float river_fbm = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv + fbm1 * 6.0, octaves, seed + planet.seed);
  river_fbm = step(river_cutoff, river_fbm);

  float dither_border = (1.0 / pixels) * dither_size;

  d_light *= d_light * 0.4;
  vec3 col = vec3(0.204);
  if (fbm4 + d_light < fbm1 * 1.5)
  {
    col = vec3(0.283);
  }
  if (fbm3 + d_light < fbm1)
  {
    col = vec3(0.343);
  }
  if (fbm2 + d_light < fbm1)
  {
    col = vec3(0.435);
  }
  if (river_fbm < fbm1 * 0.5)
  {
    col = vec3(0.329);
    if (fbm4 + d_light < fbm1 * 1.5)
    {
      col = vec3(0.558);
    }
  }

  col = col * light_borders(d_light, planet.radius);
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(col, step(distance(vec2(0.5), uv), 0.5));
}

vec4 land(vec2 UV, vec2 uv, Planet planet)
{
  vec4 clouds = computeClouds(uv, planet);
  if (clouds.a == 0.)
  {
    return computeLand(UV, uv, planet);
  } else {
    return clouds;
  }
}
