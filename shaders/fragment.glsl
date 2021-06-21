# version 330 core

uniform float fflags[6];
uniform bvec3 bflags;
uniform sampler2D big_stars_texture;

out vec4 fragColor;

float size = 10.0;

float star_density = 20.;
float planet_density = 1.; // WARNING: must be greater than 1 to avoid some artifacts
float bigstars_density = 3.;

vec2 resolution = vec2(fflags[0], fflags[1]);
vec2 seed = vec2(fflags[2], fflags[3]);
float time = fflags[4];
float pixels = fflags[5];

bool animation = bflags.x;
bool motion = bflags.y;
bool palettes = bflags.z;

// Land
float dither_size = 3.951;
float planet_size = 4.6;
float river_cutoff = 0.368;
float light_border_1 = 0.52;
float light_border_2 = 0.62;

vec3 col1 = vec3(0.388, 0.670, 0.247);
vec3 col2 = vec3(0.231, 0.490, 0.309);
vec3 col3 = vec3(0.184, 0.341, 0.325);
vec3 col4 = vec3(0.156, 0.207, 0.250);
vec3 river_col = vec3(0.309, 0.643, 0.721);
vec3 river_col_dark = vec3(0.250, 0.286, 0.450);

// Clouds
float cloud_curve = 1.3;
float size_clouds = 7.315;
float stretch = 2.0;
float cloud_cover = 0.47;
float light_border_clouds_1 = 0.52;
float light_border_clouds_2 = 0.62;

vec3 base_color = vec3(0.960, 1.000, 0.909);
vec3 outline_color = vec3(0.874, 0.878, 0.909);
vec3 shadow_base_color = vec3(0.407, 0.435, 0.6);
vec3 shadow_outline_color = vec3(0.250, 0.286, 0.450);

struct Planet
{
  float type;
  vec2 center;
  float rotation;
  float radius;
  vec2 seed;
  float time_speed;
  float plan;
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

  // more iterations for more turbulence
  int iters = 2;
  for (int i = 0; i < iters; i++)
  {
    c_noise += pscircleNoise(uv * 0.5 + (float(i + 1)) + vec2(-0.3, 0.0));
  }
  float fbm = psfbm(uv + c_noise, octaves);

  return fbm;
}

