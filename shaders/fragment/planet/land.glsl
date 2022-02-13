# include "pixelplanets.glsl"

float light_borders(float d_light, float radius)
{
  float light = 1.;
  if (d_light > radius / 4.)
  {
    float p = (1. - d_light) / (1. - radius / 4.);
    p *= p;
    p *= p;
    p *= p;
    light = p;
  }
  return light;
}

vec4 computeClouds(vec2 coords, Planet planet, bool dith)
{
  const float cloud_curve = 1.3;
  const float size = 7.315;
  const float stretch = 3.;
  const float cloud_cover = 0.47;
  const uint octaves = 2u;

  float d_light = distance(coords, planet.light_origin) / sqrt(planet.radius);
  float d_to_center = length(coords);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  coords.y += smoothstep(0., cloud_curve, abs(coords.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.), planet.time_speed,
    (coords + planet.center) * vec2(1., stretch), octaves, seed, planet.center);

  vec3 col = (c < cloud_cover + 0.03 ? vec3(0.887) : vec3(0.956));

  d_light *= d_light * 0.4;
  float light_b = light_borders(d_light, planet.radius) + c - 0.5;
  col *= light_b;
  col *= (dith && (light_b < 1.) ? 0.9 : 1.);
  col = (floor(col * NB_COLS)) / NB_COLS;
  return vec4(col, step(cloud_cover, c));
}

vec4 computeLand(vec2 coords, Planet planet, bool dith)
{
  const float size = 4.6;
  const float river_cutoff = 0.368;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);

  float d_light = distance(coords, planet.light_origin) / sqrt(planet.radius);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  vec2 base_fbm_coords =
    (coords + planet.center) * size + vec2(time * planet.time_speed, 0.);

  float fbm1 =
    ppfbm(size, sizeModifier, base_fbm_coords, octaves, seed, planet.center);
  float fbm2 = ppfbm(size, sizeModifier,
    base_fbm_coords - planet.light_origin * fbm1, octaves, seed, planet.center);
  float fbm3 = ppfbm(size, sizeModifier,
    base_fbm_coords - planet.light_origin * 1.5 * fbm1, octaves, seed,
    planet.center);
  float fbm4 = ppfbm(size, sizeModifier,
    base_fbm_coords - planet.light_origin * 2. * fbm1, octaves, seed,
    planet.center);

  float river_fbm = ppfbm(size, sizeModifier,
    base_fbm_coords + fbm1 * 6., octaves, seed, planet.center);
  river_fbm = step(river_cutoff, river_fbm);

  d_light *= d_light * 0.4;
  vec3 col = (fbm4 + d_light < fbm1 * 1.5 ? vec3(0.283) : vec3(0.204));
  col =      (fbm3 + d_light < fbm1 ?       vec3(0.343) : col);
  col =      (fbm2 + d_light < fbm1 ?       vec3(0.435) : col);
  col = (river_fbm < fbm1 * 0.5 ? (fbm4 + d_light < fbm1 * 1.5 ?
    vec3(0.558) : vec3(0.558)) : col);

  float light_b = light_borders(d_light, planet.radius) + fbm1 - 0.2;
  col *= light_b;
  col *= (dith && (light_b < 1.) ? 0.9 : 1.);
  col = (floor(col * NB_COLS)) / NB_COLS;
  return vec4(col, 1.);
}

vec4 land(vec2 coords, Planet planet, bool dith)
{
  vec4 clouds = computeClouds(coords, planet, dith);
  return (clouds.a == 0. ? computeLand(coords, planet, dith) : clouds);
}
