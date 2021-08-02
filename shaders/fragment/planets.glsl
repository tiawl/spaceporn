# include "pixelspace.glsl"
# include "planet/land.glsl"
# include "planet/moon.glsl"

# define MOON 0.25
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

Planet calc_circle(vec2 xy, vec2 offset)
{
  vec2 ixy = vec2(floor_multiple(xy.x, planets_density),
    floor_multiple(xy.y, planets_density));

  ixy -= offset;
  vec2 center = ixy + planets_density * 0.5;

  center += planets_density * 0.25 + planets_density * 0.5 * psrand(ixy);

  float angle = radians(psrand(ixy + 50.0) * 360.);
  center.x += planets_density * 0.1 * sin(angle);
  center.y += planets_density * 0.1 * cos(angle);

  float rd_planet = ceil(psrand(ixy + 620.) * 4.);
  if (rd_planet < 1.)
  {
    rd_planet = 1.;
  }
  rd_planet = rd_planet / 4.;

  float radius = 0.2 + 0.4 * psrand(ixy + 100.0);
  float light_angle = radians(psrand(ixy + 230.0) * 360.);
  float light_dist = (radius / 4.) + psrand(ixy - 370.) * (radius / 4.);

  return Planet(step(distance(xy, center), radius) * rd_planet,
    center, radians(psrand(ixy - 20.0) * 360.), radius,
    vec2(psrand(ixy + 840.), psrand(ixy + 480.)),
    (psrand(ixy - 90.) + 1.) * 2., psrand(ixy - 520.),
    center + light_dist * vec2(cos(light_angle), sin(light_angle)));
}

vec4 planets(vec2 UV, vec2 uv)
{
  uv *= 5.;

  Planet calc[4] = Planet[4](
    calc_circle(uv, vec2(0., 0.)), calc_circle(uv, vec2(planets_density, 0.)),
    calc_circle(uv, vec2(0., planets_density)),
    calc_circle(uv, vec2(planets_density, planets_density))
  );

  int index = 0;
  Planet planet = Planet(0., vec2(0.), 0., 0., vec2(0.), 0., 0., vec2(0., 0.));

  while (index < 4)
  {
    if ((calc[index].type > 0.) && (planet.plan < calc[index].plan))
    {
      planet = calc[index];
    }
    ++index;
  }

  if (planet.type == LAND)
  {
    return land(UV, uv, planet);
  } else if (planet.type == MOON) {
    return moon(uv, planet);
  } else {
    return vec4(planet.type);
  }
}