bool psdither(vec2 uv1, vec2 uv2)
{
  return mod(uv1.y + uv2.x, 2.0 / pixels) <= 1.0 / pixels;
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

  // more iterations for more turbulence
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

bool ppdither(vec2 uv1, vec2 uv2)
{
  return mod(uv1.x + uv2.y, 2.0 / pixels) * dither_size <= 1.0 / pixels;
}

/****************************************************************************
 *                                                                          *
 *                     PixelSpace & PixelPlanet utils                       *
 *                                                                          *
 ****************************************************************************/

vec2 spherify(vec2 uv, vec2 center, float diameter)
{
  vec2 centered = uv - center;
  float z = sqrt(diameter - dot(centered.xy, centered.xy));
  vec2 sphere = centered/(z + 1.0);
  return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 vec, vec2 center, float angle)
{
  vec -= center;
  vec *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
  vec += center;
  return vec;
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
  //get two rotated fbm calls and displace the domain
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

  // distance from center
  float d = distance(uv, vec2(0.5)) * 0.4;

  // noise for the inside of the nebulae
  float n = pscloud_alpha(uv * size, octaves);
  float n2 = psfbm(uv * size + vec2(1, 1), octaves);
  float n_lerp = n2 * n;
  float n_dust = pscloud_alpha(uv * size, octaves);
  float n_dust_lerp = n_dust * n_lerp;

  // noise for the shape of the nebulae
  float n_alpha = psfbm(uv * ceil(size * 0.05) - vec2(1, 1), octaves);
  float a_dust = step(n_alpha , n_dust_lerp * 1.8);

  // apply dithering
  if (dith)
  {
    n_dust_lerp *= 0.95;
    n_lerp *= 0.95;
    d*= 0.98;
  }

  // slightly offset alpha values to create thin bands around the nebulae
  float a = step(n2, 0.1 + d);
  float a2 = step(n2, 0.115 + d);

  float col_value = 0.0;
  if (a2 > a) {
    col_value = floor(n_dust_lerp * 35.0) / NB_COL;
  } else {
    col_value = floor(n_dust_lerp * 14.0) / NB_COL;
  }

  return vec4(vec3(col_value), a2) * (sin(time * 1000.) * 0.05 + 1.);
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

  // noise for the dust
  // the + vec2(x,y) is to create an offset in noise values
  float n_alpha = psfbm(uv * ceil(size * 0.5) + vec2(2, 2), octaves);
  float n_dust = pscloud_alpha(uv * size, octaves);
  float n_dust2 = psfbm(uv * ceil(size * 0.2) - vec2(2, 2), octaves);
  float n_dust_lerp = n_dust2 * n_dust;

  // apply dithering
  if (dith)
  {
    n_dust_lerp *= 0.95;
  }

  // choose alpha value
  float a_dust = step(n_alpha , n_dust_lerp * 1.8);
  n_dust_lerp = pow(n_dust_lerp, 3.2) * 56.0;
  if (dith)
  {
    n_dust_lerp *= 1.1;
  }

  float col_value = floor(n_dust_lerp) / NB_COL;
  return vec4(vec3(col_value), a_dust) * (sin(time * 1000.) * 0.05 + 1.);
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

vec3 stars(vec2 uv)
{
  vec2 stars_seed = uv.xy * 2.0;
  stars_seed = floor(stars_seed * resolution.x);
  vec3 rnd = nrand3(stars_seed);
  vec3 starcolor = vec3(pow(rnd.y, star_density));

  if (starcolor.x > 0.3)
  {
    float brighness_variance = max(0.15, psrand(uv) / 2.0f);
    return starcolor + (vec3(psrand((1. + fract(time)) * uv)
      * brighness_variance) - (brighness_variance / 2.));
  } else {
    return vec3(0.);
  }
}

/****************************************************************************
 *                                                                          *
 *                              Land Planet                                 *
 *                                                                          *
 ****************************************************************************/

vec4 computeClouds(vec2 uv, Planet planet)
{
  uint octaves = 2u;
  float d_to_center = distance(uv, planet.center);

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius * 2.);

  uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

  float c = ppcloud_alpha(size_clouds, vec2(1.0, 1.0), planet.time_speed,
    (uv + planet.seed) * vec2(1.0, stretch), octaves);

  // assign some colors based on cloud depth & distance from light
  vec3 col = base_color;
  if (c < cloud_cover + 0.03)
  {
    col = outline_color;
  }
  if (d_to_center + c * 0.2 > light_border_clouds_1)
  {
    col = shadow_base_color;
  }
  if (d_to_center + c * 0.2 > light_border_clouds_2)
  {
    col = shadow_outline_color;
  }

  c *= step(d_to_center, 0.5);

  return vec4(col, step(cloud_cover, c));
}

vec4 computeLand(vec2 uv, Planet planet, bool dith)
{
  uint octaves = 5u;
  float d_light = distance(uv, planet.center);

  uv = rotate(uv, planet.center, planet.rotation);
  uv = spherify(uv, planet.center, planet.radius * 2.);

  vec2 base_fbm_uv = (uv + planet.seed) * planet_size +
    vec2(time * planet.time_speed, 0.0);

  float fbm1 = ppfbm(planet_size, vec2(2.0, 1.0), base_fbm_uv, octaves);
  float fbm2 = ppfbm(planet_size, vec2(2.0, 1.0),
    base_fbm_uv - planet.center * fbm1, octaves);
  float fbm3 = ppfbm(planet_size, vec2(2.0, 1.0),
    base_fbm_uv - planet.center * 1.5 * fbm1, octaves);
  float fbm4 = ppfbm(planet_size, vec2(2.0, 1.0),
    base_fbm_uv - planet.center * 2.0 * fbm1, octaves);

  float river_fbm =
    ppfbm(planet_size, vec2(2.0, 1.0), base_fbm_uv + fbm1 * 6.0, octaves);
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

  d_light = pow(d_light, 2.0) * 0.4;
  vec3 col = col4;
  if (fbm4 + d_light < fbm1 * 1.5)
  {
    col = col3;
  }
  if (fbm3 + d_light < fbm1 * 1.0)
  {
    col = col2;
  }
  if (fbm2 + d_light < fbm1)
  {
    col = col1;
  }
  if (river_fbm < fbm1 * 0.5)
  {
    col = river_col_dark;
    if (fbm4 + d_light < fbm1 * 1.5)
    {
      col = river_col;
    }
  }

  return vec4(col, step(distance(vec2(0.5), uv), 0.5));
}

vec4 landplanet(vec2 uv, Planet planet, bool dith)
{
  vec4 clouds = computeClouds(uv, planet);
  if (clouds.a == 0.)
  {
    return computeLand(uv, planet, dith);
  } else {
    return clouds;
  }
}

/****************************************************************************
 *                                                                          *
 *                                 Planets                                  *
 *                                                                          *
 ****************************************************************************/

#define LAND_PLANET 1.

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
  vec2 ixy = vec2(roundDown(xy.x, planet_density),
    roundDown(xy.y, planet_density));
  ixy -= offset;
  vec2 center = ixy + planet_density * 0.5;

  float radius = 0.2 + 0.4 * psrand(ixy + 100.0);
  center += planet_density * 0.25 + planet_density * 0.5 * psrand(ixy);

  float angle = radians(psrand(ixy + 50.0) * 360.);
  center.x += planet_density * 0.1 * sin(angle);
  center.y += planet_density * 0.1 * cos(angle);
  center.x += 0.1 * sin(angle * time * 10. * (psrand(ixy + 150.0)));
  center.y += 0.1 * cos(angle * time * 10. * (psrand(ixy + 150.0)));

  vec2 d = xy - center;
  float hsq = d.x * d.x + d.y * d.y;

  float rd_planet = ceil(psrand(ixy + 620.) * 4.);
  if (rd_planet < 1.)
  {
    rd_planet = 1.;
  }
  rd_planet = rd_planet / 4.;

  return Planet(step(distance(xy, center), radius) * rd_planet,
    center, radians(psrand(ixy - 20.0) * 360.), radius,
    vec2(psrand(ixy + 840.), psrand(ixy + 480.)), psrand(ixy - 90.) * 5.,
    psrand(ixy - 520.));
}

