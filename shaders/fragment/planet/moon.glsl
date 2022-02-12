# include "pixelplanets.glsl"

float circleNoiseCrater(float size, vec2 sizeModifier, vec2 uv, vec2 center)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h =
    pprand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)), seed, center);
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m);
}

float crater(float size, vec2 sizeModifier, float time_speed, vec2 uv,
  vec2 center)
{
  float c = 1.0;

  for (int i = 0; i < 2; i++)
  {
    c *= circleNoiseCrater(size, sizeModifier,
      (uv * size) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0),
      center);
  }

  return 1.0 - c;
}

vec4 computeCraters(vec2 uv, Planet planet, bool dith)
{
  const float sizeCraters = 5.0;
  const float sizePlanet = 8.0;
  const vec3 color1 = vec3(0.608);
  const uint octaves = 4u;
  const vec2 sizeModifier = vec2(2., 1.);

  float lratio = 1. / sqrt(planet.radius);
  float d_to_center = length(uv);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, vec2(0.), planet.rotation);
  uv = spherify(uv, vec2(0.), planet.radius);

  float c1 =
    crater(sizeCraters, sizeModifier, planet.time_speed, uv, planet.center);
  float c2 = crater(sizeCraters, sizeModifier, planet.time_speed,
    uv + (planet.light_origin + vec2(0.5, 0.)) * 0.03,
    planet.center);

  float s = step(d_to_center, planet.radius);
  float a = step(0.5, c1) * s * s;

  d_light += ppfbm(sizePlanet, sizeModifier,
    uv * sizePlanet + vec2(time * planet.time_speed, 0.0), octaves, seed,
    planet.center) * 0.3;

  float light_b = 1. - d_light;
  vec3 col = vec3(light_b);

  if (dith && (light_b < 1.))
  {
    col *= 0.9;
  }

  float diff_col = 0.;
  if ((c1 > 0.) && (c2 == 0.))
  {
    diff_col = (PLANET_COLS / 5.);
  }
  col = (floor(col * PLANET_COLS) - diff_col) / PLANET_COLS;
  col = min(col, color1);
  return vec4(col, a);
}

vec4 computeMoon(vec2 uv, Planet planet, bool dith)
{
  const float size = 8.0;
  const vec3 color1 = vec3(0.608);
  const uint octaves = 4u;
  const vec2 sizeModifier = vec2(2., 1.);

  float lratio = 1. / sqrt(planet.radius);
  float d_circle = length(uv);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, vec2(0.), planet.rotation);

  float a = step(d_circle, 1.);

  d_light += ppfbm(size, sizeModifier,
    uv * size + vec2(time * planet.time_speed, 0.0), octaves, seed,
    planet.center) * 0.3;

  float light_b = 1. - d_light;
  vec3 col = vec3(light_b);

  if (dith && (light_b < 1.))
  {
    col *= 0.9;
  }

  col = floor(col * PLANET_COLS) / PLANET_COLS;
  col = min(col, color1);
  return vec4(col, a);
}

vec4 moon(vec2 uv, Planet planet, bool dith)
{
  planet.time_speed *= 3.;
  vec4 craters = computeCraters(uv, planet, dith);
  if (craters.a == 0.)
  {
    return computeMoon(uv, planet, dith);
  } else {
    return craters;
  }
}
