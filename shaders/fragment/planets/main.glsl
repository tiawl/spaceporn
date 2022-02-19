# include "hash.glsl"
# include "planets/land.glsl"
# include "planets/moon.glsl"
# include "planets/gaz.glsl"
# include "planets/ring.glsl"
# include "planets/dry.glsl"

# define LAND 1.
# define MOON 2.
# define GAZ  3.
# define RING 4.
# define DRY  5.
# define PLANET_TYPES 5.

Planet calc_planet(vec2 coords, vec2 center, float pixel_res)
{
  float rd_planet = max(ceil(hash(center, seed + 2u) * PLANET_TYPES), 1.);

  float radius = 0.2 + 0.4 * hash(center, seed + 3u);
  float light_angle = radians(hash(center, seed + 4u) * 360.);
  float light_dist = (radius / 4.) + hash(center, seed + 5u) * (radius / 4.);

  float shape = sign(length(coords) - radius) < 0.5 ? rd_planet : 0.;
  float rotation = radians(hash(center, seed + 6u) * 360.);
  float time_speed = (hash(center, seed + 7u) + 1.) * 2.;
  float plan = hash(center, seed + 8u);
  vec2 light_origin = light_dist * vec2(cos(light_angle), sin(light_angle));

  Planet planet = Planet(shape, center, rotation, radius, time_speed, plan,
    light_origin, 0u, 0., 0., 0., 0.);
  if ((rd_planet < (DRY + RING) / 2.) && (rd_planet > (RING + GAZ) / 2.))
  {
    float ring_rotation = radians(hash(center, seed + 10u) * 360.);
    float ring_radius =
      hash(center, seed + 11u) * (0.2 + (planet.radius - 0.2) / 4.);
    float ring_width = hash(center, seed + 12u) * 0.06;
    float ring_angle = hash(center, seed + 13u) * 10. * (planet.radius - 0.2);

    vec3 res = computeRingShape(coords, planet, ring_rotation, ring_width,
      ring_radius, ring_angle);
    planet.type = max(res.x * rd_planet, planet.type);
    planet.ring = res.y;
    planet.ring_a = res.z;
    planet.turbulence = (uint(hash(center, seed + 9u) * 9.) + 1u) * 10u;
  } else if ((rd_planet < (MOON + LAND) / 2.) && (rd_planet > LAND / 2.)) {
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
    Planet(0., vec2(0.), 0., 0., 0., 0., vec2(0.), 0u, 0., 0., 0., 0.);
  Planet tmp =
    Planet(0., vec2(0.), 0., 0., 0., 0., vec2(0.), 0u, 0., 0., 0., 0.);
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
  if (planet.type < LAND / 2.)
  {
    color = vec4(-1.);// vec4(planet.type / PLANET_TYPES);
  } else if (planet.type < (MOON + LAND) / 2.) {
    color = land(coords, planet, dith);
  } else if (planet.type < (GAZ + MOON) / 2.) {
    color = moon(coords, planet, dith);
  } else if (planet.type < (RING + GAZ) / 2.) {
    color = gaz(coords, planet, dith);
  } else if (planet.type < (DRY + RING) / 2.) {
    color = ring(coords, planet, dith);
  } else {
    color = dry(coords, planet, dith);
  }
  return color;
}
