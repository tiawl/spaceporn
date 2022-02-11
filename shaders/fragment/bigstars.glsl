# include "hash.glsl"
# include "star/diamond.glsl"
# include "star/nova.glsl"
# include "star/polar.glsl"

# define STAR_TYPES 3.

float calc_star(vec2 coords, vec2 o)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;

  vec2 i = floor(coords);
  vec2 f = fract(coords);
  vec2 center = i + o;
  vec2 h = vec2(floor_multiple(hash(center, seed), pixel_res),
    floor_multiple(hash(center, seed + 1u), pixel_res));
  coords = o + h - f;

  float rd_bigstar = 0.2;//min(floor(hash(center, seed + 2u) * STAR_TYPES), STAR_TYPES - 1.);
  float size_hash = hash(center, seed + 3u);
//   size_hash *= size_hash;
//   size_hash *= size_hash;
//   size_hash *= size_hash;
  float size = (min(floor(size_hash * 10.), 9.) + 7.) * pixel_res;
  float brightness = hash(center, seed + 4u) + 1.;
  float ring_size = hash(center, seed + 5u) * 1.5;
  ring_size = ((ring_size < 0.5) || (size / pixel_res < 11.5) ? 0. : ring_size);
  ring_size = (brightness < 1.5) ? 0. : ring_size;

  float star = 0.;
  Star bigstar =
    Star(rd_bigstar, center, size, 120., 1., 1., 2u, 2., ring_size);
  if (bigstar.type < 0.5)
  {
    bool rotation = hash(center, seed + 8u) > 0.5;
    bigstar.brightness = bigstar.size * brightness;
    coords = rotate(coords, vec2(0.), radians(rotation ? 45. : 0.));
    bigstar.shape = ((bigstar.size / pixel_res < 10.) &&
      rotation ? 2. * distance(vec2(0.), coords) : 0.0001);
    bigstar.sharpness = 2u;
    star = diamond(coords, bigstar);
  } else if (bigstar.type < 1.5) {
    bigstar.diag = 2. + hash(center, seed + 6u) * 3.;
    bigstar.diag = ((bigstar.diag < 2.1) && (bigstar.sharpness == 2u) &&
      (((bigstar.size < 15.5 * pixel_res) && (bigstar.size > 14.5 * pixel_res)) ||
      ((bigstar.size < 13.5 * pixel_res) && (bigstar.size > 12.5 * pixel_res)) ||
      ((bigstar.size < 11.5 * pixel_res) && (bigstar.size > 10.5 * pixel_res))) ?
        1.5 : bigstar.diag);
    bigstar.brightness = bigstar.size * brightness;
    bigstar.brightness *= (bigstar.diag < 1.6 ?
      0.9 : ((hash(center, seed + 7u) + 1.) / 2.));
    bigstar.sharpness = (bigstar.size > 11.5 * pixel_res ?
      1u + uint(max(1., ceil(hash(center, seed + 8u) * 15.))) : 2u);
    bigstar.shape = novaShape(bigstar, pixel_res);
    star = nova(coords, bigstar);
  } else {
    bigstar.brightness = bigstar.size * brightness;
    bigstar.diag = 2.5 + hash(center, seed + 6u) * 0.5;
    bigstar.sharpness = (bigstar.size > 11.5 * pixel_res ?
      1u + uint(max(1., ceil(hash(bigstar.center, seed + 7u) * 15.))) : 2u);
    bigstar.shape = polarShape(bigstar, pixel_res);
    star = polar(coords, bigstar);
  }
  return star;
}

vec4 bigstars(vec2 coords)
{
  coords *= BIGSTARS_DENSITY;
  float d = 1e9,
        c;
  vec2 o;

  for (int k = 0; k < 9; k++)
  {
    o = vec2(k % 3, k / 3) - 1.;
    c = calc_star(coords, o);
    d = min(d, c);
  }
  return vec4(vec3(-d), 1.);
}
