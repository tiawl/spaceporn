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

#define TEXTURE_SIZE vec2(256., 32.)
#define NB_COL 7.

/****************************************************************************
 *                                                                          *
 *                            Random and Noises                             *
 *                                                                          *
 ****************************************************************************/

float rand(vec2 coord)
{
  return fract(43757.5453 * sin(dot(coord, vec2(12.9898, 78.233))));
}

float noise(vec2 coord)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) + (c - a) * cubic.y *
    (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord, uint octaves)
{
  float value = 0.0;
  float scale = 0.5;

  for(uint i = 0u; i < octaves; i++)
  {
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
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
    vec2(fbm(p2 - time * 1.6, octaves), fbm(p2 + time * 1.7, octaves));
  basis = (basis - .5) * .2;
  p += basis;

  return p * makem2(time * .2);
}

/****************************************************************************
 *                                                                          *
 *                            Deep-Fold Functions                           *
 *                                                                          *
 ****************************************************************************/

bool dither(vec2 uv1, vec2 uv2)
{
  return mod(uv1.y + uv2.x, 2.0 / pixels) <= 1.0 / pixels;
}

float circleNoise(vec2 uv)
{
  float uv_y = floor(uv.y);
  uv.x += uv_y * .31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uv_y)));
  float m = (length(f - 0.25 - (h * 0.5)));
  float r = h*0.25;
  return smoothstep(0.0, r, m * 0.75);
}

vec2 rotate(vec2 vec, vec2 center, float angle)
{
  vec -= center;
  vec *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
  vec += center;
  return vec;
}

float cloud_alpha(vec2 uv, uint octaves)
{
  float c_noise = 0.0;

  // more iterations for more turbulence
  int iters = 2;
  for (int i = 0; i < iters; i++)
  {
    c_noise += circleNoise(uv * 0.5 + (float(i + 1)) + vec2(-0.3, 0.0));
  }
  float fbm = fbm(uv + c_noise, octaves);

  return fbm;
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
  float n = cloud_alpha(uv * size, octaves);
  float n2 = fbm(uv * size + vec2(1, 1), octaves);
  float n_lerp = n2 * n;
  float n_dust = cloud_alpha(uv * size, octaves);
  float n_dust_lerp = n_dust * n_lerp;

  // noise for the shape of the nebulae
  float n_alpha = fbm(uv * ceil(size * 0.05) - vec2(1, 1), octaves);
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
  float n_alpha = fbm(uv * ceil(size * 0.5) + vec2(2, 2), octaves);
  float n_dust = cloud_alpha(uv * size, octaves);
  float n_dust2 = fbm(uv * ceil(size * 0.2) - vec2(2, 2), octaves);
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
    float brighness_variance = max(0.15, rand(uv) / 2.0f);
    return starcolor + (vec3(rand((1. + fract(time)) * uv)
      * brighness_variance) - (brighness_variance / 2.));
  } else {
    return vec3(0.);
  }
}

/****************************************************************************
 *                                                                          *
 *                                 Planets                                  *
 *                                                                          *
 ****************************************************************************/

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

float calc_circle(vec2 xy, vec2 offset)
{
  vec2 ixy = vec2(roundDown(xy.x, planet_density),
    roundDown(xy.y, planet_density));
  ixy -= offset;
  vec2 center = ixy + planet_density * 0.5;

  float radius = 0.05 + 0.2 * rand(ixy + 100.0);
  center += planet_density * 0.25 + planet_density * 0.5 * rand(ixy);

  float angle = radians(rand(ixy + 50.0) * 360.);
  center.x += planet_density * 0.1 * sin(angle);
  center.y += planet_density * 0.1 * cos(angle);
  center.x += 0.1 * sin(angle * time * 10. * (rand(ixy + 150.0)));
  center.y += 0.1 * cos(angle * time * 10. * (rand(ixy + 150.0)));

  vec2 d = xy - center;
  float hsq = d.x*d.x + d.y*d.y;

  return (1.0 - smoothstep(radius, radius + 0.01, hsq)) *
    (ceil(rand(ixy * 620.) * 4.0) / 4.);
}

vec3 planets(vec2 uv)
{
  uv *= 5.;
  float col_value = max(calc_circle(uv, vec2(0.0, 0.0)),
    max(calc_circle(uv, vec2(0.0, planet_density)),
    max(calc_circle(uv, vec2(planet_density, 0.0)),
    calc_circle(uv, vec2(planet_density, planet_density)))));
  return vec3(floor(col_value * NB_COL) / NB_COL);
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

  center += 0.25 + 0.5 * rand(ixy + 1000.0);

  float angle = radians(rand(ixy + 1050.0) * 360.);
  center.x += 0.25 * sin(angle);
  center.y += 0.25 * cos(angle);

  vec2 uv_unit = (vec2(1.) / resolution) * bigstars_density;
  uv_unit.x *= resolution.x / resolution.y;

  float rd_bigstar = ceil(rand(ixy + 500.) * 6.);
  if (rd_bigstar < 1.)
  {
    rd_bigstar = 1.;
  }

  float bigstar_size = (max(resolution.x, resolution.y) / pixels) *
    (0.5 + rand(ixy + 300.) * 0.4);

  vec2 dist_text_center = ceil(12.0 * bigstar_size + 0.1) * uv_unit;
  float m = 2. * ((rd_bigstar - 1.) / rd_bigstar) - 1.;

  //xy = rotate(xy, center, radians(rand(ixy + 400.) * 360.));
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
      return text.x * ((rand(ixy + 150. + fract(time)) * 0.5) + 1.);
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
  bool dith = dither(uv, UV);

  vec4 col;

  vec4 planets = vec4(planets(uv), 1.);
  float planets_value = planets.x;

  if (planets_value == -1.)
  {
    vec4 nebulae = nebulae(uv, dith);
    vec4 dust = dust(uv, dith);
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
