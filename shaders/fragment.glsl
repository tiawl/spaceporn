# version 330 core

uniform float fflags[6];
uniform bvec3 bflags;
uniform sampler2D big_stars_texture;

out vec4 fragColor;

const float SIZE = 10.0;

const float planets_density = 1.; // WARNING: must be greater than 1 to avoid some artifacts
const float bigstars_density = 3.;

vec2 resolution = vec2(fflags[0], fflags[1]);
vec2 seed = vec2(fflags[2], fflags[3]);
float time = fflags[4];
float pixels = fflags[5];

bool animation = bflags.x;
bool motion = bflags.y;
bool palettes = bflags.z;

struct Planet
{
  float type;
  vec2 center;
  float rotation;
  float radius;
  vec2 seed;
  float time_speed;
  float plan;
  vec2 light_origin;
};

#define TEXTURE_SIZE vec2(256., 32.)
#define NB_COL 7.

/****************************************************************************
 *                                                                          *
 *                           PixelSpace Functions                           *
 *                                                                          *
 ****************************************************************************/

float psrand(vec2 coord)
{
  return fract(43757.5453 * sin(dot(coord, vec2(12.9898, 78.233))));
}

float psnoise(vec2 coord)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = psrand(i);
  float b = psrand(i + vec2(1.0, 0.0));
  float c = psrand(i + vec2(0.0, 1.0));
  float d = psrand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) + (c - a) * cubic.y *
    (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float psfbm(vec2 coord, uint octaves)
{
  float value = 0.0;
  float scale = 0.5;

  for(uint i = 0u; i < octaves; i++)
  {
    value += psnoise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float pscircleNoise(vec2 uv)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = psrand(vec2(floor(uv.x), floor(uv_y)));
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float pscloud_alpha(vec2 uv, uint octaves)
{
  float c_noise = 0.0;

  int iters = 2;
  for (int i = 0; i < iters; i++)
  {
    c_noise += pscircleNoise(uv * 0.5 + (float(i + 1)) + vec2(-0.3, 0.0));
  }
  float fbm = psfbm(uv + c_noise, octaves);

  return fbm;
}

/****************************************************************************
 *                                                                          *
 *                           PixelSpace Functions                           *
 *                                                                          *
 ****************************************************************************/

float pprand(float size, vec2 sizeModifier, vec2 coord)
{
  coord = mod(coord, sizeModifier * round(size));
  return psrand(coord);
}

float ppnoise(float size, vec2 sizeModifier, vec2 coord)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = pprand(size, sizeModifier, i);
  float b = pprand(size, sizeModifier, i + vec2(1.0, 0.0));
  float c = pprand(size, sizeModifier, i + vec2(0.0, 1.0));
  float d = pprand(size, sizeModifier, i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) + (c - a) * cubic.y *
    (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float ppfbm(float size, vec2 sizeModifier, vec2 coord, uint octaves)
{
  float value = 0.0;
  float scale = 0.5;

  for(uint i = 0u; i < octaves; i++)
  {
    value += ppnoise(size, sizeModifier, coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float ppcircleNoise(float size, vec2 sizeModifier, vec2 uv)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = pprand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)));
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float ppcloud_alpha(float size, vec2 sizeModifier, float time_speed, vec2 uv,
  uint octaves)
{
  float c_noise = 0.0;

  int iters = 9;
  for (int i = 0; i < iters; i++)
  {
    c_noise += ppcircleNoise(size, sizeModifier,
      (uv * size * 0.3) + (float(i + 1) + 10.0) +
        (vec2(time * time_speed, 0.0)));
  }
  float fbm = ppfbm(size, sizeModifier,
    uv * size + c_noise + vec2(time * time_speed, 0.0), octaves);

  return fbm;
}

/****************************************************************************
 *                                                                          *
 *                     PixelSpace & PixelPlanet utils                       *
 *                                                                          *
 ****************************************************************************/

vec2 rotate(vec2 vec, vec2 center, float angle)
{
  vec -= center;
  vec *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
  vec += center;
  return vec;
}

bool dither(float dither_size, vec2 uv1, vec2 uv2)
{
  return mod(uv1.x + uv2.y, 2.0 / pixels) * dither_size <= 1.0 / pixels;
}

/****************************************************************************
 *                                                                          *
 *                              Noise Animation                             *
 *                                                                          *
 ****************************************************************************/

mat2 makem2(float theta)
{
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c,-s,s,c);
}

vec2 dualfbm(vec2 p, uint octaves)
{
  vec2 p2 = p * 2.7;
  vec2 basis =
    vec2(psfbm(p2 - time * 1.6, octaves), psfbm(p2 + time * 1.7, octaves));
  basis = (basis - .5) * .2;
  p += basis;

  return p * makem2(time * .2);
}

/****************************************************************************
 *                                                                          *
 *                                 Nebulae                                  *
 *                                                                          *
 ****************************************************************************/

vec4 nebulae(vec2 uv, bool dith)
{
  uint octaves = 2u;
  uv = dualfbm(uv, octaves);

  float d = distance(uv, vec2(0.5)) * 0.4;

  float n = pscloud_alpha(uv * SIZE, octaves);
  float n2 = psfbm(uv * SIZE + vec2(1, 1), octaves);
  float n_lerp = n2 * n;
  float n_dust = pscloud_alpha(uv * SIZE, octaves);
  float n_dust_lerp = n_dust * n_lerp;

  float n_alpha = psfbm(uv * ceil(SIZE * 0.05) - vec2(1, 1), octaves);
  float a_dust = step(n_alpha , n_dust_lerp * 1.8);

  if (dith)
  {
    n_dust_lerp *= 0.95;
    n_lerp *= 0.95;
    d*= 0.98;
  }

  float a = step(n2, 0.1 + d);
  float a2 = step(n2, 0.115 + d);

  float col_value = 0.0;
  if (a2 > a) {
    col_value = floor(n_dust_lerp * 35.0) / NB_COL;
  } else {
    col_value = floor(n_dust_lerp * 14.0) / NB_COL;
  }

  return vec4(vec3(col_value), a2);
}

/****************************************************************************
 *                                                                          *
 *                                   Dust                                   *
 *                                                                          *
 ****************************************************************************/

vec4 dust(vec2 uv, bool dith)
{
  uint octaves = 8u;
  uv = dualfbm(uv, octaves);

  float n_alpha = psfbm(uv * ceil(SIZE * 0.5) + vec2(2, 2), octaves);
  float n_dust = pscloud_alpha(uv * SIZE, octaves);
  float n_dust2 = psfbm(uv * ceil(SIZE * 0.2) - vec2(2, 2), octaves);
  float n_dust_lerp = n_dust2 * n_dust;

  if (dith)
  {
    n_dust_lerp *= 0.95;
  }

  float a_dust = step(n_alpha , n_dust_lerp * 1.8);
  n_dust_lerp = pow(n_dust_lerp, 3.2) * 56.0;
  if (dith)
  {
    n_dust_lerp *= 1.1;
  }

  float col_value = floor(n_dust_lerp) / NB_COL;
  return vec4(vec3(col_value), a_dust);
}

/****************************************************************************
 *                                                                          *
 *                                 Stars                                    *
 *                                                                          *
 ****************************************************************************/

vec3 nrand3(vec2 co)
{
  vec3 a = fract(cos(co.x * 8.3e-3 + co.y) * vec3(1.3e5, 4.7e5, 2.9e5));
  vec3 b = fract(sin(co.x * 0.3e-3 + co.y) * vec3(8.1e5, 1.0e5, 0.1e5));
  vec3 c = mix(a, b, 0.5);
  return c;
}

vec4 stars(vec2 uv)
{
  const float stars_density = 20.;

  vec2 stars_seed = uv.xy * 2.0;
  stars_seed = floor(stars_seed * resolution.x);
  vec3 rnd = nrand3(stars_seed);
  vec4 starcolor = vec4(pow(rnd.y, stars_density));

  if (starcolor.x > 0.3)
  {
    float brighness_variance = max(0.15, psrand(uv) / 2.0f);
    return starcolor + (vec4(psrand((1. + fract(time)) * uv)
      * brighness_variance) - (brighness_variance / 2.));
  } else {
    return vec4(0.);
  }
}

/****************************************************************************
 *                                                                          *
 *                                  Land                                    *
 *                                                                          *
 ****************************************************************************/

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

  float c = ppcloud_alpha(size, vec2(1.0, 1.0), planet.time_speed,
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

/****************************************************************************
 *                                                                          *
 *                                   Moon                                   *
 *                                                                          *
 ****************************************************************************/

vec2 moonSpherify(vec2 uv, vec2 center, float radius)
{
  vec2 centered = (uv - center) * 2.;
  float z = sqrt(radius * radius * 4. - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

float circleNoiseCrater(float size, vec2 sizeModifier, vec2 uv)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = pprand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)));
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m);
}

float crater(float size, vec2 sizeModifier, float time_speed, vec2 uv)
{
  float c = 1.0;

  for (int i = 0; i < 2; i++)
  {
    c *= circleNoiseCrater(size, sizeModifier,
      (uv * size) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }

  return 1.0 - c;
}

vec4 computeCraters(vec2 uv, Planet planet)
{
  const float light_border_crater = 0.465;
  const float light_border_planet = 0.729;
  const float sizeCraters = 5.0;
  const float sizePlanet = 8.0;
  const vec3 craterColor1 = vec3(0.521);
  const vec3 craterColor2 = vec3(0.368);
  const uint octaves = 4u;

  float lratio = 1. / sqrt(planet.radius);
  float d_to_center = distance(uv, planet.center);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);
  uv = moonSpherify(uv, planet.center, planet.radius);

  float c1 = crater(sizeCraters, vec2(1.0), planet.time_speed, uv);
  float c2 = crater(sizeCraters, vec2(1.0), planet.time_speed,
    uv + (planet.light_origin - planet.center + vec2(0.5, 0.)) * 0.03);

  vec3 col = craterColor1;
  float a = step(0.5, c1);

  if (c2 < c1 - (0.5 - d_light) * 2.0)
  {
    col = craterColor2;
  }

  if (d_light > light_border_crater)
  {
    col = craterColor2;
  }

  d_light += ppfbm(sizePlanet, vec2(1.0),
    uv * sizePlanet + vec2(time * planet.time_speed, 0.0), octaves) * 0.3;

  if (d_light > light_border_planet)
  {
    col = craterColor2 * (1.- d_light) / (1. - light_border_planet);
  }

  a *= step(d_to_center, planet.radius);

  return vec4(col, a);
}

vec4 computeMoon(vec2 uv, Planet planet)
{
  const float size = 8.0;
  const float light_border_1 = 0.615;
  const float light_border_2 = 0.729;
  const vec3 color1 = vec3(0.760);
  const vec3 color2 = vec3(0.521);
  const vec3 color3 = vec3(0.368);
  const uint octaves = 4u;

  float lratio = 1. / sqrt(planet.radius);
  float d_circle = distance(uv, planet.center);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = rotate(uv, planet.center, planet.rotation);

  float a = step(d_circle, 1.);

  d_light += ppfbm(size, vec2(1.0),
    uv * size + vec2(time * planet.time_speed, 0.0), octaves) * 0.3;

  float p = (light_border_1 - d_light) / light_border_1;
  p = sqrt(p);
  vec3 col = color2 * (1 - p) + color1 * p;
  if (d_light > light_border_1)
  {
    p = (light_border_2 - d_light) / (light_border_2 - light_border_1);
    col = color3 * (1 - p) + color2 * p;
  }
  if (d_light > light_border_2)
  {
    col = color3 * (1. - d_light) / (1. - light_border_2);
  }

  return vec4(col, a);
}

vec4 moon(vec2 uv, Planet planet)
{
  planet.time_speed *= 3.;
  vec4 craters = computeCraters(uv, planet);
  if (craters.a == 0.)
  {
    return computeMoon(uv, planet);
  } else {
    return craters;
  }
}

/****************************************************************************
 *                                                                          *
 *                                 Planets                                  *
 *                                                                          *
 ****************************************************************************/

#define MOON 0.25
#define LAND 1.

float roundDown(float numToRound, float multiple)
{
  float remainder = mod(abs(numToRound), multiple);
  if (remainder == 0.)
  {
    return numToRound;
  } else if (numToRound < 0.) {
    return -(abs(numToRound) - remainder);
  } else {
    return numToRound - remainder;
  }
}

Planet calc_circle(vec2 xy, vec2 offset)
{
  vec2 ixy = vec2(roundDown(xy.x, planets_density),
    roundDown(xy.y, planets_density));
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

/****************************************************************************
 *                                                                          *
 *                               Big Stars                                  *
 *                                                                          *
 ****************************************************************************/

float calc_square(vec2 xy, vec2 offset)
{
  vec2 ixy = floor(xy) - offset;
  vec2 center = ixy + 0.5;

  center += 0.25 + 0.5 * psrand(ixy + 1000.0);

  float angle = radians(psrand(ixy + 1050.0) * 360.);
  center.x += 0.25 * sin(angle);
  center.y += 0.25 * cos(angle);

  vec2 uv_unit = (vec2(1.) / resolution) * bigstars_density;
  uv_unit.x *= resolution.x / resolution.y;

  float rd_bigstar = ceil(psrand(ixy + 500.) * 6.);
  if (rd_bigstar < 1.)
  {
    rd_bigstar = 1.;
  }

  float size = (max(resolution.x, resolution.y) / pixels) *
    (0.5 + psrand(ixy + 300.) * 0.4);

  vec2 dist_text_center = ceil(12.0 * size + 0.1) * uv_unit;
  float m = 2. * ((rd_bigstar - 1.) / rd_bigstar) - 1.;

  vec2 dist_center = vec2(xy.x - center.x, xy.y - center.y);

  if ((abs(dist_center.x) < dist_text_center.x) &&
    (abs(dist_center.y) < dist_text_center.y))
  {
    dist_center += floor(12.5 * size + 0.1) * uv_unit;
    dist_center.x += (25. * uv_unit.x * size) * (rd_bigstar - 1.);
    vec4 text = texture2D(big_stars_texture,
      dist_center / (size * uv_unit * TEXTURE_SIZE));
    if (text.a > 0.)
    {
      return text.x * ((psrand(ixy + 150. + fract(time)) * 0.5) + 1.);
    } else {
      return 0.;
    }
  } else {
    return 0.;
  }
}

vec4 bigstars(vec2 uv)
{
  uv *= bigstars_density;
  float col_value = max(max(max(calc_square(uv, vec2(0.0, 0.0)),
    calc_square(uv, vec2(0.0, 1.0))), calc_square(uv, vec2(1.0, 0.0))),
    calc_square(uv, vec2(1.0, 1.0)));
  return vec4(floor(col_value * NB_COL) / NB_COL);
}

/****************************************************************************
 *                                                                          *
 *                                   Main                                   *
 *                                                                          *
 ****************************************************************************/

void main()
{
  vec2 m = vec2(0.);
  if (motion)
  {
    m = 2. * max(resolution.x, resolution.y) * vec2(sin(time), sin(time * 0.75));
  }

  if (!animation)
  {
    time = 0.0;
  }

  vec2 UV = (gl_FragCoord.xy + m) / resolution;
  UV.x *= resolution.x / resolution.y;

  vec2 uv = floor((UV) * pixels) / pixels;
  bool psdith = dither(1., uv, UV);

  vec4 col;

  vec4 planets = planets(UV, uv);
  float planets_value = planets.x;

  //if (planets_value == 0.)
  if (planets_value == -1.)
  {
    col = max(bigstars(UV), max(stars(uv), max(nebulae(uv, psdith),
      dust(uv, psdith)) * (sin(time * 2500.) * 0.025 + 1.)));
  } else {
    col = planets;
  }

  fragColor = col;
}
