const vec3[15] lightColors = vec3[](
  vec3(0.933, 0.764, 0.603),
  vec3(0.913, 0.729, 0.552),
  vec3(0.894, 0.698, 0.501),
  vec3(0.870, 0.662, 0.450),
  vec3(0.850, 0.627, 0.4),
  vec3(0.792, 0.568, 0.364),
  vec3(0.733, 0.509, 0.333),
  vec3(0.678, 0.454, 0.298),
  vec3(0.619, 0.396, 0.266),
  vec3(0.560, 0.337, 0.231),
  vec3(0.0, 1.0, 1.0),        // control colors from here on. To watch for overflows
  vec3(0.0, 0.8, 0.8),
  vec3(0.0, 0.6, 0.6),
  vec3(0.0, 0.4, 0.4),
  vec3(0.0, 0.2, 0.2)
);

const vec3[15] darkColors = vec3[](
  vec3(0.4, 0.223, 0.192),
  vec3(0.368, 0.207, 0.203),
  vec3(0.337, 0.192, 0.215),
  vec3(0.301, 0.172, 0.223),
  vec3(0.270, 0.156, 0.235),
  vec3(0.243, 0.149, 0.227),
  vec3(0.215, 0.145, 0.223),
  vec3(0.188, 0.137, 0.215),
  vec3(0.160, 0.133, 0.211),
  vec3(0.133, 0.125, 0.203),
  vec3(1.0, 1.0, 1.0),        // control colors from here on. To watch for overflows
  vec3(1.0, 0.8, 0.8),
  vec3(1.0, 0.6, 0.6),
  vec3(1.0, 0.4, 0.4),
  vec3(1.0, 0.2, 0.2)
);

float turbulence(float size, vec2 sizeModifier, float time_speed, vec2 uv,
  uint noise_seed, uint octaves)
{
  float c_noise = 0.0;

  for (uint i = 0u; i < octaves; i++)
  {
    c_noise += ppcircleNoise(size, sizeModifier,
      (uv * size * 0.3) + (float(i + 1u) + 10.) +
        (vec2(time * time_speed, 0.0)), noise_seed);
  }
  return c_noise;
}

vec3 colorSelection(vec3 colors[15], float posterized)
{
  int pos = int(floor(posterized * 9.5));
  return colors[pos];
}

vec4 computePlanetUnder(vec2 uv, Planet planet, bool dith)
{
  const float size = 8.0;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);

  float lratio = 1. / sqrt(planet.radius);
  float d_circle = distance(uv, planet.center);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius);

  float band = ppfbm(size, sizeModifier, vec2(0.0, uv.y * size),
    octaves, seed + planet.seed);
  float turb = turbulence(size, sizeModifier, planet.time_speed, uv,
    seed + planet.seed, planet.turbulence);

  float fbm1 =
    ppfbm(size, sizeModifier, uv * size, octaves, seed + planet.seed);
  float fbm2 = ppfbm(size, sizeModifier, uv * vec2(1.0, 2.0) * size
    + fbm1 + vec2(-time * planet.time_speed, 0.0) + turb, octaves,
    seed + planet.seed);

  fbm2 *= band * band * 7.0;
  float light = fbm2 + d_light * 1.8;
  fbm2 += d_light - 0.3;
  fbm2 = smoothstep(-0.2, 4.0 - fbm2, light);

  if (dith)
  {
    fbm2 *= 1.1;
  }

  float posterized = floor(fbm2 * 4.0) / 2.0;
  vec3 col;
  if (fbm2 < 0.625)
  {
    col = colorSelection(lightColors, posterized);
  } else {
    col = colorSelection(darkColors, posterized - 1.0);
  }

  return vec4(col, 1.);
}

vec4 computeRing(vec2 uv, Planet planet, bool colorized)
{
  const float size = 10.0;
  const float width = 0.15;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, sin(time) * 4.);
  uv -= planet.center;

  vec2 uv_center = uv;
  uv_center *= vec2(0.4, 1.7);
  float center_d = distance(uv_center, vec2(0.));

  float ring = smoothstep(0.5 - width * 2.0, 0.5 - width, center_d);
  ring *= smoothstep(center_d - width, center_d, 0.4);

  if (uv.y > 0.1) // here 0.1 should be a variable
  {
    float scale_rel_to_planet = 2.;
    ring *= step(1. / scale_rel_to_planet, distance(uv, vec2(0.)));
  }

  uv_center =
    rotate(uv_center + vec2(0, 0.5), vec2(0.5), time * planet.time_speed);
  ring *=
    ppfbm(size, sizeModifier, uv_center * size, octaves, seed + planet.seed);

  float ring_a = step(0.28, ring);
  if (!colorized)
  {
    if (ring_a > 0.)
    {
      return vec4(1.);
    } else {
      return vec4(0.);
    }
  }

  float posterized = floor((ring * d_light) * 8.0) / 8.0;
  vec3 col;
  if (posterized <= 1.0)
  {
    col = colorSelection(lightColors, posterized);
  } else {
    col = colorSelection(darkColors, posterized - 1.0);
  }
  return vec4(col, ring_a);
}

vec4 ring(vec2 uv, Planet planet, bool dith)
{
  vec4 planetRing = computeRing(uv, planet, true);
  if (planetRing.a != 0.0)
  {
    return planetRing;
  } else {
    return computePlanetUnder(uv, planet, dith);
  }
}
