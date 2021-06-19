# include "hash.glsl"
# include "planets/land.glsl"
# include "planets/moon.glsl"
# include "planets/gaz.glsl"
# include "planets/ring.glsl"
# include "planets/dry.glsl"

# define LAND 1u
# define MOON 2u
# define GAZ  3u
# define RING 4u
# define DRY  5u
# define PLANET_TYPES 5.

Planet calc_planet(vec2 coords, vec2 center, float pixel_res)
{
  uint rd_planet = uint(max(ceil(hash(center, seed + 2u) * PLANET_TYPES), 1.));

  float radius = 0.2 + 0.4 * hash(center, seed + 3u);
  float light_angle = radians(hash(center, seed + 4u) * 360.);
  float light_dist = radius * 1.2 * hash(center, seed + 5u);

  uint shape = sign(length(coords) - radius) < 0.5 ? rd_planet : 0u;
  float rotation = radians(hash(center, seed + 6u) * 360.);
  float time_speed = (hash(center, seed + 7u) + 1.) * 2.;
  float plan = hash(center, seed + 8u);
  vec2 light_origin =
    vec2(0.5) + light_dist * vec2(cos(light_angle), sin(light_angle));

  Planet planet = Planet(shape, center, rotation, radius, time_speed, plan,
    light_origin, 0u, 0., 0., 0., 0.);

  if (rd_planet == RING)
  {
    float ring_rotation = radians(hash(center, seed + 10u) * 360.);
    float ring_radius =
      hash(center, seed + 11u) * (0.2 + (planet.radius - 0.2) / 4.);
    float ring_width = hash(center, seed + 12u) * 0.06;
    float ring_angle = hash(center, seed + 13u) * 10. * (planet.radius - 0.2);

    vec3 res = computeRingShape(coords, planet, ring_rotation, ring_width,
      ring_radius, ring_angle);
    planet.type = max(uint(res.x) * rd_planet, planet.type);
    planet.ring = res.y;
    planet.ring_a = res.z;
    planet.turbulence = (uint(hash(center, seed + 9u) * 9.) + 1u) * 10u;
  } else if (rd_planet == LAND) {
    planet.cloud_cover = 0.37 + hash(center, seed + 10u) * 0.3;
    planet.cloud_stretch = 2. + hash(center, seed + 10u) * 2.;
  }

  return planet;
}

vec4 planets(vec2 coords, bool dith)
{
  float scale = PLANETS_DENSITY / 10.;
  coords *= PLANETS_DENSITY;
  Planet planet =
    Planet(0u, vec2(0.), 0., 0., 0., 0., vec2(0.), 0u, 0., 0., 0., 0.);
  Planet tmp =
    Planet(0u, vec2(0.), 0., 0., 0., 0., vec2(0.), 0u, 0., 0., 0., 0.);
  vec2 o;
  vec2 fp_coords;

  float pixel_res = PLANETS_DENSITY / pixels;

  vec2 i = floor(coords);
  vec2 f = fract(coords);
  vec2 h;
  vec2 center;

  for (int k = 0; k < 9; k++)
  {
    o = vec2(k % 3, k / 3) - 1.;

    center = i + o;
    h = vec2(floor2(hash(center, seed), pixel_res),
      floor2(hash(center, seed + 1u), pixel_res));
    coords = o + h - f;

    tmp = calc_planet(coords / scale, center, pixel_res);
    if ((tmp.type > 0.) && (planet.plan < tmp.plan))
    {
      planet = tmp;
      fp_coords = coords;
    }
  }
  coords = fp_coords / scale;

  vec4 color;
  switch (planet.type)
  {
    case LAND:
      color = land(coords, planet, dith);
      break;
    case MOON:
      color = moon(coords, planet);
      break;
    case GAZ:
      color = gaz(coords, planet, dith);
      break;
    case RING:
      color = ring(coords, planet, dith);
      break;
    case DRY:
      color = dry(coords, planet, dith);
      break;
    default:
      color = vec4(-1.);// vec4(planet.type / PLANET_TYPES);
      break;
  }
  return color;
}