vec4 planets(vec2 uv, bool dith)
{
  uv *= 5.;

  Planet calc[4] = Planet[4](
    calc_circle(uv, vec2(0., 0.)), calc_circle(uv, vec2(planet_density, 0.)),
    calc_circle(uv, vec2(0., planet_density)),
    calc_circle(uv, vec2(planet_density, planet_density))
  );

  int index = 0;
  Planet planet = Planet(0., vec2(0.), 0., 0., vec2(0.), 0., 0.);

  while (index < 4)
  {
    if ((calc[index].type > 0.) && (planet.plan < calc[index].plan))
    {
      planet = calc[index];
    }
    ++index;
  }

  if (planet.type == LAND_PLANET)
  {
    return landplanet(uv, planet, dith);
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

  float bigstar_size = (max(resolution.x, resolution.y) / pixels) *
    (0.5 + psrand(ixy + 300.) * 0.4);

  vec2 dist_text_center = ceil(12.0 * bigstar_size + 0.1) * uv_unit;
  float m = 2. * ((rd_bigstar - 1.) / rd_bigstar) - 1.;

  vec2 dist_center = vec2(xy.x - center.x, xy.y - center.y);

  if ((abs(dist_center.x) < dist_text_center.x) &&
    (abs(dist_center.y) < dist_text_center.y))
  {
    dist_center += floor(12.5 * bigstar_size + 0.1) * uv_unit;
    dist_center.x += (25. * uv_unit.x * bigstar_size) * (rd_bigstar - 1.);
    vec4 text = texture2D(big_stars_texture,
      dist_center / (bigstar_size * uv_unit * TEXTURE_SIZE));
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

vec3 bigstars(vec2 uv)
{
  uv *= bigstars_density;
  float col_value = max(max(max(calc_square(uv, vec2(0.0, 0.0)),
    calc_square(uv, vec2(0.0, 1.0))), calc_square(uv, vec2(1.0, 0.0))),
    calc_square(uv, vec2(1.0, 1.0)));
  return vec3(floor(col_value * NB_COL) / NB_COL);
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

  vec2 UV = (gl_FragCoord.xy + m) / resolution;
  UV.x *= resolution.x / resolution.y;

  // pixelizing and dithering
  vec2 uv = floor((UV) * pixels) / pixels;
  bool psdith = psdither(uv, UV);
  bool ppdith = ppdither(uv, UV);

  vec4 col;

  vec4 planets = planets(uv, ppdith);
  float planets_value = planets.x;

  //if (planets_value == 0.)
  if (planets_value == -1.)
  {
    vec4 nebulae = nebulae(uv, psdith);
    vec4 dust = dust(uv, psdith);
    vec4 stars = vec4(stars(uv), 1.);
    vec4 bigstars = vec4(bigstars(UV), 1.);

    float nebulae_value = nebulae.x;
    float dust_value = dust.x;
    float stars_value = stars.x;
    float bigstars_value = bigstars.x;

    float max_value = max(bigstars_value, max(stars_value,
      max(dust_value, nebulae_value)));

    if (max_value == nebulae_value)
    {
      col = nebulae;
    } else if (max_value == dust_value) {
      col = dust;
    } else if (max_value == stars_value) {
      col = stars;
    } else {
      col = bigstars;
    }
  } else {
    col = planets;
  }

  fragColor = col;
}
