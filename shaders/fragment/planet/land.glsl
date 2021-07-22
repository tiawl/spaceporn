#include "pixelplanets.glsl"

vec2 landSpherify(vec2 uv, vec2 center, float radius)
{
  vec2 centered = uv - center;
  float z = sqrt(radius - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.0);
  return sphere + 0.5;
}

vec4 computeClouds(vec2 uv, Planet planet)
{
  const float cloud_curve = 1.3;
  const float size = 7.315;
  const float stretch = 3.;
  const float cloud_cover = 0.47;
  const float light_border_clouds_1 = 0.52;
  const float light_border_clouds_2 = 0.62;
  const uint octaves = 2u;

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;
  float d_to_center = distance(uv, planet.center);

  uv = rotate(uv, planet.center, planet.rotation);
  uv = landSpherify(uv, planet.center, planet.radius);

  uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

  float c = ppcloud_alpha(size, vec2(1.0), planet.time_speed,
    (uv + planet.seed) * vec2(1.0, stretch), octaves);

  vec3 col = vec3(0.956);
  if (c < cloud_cover + 0.03)
  {
    col = vec3(0.887);
  }
  if (d_light + c * 0.2 > light_border_clouds_1)
  {
    col = vec3(0.481);
  }
  if (d_light + c * 0.2 > light_border_clouds_2)
  {
    col = vec3(0.329);
  }

  d_light *= d_light * 0.4;
  if (d_light > planet.radius / 4.)
  {
    float p = (1. - d_light) / (1. - planet.radius / 4.);
    p *= p;
    p *= p;
    p *= p;
    col = col * p;
  }

  c *= step(d_to_center, 0.5);

  return vec4(col, step(cloud_cover, c));
}

vec4 computeLand(vec2 UV, vec2 uv, Planet planet)
{
  const float dither_size = 3.951;
  const float size = 4.6;
  const float river_cutoff = 0.368;
  const float light_border_1 = 0.52;
  const float light_border_2 = 0.62;
  const uint octaves = 5u;

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;
  bool dith = dither(dither_size, uv, UV);

  uv = rotate(uv, planet.center, planet.rotation);
  uv = landSpherify(uv, planet.center, planet.radius);

  vec2 base_fbm_uv = (uv + planet.seed) * size +
    vec2(time * planet.time_speed, 0.0);

  float fbm1 = ppfbm(size, vec2(2.0, 1.0), base_fbm_uv, octaves);
  float fbm2 = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv - planet.light_origin * fbm1, octaves);
  float fbm3 = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv - planet.light_origin * 1.5 * fbm1, octaves);
  float fbm4 = ppfbm(size, vec2(2.0, 1.0),
    base_fbm_uv - planet.light_origin * 2.0 * fbm1, octaves);

  float river_fbm =
    ppfbm(size, vec2(2.0, 1.0), base_fbm_uv + fbm1 * 6.0, octaves);
  river_fbm = step(river_cutoff, river_fbm);

  float dither_border = (1.0 / pixels) * dither_size;

  if (d_light < light_border_1)
  {
    fbm4 *= 0.9;
  }
  if (d_light > light_border_1)
  {
    fbm2 *= 1.05;
    fbm3 *= 1.05;
    fbm4 *= 1.05;
  }
  if (d_light > light_border_2)
  {
    fbm2 *= 1.3;
    fbm3 *= 1.4;
    fbm4 *= 1.8;
    if (d_light < light_border_2 + dither_border && dith)
    {
      fbm4 *= 0.5;
    }
  }

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

  if (d_light > planet.radius / 4.)
  {
    float p = (1. - d_light) / (1. - planet.radius / 4.);
    p *= p;
    p *= p;
    p *= p;
    col = col * p;
  }

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
