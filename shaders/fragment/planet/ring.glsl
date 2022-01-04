const vec3[10] lightColors = vec3[](
  vec3(0.766), vec3(0.731), vec3(0.697), vec3(0.660), vec3(0.625), vec3(0.574),
  vec3(0.525), vec3(0.476), vec3(0.427), vec3(0.376)
);

const vec3[10] darkColors = vec3[](
  vec3(0.271), vec3(0.259), vec3(0.248), vec3(0.232), vec3(0.220), vec3(0.206),
  vec3(0.194), vec3(0.18), vec3(0.168), vec3(0.153)
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

vec3 colorSelection(vec3 colors[10], float posterized)
{
  int pos = int(floor(posterized * 9.5));
  return colors[min(pos, 9)];
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
    + fbm1 + vec2(time * planet.time_speed, 0.0) + turb, octaves,
    seed + planet.seed);

  fbm2 *= band * band * 7.0;
  float light = fbm2 + d_light * 1.8;
  fbm2 += d_light - 0.3;
  fbm2 = smoothstep(-0.2, max(0., 4.0 - fbm2), light);

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

  float light_b = 1. - d_light;
  col *= min(0.7, light_b);
  if (dith && (light_b < 0.8))
  {
    col *= 0.95;
  }
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(col, 1.);
}

vec3 computeRingShape(vec2 uv, Planet planet, float rotation, float w,
  float radius, float angle)
{
  const float size = 10.0;
  float width = 0.12 + w;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);

  uv = rotate(uv, planet.center, rotation);
  uv -= planet.center;

  vec2 uv_center = uv;
  uv_center *= vec2(0.5 - radius, 5.7 - angle);
  float center_d = distance(uv_center, vec2(0.));

  float ring = smoothstep(0.5 - width * 2.0, 0.5 - width, center_d);
  ring *= smoothstep(center_d - width, center_d, 0.4);

  if (uv.y > 0.)
  {
    ring *= step(planet.radius, distance(uv, vec2(0.)));
  }

  uv_center =
    rotate(uv_center + vec2(0, 0.5), vec2(0.5), time * planet.time_speed);
  ring *=
    ppfbm(size, sizeModifier, uv_center * size, octaves, seed + planet.seed);

  float ring_a = step(0.28, ring);
  if (ring_a > 0.)
  {
    return vec3(1., ring, ring_a);
  } else {
    return vec3(0.);
  }
}

vec4 computeRingColor(vec2 uv, Planet planet, bool dith)
{
  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;
  float posterized = floor((planet.ring * d_light * d_light) * 8.0) / 8.0;
  vec3 col;
  if (posterized <= 1.0)
  {
    col = colorSelection(lightColors, posterized);
  } else {
    col = colorSelection(darkColors, posterized - 1.0);
  }

  float light_b = max(sqrt(1. - d_light), 0.4);
  col *= light_b;
  if (dith && (light_b < 1.))
  {
    col *= 0.95;
  }
  col = (floor(col * PLANET_COLS)) / PLANET_COLS;
  return vec4(col, 1.);
  return vec4(col, planet.ring_a);
}

vec4 ring(vec2 uv, Planet planet, bool dith)
{
  if (planet.ring_a != 0.0)
  {
    return computeRingColor(uv, planet, dith);
  } else {
    return computePlanetUnder(uv, planet, dith);
  }
}
