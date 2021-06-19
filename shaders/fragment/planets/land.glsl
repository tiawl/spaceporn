# include "planets/common.glsl"

vec4 computeClouds(vec2 coords, Planet planet, bool dith)
{
  const float cloud_curve = 1.3;
  const float size = 7.315;
  const uint octaves = 2u;

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_light = distance(coords, planet.light_origin) / planet.radius;

  coords.y += smoothstep(0., cloud_curve, abs(coords.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.), planet.time_speed,
    (coords + planet.center) * vec2(1., planet.cloud_stretch), octaves, seed,
    planet.center);

  float col = (c < planet.cloud_cover + 0.03 ? 0.887 : 0.956);

  d_light *= d_light * 0.8;
  float light_b = (1. - d_light) + (c - 0.5) * 0.5;
  col *= light_b;
  col *= (dith && (light_b < 1.) ? 0.9 : 1.);
  col = (floor(col * NB_COLS)) / NB_COLS;
  return vec4(vec3(col), step(planet.cloud_cover, c));
}

vec4 computeLand(vec2 coords, Planet planet, bool dith)
{
  const float size = 4.6;
  const float river_cutoff = 0.368;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);
  const float light_incr = 1.5;

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_light = distance(coords, planet.light_origin) / planet.radius;
  d_light *= d_light * 0.1;

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

  float col = (fbm4 + d_light < fbm1 ? 0.283 : 0.204);
  col =       (fbm3 + d_light < fbm1 ? 0.343 : col);
  col =       (fbm2 + d_light < fbm1 ? 0.435 : col);
  col = (river_fbm < fbm1 * 0.5 ? (fbm4 + d_light < fbm1 * 1.5 ?
    0.558 : 0.329) : col);

  d_light *= 8.;
  d_light += (fbm4 - 0.5) * 0.35;
  col *= (1. - d_light) * light_incr;
  col *= (dith ? 0.95 : 1.);
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(vec3(col), 1.);
}

vec4 land(vec2 coords, Planet planet, bool dith)
{
  vec4 clouds = computeClouds(coords, planet, dith);
  return (clouds.a <= 0. ? computeLand(coords, planet, dith) : clouds);
}
