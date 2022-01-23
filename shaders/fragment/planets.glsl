# include "hash.glsl"
# include "planet/land.glsl"
# include "planet/moon.glsl"
# include "planet/gaz.glsl"
# include "planet/ring.glsl"
# include "planet/dry.glsl"

# define LAND 0.2
# define MOON 0.4
# define GAZ  0.6
# define RING 0.8
# define DRY  1.0
# define PLANET_TYPES 5.

Planet calc_planet(vec2 ixy, vec2 xy, vec2 offset)
{
  ixy -= offset;
  vec2 center = ixy + planets_density * 0.5;

  center += planets_density * 0.25 + planets_density * 0.5 * hash(ixy, seed);

  float angle = radians(hash(ixy, seed + 1u) * 360.);
  center.x += planets_density * 0.1 * sin(angle);
  center.y += planets_density * 0.1 * cos(angle);

  float rd_planet = max(ceil(hash(ixy, seed + 2u) * PLANET_TYPES), 1.);
  rd_planet = rd_planet / PLANET_TYPES;

  float radius = 0.2 + 0.4 * hash(ixy, seed + 3u);
  float light_angle = radians(hash(ixy, seed + 4u) * 360.);
  float light_dist = (radius / 4.) + hash(ixy, seed + 5u) * (radius / 4.);

  float shape = step(distance(xy, center), radius) * rd_planet;
  float rotation = radians(hash(ixy, seed + 6u) * 360.);
  float time_speed = (hash(ixy, seed + 7u) + 1.) * 2.;
  float plan = hash(ixy, seed + 8u);
  vec2 light_origin =
    center + light_dist * vec2(cos(light_angle), sin(light_angle));

  Planet planet = Planet(shape, center, rotation, radius, time_speed, plan,
    light_origin, 0u, 0., 0.);
  if (rd_planet == RING) // TODO: remove equality
  {
    float ring_rotation = radians(hash(ixy, seed + 10u) * 360.);
    float ring_radius =
      hash(ixy, seed + 11u) * (0.2 + (planet.radius - 0.2) / 4.);
    float ring_width = hash(ixy, seed + 12u) * 0.06;
    float ring_angle = hash(ixy, seed + 13u) * 10. * (planet.radius - 0.2);

    vec3 res = computeRingShape(xy, planet, ring_rotation, ring_width,
      ring_radius, ring_angle);
    planet.type = max(res.x * rd_planet, planet.type);
    planet.ring = res.y;
    planet.ring_a = res.z;
    planet.turbulence = (uint(hash(ixy, seed + 9u) * 9.) + 1u) * 10u;
  }

  return planet;
}

vec4 planets(vec2 px, bool dith)
{
  px *= PLANETS_SIZE;

  vec2 ixy = vec2(floor_multiple(px.x, planets_density),
    floor_multiple(px.y, planets_density));

  Planet calc[4] = Planet[4](calc_planet(ixy, px, vec2(0.)),
    calc_planet(ixy, px, vec2(planets_density, 0.)),
    calc_planet(ixy, px, vec2(0., planets_density)),
    calc_planet(ixy, px, vec2(planets_density, planets_density))
  );

  int index = 0;
  Planet planet =
    Planet(0., vec2(0.), 0., 0., 0., 0., vec2(0., 0.), 0u, 0., 0.);

  while (index < 4)
  {
    if ((calc[index].type > 0.) && (planet.plan < calc[index].plan))
    {
      planet = calc[index];
    }
    ++index;
  }

  if (planet.type > (DRY + RING) / 2.)
  {
    return dry(px, planet, dith);
  } else if (planet.type > (RING + GAZ) / 2.) {
    return ring(px, planet, dith);
  } else if (planet.type > (GAZ + MOON) / 2.) {
    return gaz(px, planet, dith);
  } else if (planet.type > (MOON + LAND) / 2.) {
    return moon(px, planet, dith);
  } else if (planet.type > LAND / 2.) {
    return land(px, planet, dith);
  } else {
    return vec4(-1.);// vec4(planet.type);
  }
}
