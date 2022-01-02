# include "pixelspace.glsl"
# include "planet/land.glsl"
# include "planet/moon.glsl"
# include "planet/gaz.glsl"
# include "planet/ring.glsl"

# define MOON 0.25
# define GAZ  0.5
# define RING 0.75
# define LAND 1.

float floor_multiple(float numToRound, float base)
{
  float modulo = mod(numToRound, base);
  if (modulo == 0.)
  {
    return numToRound;
  } else {
    return numToRound - modulo;
  }
}

Planet calc_circle(vec2 ixy, vec2 xy, vec2 offset)
{
  ixy -= offset;
  vec2 center = ixy + planets_density * 0.5;

  center += planets_density * 0.25 + planets_density * 0.5 * hash(ixy, seed);

  float angle = radians(hash(ixy, seed + 1u) * 360.);
  center.x += planets_density * 0.1 * sin(angle);
  center.y += planets_density * 0.1 * cos(angle);

  float rd_planet = ceil(hash(ixy, seed + 2u) * 4.);
  if (rd_planet < 1.)
  {
    rd_planet = 1.;
  }
  rd_planet = rd_planet / 4.;

  float radius = 0.2 + 0.4 * hash(ixy, seed + 3u);
  float light_angle = radians(hash(ixy, seed + 4u) * 360.);
  float light_dist = (radius / 4.) + hash(ixy, seed + 5u) * (radius / 4.);

  float shape = step(distance(xy, center), radius) * rd_planet;
  float rotation = radians(hash(ixy, seed + 6u) * 360.);
  uint seed = uint(round(hash(ixy, seed + 7u) * resolution.x));
  float time_speed = (hash(ixy, seed + 8u) + 1.) * 2.;
  float plan = hash(ixy, seed + 9u);
  vec2 light_origin =
    center + light_dist * vec2(cos(light_angle), sin(light_angle));
  uint turbulence = 0u;
  Planet planet = Planet(shape, center, rotation, radius, seed, time_speed,
    plan, light_origin, turbulence);
  if (rd_planet == GAZ)
  {
    planet.turbulence = (uint(hash(ixy, seed + 10u) * 9.) + 1u) * 10u;
    planet.type = max(computeRing(xy, planet, false).x * rd_planet, planet.type);
  }

  return planet;
}

vec4 planets(vec2 UV, vec2 px, bool dith)
{
  px *= PLANETS_SIZE;

  vec2 ixy = vec2(floor_multiple(px.x, planets_density),
    floor_multiple(px.y, planets_density));

  Planet calc[4] = Planet[4](calc_circle(ixy, px, vec2(0.)),
    calc_circle(ixy, px, vec2(planets_density, 0.)),
    calc_circle(ixy, px, vec2(0., planets_density)),
    calc_circle(ixy, px, vec2(planets_density, planets_density))
  );

  int index = 0;
  Planet planet = Planet(0., vec2(0.), 0., 0., 0u, 0., 0., vec2(0., 0.), 0u);

  while (index < 4)
  {
    if ((calc[index].type > 0.) && (planet.plan < calc[index].plan))
    {
      planet = calc[index];
    }
    ++index;
  }

//   if (planet.type == LAND)
//   {
//     return land(UV, px, planet);
//   } else if (planet.type == MOON) {
//     return moon(px, planet, dith);
//   } else if (planet.type == GAZ) {
//     return gaz(px, planet);
//   } else if (planet.type == RING) {
//     return ring(px, planet, dith);
//   } else {
    return vec4(planet.type); //vec(-1.);
//   }
}
