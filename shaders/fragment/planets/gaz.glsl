# include "planets/common.glsl"

vec4 computeInnerCloud(vec2 coords, Planet planet, bool dith)
{
  const float size = 9.;
  const float stretch = 1.;
  const uint octaves = 5u;
  const float cloud_curve = 1.3;
  const float cloud_cover = 0.;

  float d_light = distance(coords, planet.light_origin) / sqrt(planet.radius);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  coords.y += smoothstep(0., cloud_curve, abs(coords.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.), planet.time_speed,
    (coords + planet.center) * vec2(1., stretch), octaves, seed, planet.center);

  vec3 col = vec3(0.169);

  float light_b = sqrt(0.8 - (d_light + c * 0.2));
  col *= light_b;
  col *= (dith && (light_b < 1.) ? 0.9 : 1.);
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(col, step(cloud_cover, c));
}

vec4 computeOuterClouds(vec2 coords, Planet planet, bool dith)
{
  const float size = 9.;
  const uint octaves = 5u;
  const float stretch = 1.;
  const float cloud_curve = 1.3;
  const float cloud_cover = 0.538;

  float d_light = distance(coords, planet.light_origin) / sqrt(planet.radius);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  coords.y += smoothstep(0., cloud_curve, abs(coords.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.), planet.time_speed,
    (coords + planet.center) * vec2(1., stretch), octaves, seed, planet.center);

  vec3 col = (c < cloud_cover + 0.03 ? vec3(0.479) : vec3(0.634));

  float light_b = sqrt(0.8 - (d_light + c * 0.2));
  col *= light_b;
  col *= (dith && (light_b < 1.) ? 0.9 : 1.);
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(col, step(cloud_cover, c));
}

vec4 gaz(vec2 coords, Planet planet, bool dith)
{
  vec4 outerClouds = computeOuterClouds(coords, planet, dith);
  return (outerClouds.a != 0. ?
    outerClouds : computeInnerCloud(coords, planet, dith));
}
