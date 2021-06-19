# include "planets/common.glsl"

vec4 computeInnerCloud(vec2 coords, Planet planet, bool dith)
{
  const float size = 9.;
  const float stretch = 1.;
  const uint octaves = 5u;
  const float cloud_curve = 1.3;
  const float cloud_cover = 0.;
  const vec2 sizeModifier = vec2(2., 1.);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_light = distance(coords, planet.light_origin) / planet.radius;

  d_light += ppfbm(size, sizeModifier,
    (coords + planet.center) * size + vec2(time * planet.time_speed, 0.),
    octaves, seed, planet.center) * 0.3;

  coords.y += smoothstep(0., cloud_curve, abs(coords.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.), planet.time_speed,
    (coords + planet.center) * vec2(1., stretch), octaves, seed, planet.center);

  d_light = sqrt(max(0., 1. - d_light)) + (c - 0.5);
  float col = 0.2 * d_light;
  col *= (dith && (d_light < 1.) ? 0.9 : 1.);
  col = ceil(col * PLANET_COLS) / PLANET_COLS;
  return vec4(vec3(col), step(cloud_cover, c));
}

vec4 computeOuterClouds(vec2 coords, Planet planet, bool dith)
{
  const float size = 9.;
  const uint octaves = 5u;
  const float stretch = 1.;
  const float cloud_curve = 1.3;
  const float cloud_cover = 0.538;
  const vec2 sizeModifier = vec2(2., 1.);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_light = distance(coords, planet.light_origin) / planet.radius;

  d_light += ppfbm(size, sizeModifier,
    (coords + planet.center) * size + vec2(time * planet.time_speed, 0.),
    octaves, seed, planet.center) * 0.3;

  coords.y += smoothstep(0., cloud_curve, abs(coords.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.), planet.time_speed,
    (coords + planet.center) * vec2(1., stretch), octaves, seed, planet.center);

  float col = (c < cloud_cover + 0.03 ? 0.5 : 0.7);

  d_light = sqrt(max(0., 1. - d_light)) + (c - 0.5);
  col *= d_light;
  col *= (dith ? 0.93 : 1.);
  col = floor(col * PLANET_COLS) / PLANET_COLS;
  return vec4(vec3(col), abs(step(cloud_cover, c)));
}

vec4 gaz(vec2 coords, Planet planet, bool dith)
{
  vec4 outerClouds = computeOuterClouds(coords, planet, dith);
  return (outerClouds.a > 0. ?
    outerClouds : computeInnerCloud(coords, planet, dith));
}
