#include "pixelplanets.glsl"

vec2 moonSpherify(vec2 uv, vec2 center, float radius)
{
  vec2 centered = (uv - center) * 2.;
  float z = sqrt(radius * radius * 4. - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

float circleNoiseCrater(float size, vec2 sizeModifier, vec2 uv)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = pprand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)));
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m);
}

float crater(float size, vec2 sizeModifier, float time_speed, vec2 uv)
{
  float c = 1.0;

  for (int i = 0; i < 2; i++)
  {
    c *= circleNoiseCrater(size, sizeModifier,
      (uv * size) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }

  return 1.0 - c;
}

vec4 computeCraters(vec2 uv, Planet planet)
{
  const float light_border_crater = 0.465;
  const float light_border_planet = 0.729;
  const float sizeCraters = 5.0;
  const float sizePlanet = 8.0;
  const vec3 craterColor1 = vec3(0.521);
  const vec3 craterColor2 = vec3(0.368);
  const uint octaves = 4u;

  float lratio = 1. / sqrt(planet.radius);
  float d_to_center = distance(uv, planet.center);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);
  uv = moonSpherify(uv, planet.center, planet.radius);

  float c1 = crater(sizeCraters, vec2(1.0), planet.time_speed, uv);
  float c2 = crater(sizeCraters, vec2(1.0), planet.time_speed,
    uv + (planet.light_origin - planet.center + vec2(0.5, 0.)) * 0.03);

  vec3 col = craterColor1;
  float a = step(0.5, c1);

  if (c2 < c1 - (0.5 - d_light) * 2.0)
  {
    col = craterColor2;
  }

  if (d_light > light_border_crater)
  {
    col = craterColor2;
  }

  d_light += ppfbm(sizePlanet, vec2(1.0),
    uv * sizePlanet + vec2(time * planet.time_speed, 0.0), octaves) * 0.3;

  if (d_light > light_border_planet)
  {
    col = craterColor2 * (1.- d_light) / (1. - light_border_planet);
  }

  a *= step(d_to_center, planet.radius);

  return vec4(col, a);
}

vec4 computeMoon(vec2 uv, Planet planet)
{
  const float size = 8.0;
  const float light_border_1 = 0.615;
  const float light_border_2 = 0.729;
  const vec3 color1 = vec3(0.760);
  const vec3 color2 = vec3(0.521);
  const vec3 color3 = vec3(0.368);
  const uint octaves = 4u;

  float lratio = 1. / sqrt(planet.radius);
  float d_circle = distance(uv, planet.center);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);

  float a = step(d_circle, 1.);

  d_light += ppfbm(size, vec2(1.0),
    uv * size + vec2(time * planet.time_speed, 0.0), octaves) * 0.3;

  float p = (light_border_1 - d_light) / light_border_1;
  p = sqrt(p);
  vec3 col = color2 * (1 - p) + color1 * p;
  if (d_light > light_border_1)
  {
    p = (light_border_2 - d_light) / (light_border_2 - light_border_1);
    col = color3 * (1 - p) + color2 * p;
  }
  if (d_light > light_border_2)
  {
    col = color3 * (1. - d_light) / (1. - light_border_2);
  }

  return vec4(col, a);
}

vec4 moon(vec2 uv, Planet planet)
{
  planet.time_speed *= 3.;
  vec4 craters = computeCraters(uv, planet);
  if (craters.a == 0.)
  {
    return computeMoon(uv, planet);
  } else {
    return craters;
  }
}
