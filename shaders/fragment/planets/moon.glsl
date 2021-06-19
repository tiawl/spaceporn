# include "planets/common.glsl"

float circleNoiseCrater(float size, vec2 sizeModifier, vec2 coords, vec2 center)
{
  float coords_y = floor(coords.y);
  coords.x += coords_y * 0.31;
  vec2 f = fract(coords);
  float h = pprand(size, sizeModifier, vec2(floor(coords.x), floor(coords_y)),
    seed, center);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(r - 0.1 * r, r, m);
}

float crater(float size, vec2 sizeModifier, float time_speed, vec2 coords,
  vec2 center)
{
  float c = 1.;

  int i;
  for (i = 0; i < 2; i++)
  {
    c *= circleNoiseCrater(size, sizeModifier,
      (coords * size) + (float(i + 1) + 10.) + vec2(time * time_speed, 0.),
      center);
  }

  return 1. - c;
}

vec4 computeCraters(vec2 coords, Planet planet)
{
  const float sizeCraters = 5.;
  const float sizePlanet = 8.;
  const float color1 = 0.608;
  const uint octaves = 4u;
  const vec2 sizeModifier = vec2(2., 1.);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_light = distance(coords, planet.light_origin) / planet.radius;

  float c1 = crater(sizeCraters, sizeModifier, planet.time_speed,
    coords + planet.center, planet.center);
  float c2 = crater(sizeCraters, sizeModifier, planet.time_speed,
    coords + planet.center + (planet.light_origin - coords) * 0.06,
    planet.center);

  d_light += ppfbm(sizePlanet, sizeModifier,
    (coords + planet.center) * sizePlanet + vec2(time * planet.time_speed, 0.),
    octaves, seed, planet.center) * 0.5;

  d_light = max(1. - d_light, 0.);
  float col = d_light;

  float n =
    hash(coords * pixels, seed) + hash(coords * pixels, seed + 1u) - 1.;
  col = (col < 0.0031308) ? col * 12.92 : 1.055 * pow(col, (1. / 2.4)) - 0.055;
  col = col + n / PLANET_COLS;
  col = (floor(col * PLANET_COLS) - ((c1 > 0.) && (c2 <= 0.) ? 3. : 1.))
    / PLANET_COLS;
  col = min(col, color1 - 1 / PLANET_COLS);
  return vec4(vec3(col), step(0.5, c1));
}

vec4 computeMoon(vec2 coords, Planet planet)
{
  const float size = 8.;
  const float color1 = 0.608;
  const uint octaves = 4u;
  const vec2 sizeModifier = vec2(2., 1.);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_light = distance(coords, planet.light_origin) / planet.radius;

  d_light += ppfbm(size, sizeModifier,
    (coords + planet.center) * size + vec2(time * planet.time_speed, 0.),
    octaves, seed, planet.center) * 0.5;

  d_light = max(1. - d_light, 0.);
  float col = d_light;

  float n =
    hash(coords * pixels, seed) + hash(coords * pixels, seed + 1u) - 1.0;
  col = (col < 0.0031308) ? col * 12.92 : 1.055 * pow(col, (1. / 2.4)) - 0.055;
  col = col + n / PLANET_COLS;
  col = floor(col * PLANET_COLS) / PLANET_COLS;
  col = min(col, color1);
  return vec4(vec3(col), 1.);
}

vec4 moon(vec2 coords, Planet planet)
{
  planet.time_speed *= 3.;
  vec4 craters = computeCraters(coords, planet);
  return (craters.a <= 0. ? computeMoon(coords, planet) : craters);
}
