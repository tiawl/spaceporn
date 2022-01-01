# include "pixelplanets.glsl"

vec4 computeInnerCloud(vec2 uv, Planet planet)
{
  const float size = 9.0;
  const float stretch = 1.0;
  const uint octaves = 5u;
  const float cloud_curve = 1.3;
  const float cloud_cover = 0.0;

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius);

  uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.0), planet.time_speed,
    uv * vec2(1.0, stretch), octaves, seed + planet.seed);

  vec3 col = vec3(0.169);

  col *= sqrt(0.8 - (d_light + c * 0.2));
  col = (floor(col * GAZ_COLS)) / GAZ_COLS;
  return vec4(col, step(cloud_cover, c));
}

vec4 computeOuterClouds(vec2 uv, Planet planet)
{
  const float size = 9.0;
  const uint octaves = 5u;
  const float stretch = 1.;
  const float cloud_curve = 1.3;
  const float cloud_cover = 0.538;

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius);

  uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.0), planet.time_speed,
    uv * vec2(1.0, stretch), octaves, seed + planet.seed);

  vec3 col = vec3(0.634);
  if (c < cloud_cover + 0.03)
  {
    col = vec3(0.479);
  }

  col *= sqrt(0.8 - (d_light + c * 0.2));
  col = (floor(col * GAZ_COLS)) / GAZ_COLS;
  return vec4(col, step(cloud_cover, c));
}

vec4 gaz(vec2 uv, Planet planet)
{
  vec4 outerClouds = computeOuterClouds(uv, planet);
  if (outerClouds.a != 0.0)
  {
    return outerClouds;
  } else {
    return computeInnerCloud(uv, planet);
  }
}
