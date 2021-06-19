# include "planets/common.glsl"

const float[10] lightColors =
  float[](0.766, 0.731, 0.697, 0.66, 0.625, 0.574, 0.525, 0.476, 0.427, 0.376);

const float[10] darkColors =
  float[](0.271, 0.259, 0.248, 0.232, 0.22, 0.206, 0.194, 0.18, 0.168, 0.153);

float turbulence(float size, vec2 sizeModifier, float time_speed, vec2 coords,
  uint noise_seed, uint octaves, vec2 center)
{
  float c_noise = 0.;

  for (uint i = 0u; i < octaves; i++)
  {
    c_noise += ppcircleNoise(size, sizeModifier,
      (coords * size * 0.3) + (float(i + 1u) + 10.) +
        (vec2(time * time_speed, 0.)), noise_seed, center);
  }
  return c_noise;
}

float colorSelection(float colors[10], float posterized)
{
  int pos = int(floor(posterized * 9.5));
  return colors[min(pos, 9)];
}

vec4 computePlanetUnder(vec2 coords, Planet planet, bool dith)
{
  const float size = 8.;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);

  coords = rotate(coords, vec2(0.), planet.rotation);
  coords = spherify(coords, vec2(0.), planet.radius);

  float d_circle = length(coords);
  float d_light = distance(coords, planet.light_origin) / planet.radius;

  float band = ppfbm(size, sizeModifier,
    vec2(0., (coords.y + planet.center.y) * size), octaves, seed,
    planet.center);
  float turb = turbulence(size, sizeModifier, planet.time_speed,
    coords + planet.center, seed, planet.turbulence, planet.center);

  float fbm1 = ppfbm(size, sizeModifier, (coords + planet.center) * size,
    octaves, seed, planet.center);
  float fbm2 = ppfbm(size, sizeModifier,
    (coords * 2. + planet.center) * vec2(1., 2.) * size
    + fbm1 + vec2(time * planet.time_speed, 0.) + turb, octaves, seed,
    planet.center);

  fbm2 *= band * band * 7.;
  float light = fbm2 + d_light * 1.8;
  fbm2 += d_light - 0.3;
  fbm2 = smoothstep(-0.2, max(0., 4. - fbm2), light);
  fbm2 *= (dith ? 1.1 : 1.);

  float posterized = floor(fbm2 * 4.) / 2.;
  float col = (fbm2 < 0.625 ? colorSelection(lightColors, posterized) :
    colorSelection(darkColors, posterized - 1.));

  d_light = sqrt(max(0., 1. - d_light)) + fbm2;
  col *= min(0.9, d_light);
  col *= (dith && (d_light < 0.9) ? 0.95 : 1.);
  col = floor(col * PLANET_COLS) / PLANET_COLS;
  return vec4(vec3(col), 1.);
}

vec3 computeRingShape(vec2 coords, Planet planet, float rotation, float w,
  float ring_radius, float angle)
{
  const float size = 10.;
  float width = 0.12 + w;
  const uint octaves = 5u;
  const vec2 sizeModifier = vec2(2., 1.);

  coords = rotate(coords, vec2(0.), rotation);

  vec2 coords2 = coords * vec2(0.5 - ring_radius, 5.7 - angle);
  float center_d = distance(coords2, vec2(0.));

  float ring = smoothstep(0.5 - width * 2., 0.5 - width, center_d);
  ring *= smoothstep(center_d - width, center_d, 0.4);
  ring *=
    (coords.y > 0. ? step(planet.radius, distance(coords, vec2(0.))) : 1.);

  coords2 =
    rotate(coords2 + vec2(0, 0.5), vec2(0.5), time * planet.time_speed);
  ring *=
    ppfbm(size, sizeModifier, coords2 * size, octaves, seed, planet.center);

  float ring_a = step(0.28, ring);
  return (ring_a > 0. ? vec3(1., ring, abs(ring_a)) : vec3(0.));
}

vec4 computeRingColor(vec2 coords, Planet planet, bool dith)
{
  coords = rotate(coords, vec2(0.), planet.rotation);
  float d_light = distance(coords, planet.light_origin - vec2(0.5)) / sqrt(planet.radius);
  float posterized = floor((planet.ring * d_light * d_light) * 8.) / 8.;
  float col = (posterized <= 1. ? colorSelection(lightColors, posterized) :
    colorSelection(darkColors, posterized - 1.));

  d_light = max(sqrt(1. - d_light) * 1.5, 0.7);
  col *= d_light;
  col *= (dith && (d_light < 1.35) ? 0.95 : 1.);
  col = floor(col * PLANET_COLS) / PLANET_COLS;
  return vec4(vec3(col), 1.);
}

vec4 ring(vec2 coords, Planet planet, bool dith)
{
  return (planet.ring_a > 0. ? computeRingColor(coords, planet, dith) :
    computePlanetUnder(coords, planet, dith));
}
