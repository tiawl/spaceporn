# include "hash.glsl"
# include "star/diamond.glsl"
# include "star/nova.glsl"
# include "star/polar.glsl"

# define STAR_TYPES 3.

// float calc_star(vec2 coords, vec2 offset)
// {
//   float pixel_res = shorter_res / pixels;
//   float density = 20.;
//   density *= round(pixels / 100.);
//   density = pixel_res * density;
//   vec2 ixy = vec2(floor_multiple(coords.x, density),
//     floor_multiple(coords.y, density));
//   vec2 center = ixy + density / 2.;

//   //center += 0.5 + 0.5 * hash(ixy, seed + 0u);

//   //center.x += floor_multiple(hash(ixy, seed + 1u) * pixels, pixel_res);
//   //center.y += hash(ixy, seed + 2u) * (pixels / 2.);

//   float rd_bigstar = min(floor(hash(ixy, seed) * STAR_TYPES), STAR_TYPES - 1.);
//   float size_hash = hash(ixy, seed + 1u);
//   size_hash *= size_hash;
//   size_hash *= size_hash;
//   size_hash *= size_hash;
//   float size = (min(floor(size_hash * 10.), 9.) + 7.) * pixel_res;
//   float ring_size = hash(ixy, seed + 3u) * 1.5;
//   ring_size = ((ring_size < 0.5) || (size / pixel_res < 12.) ? 0. : ring_size);
//   uint sharpness = (size > 11.5 * pixel_res ?
//     1u + uint(max(1., ceil(hash(ixy, seed + 6u) * 15.))) : 2u);

//   Star bigstar = Star(rd_bigstar, center, 0., size, 120., 0., 0., sharpness,
//     2., ring_size);
//   if (bigstar.type < 0.5)
//   {
//     bigstar.brightness = 1.55 * (((bigstar.size / pixel_res)
//       * shorter_res / 200.) / 13.);
//     bool branch = hash(ixy, seed + 3u) > 0.5;
//     bigstar.shape = (hash(ixy, seed + 3u) + 2.) * bigstar.size / 5.4;
//     bigstar.shape *= branch ? 5. :
//       (hash(ixy, seed + 3u) > .5 ? 2. : 0.2);
//     bigstar.sharpness = branch ? 32u : 2u;
//   } else if (bigstar.type < 1.5) {
//     bigstar.diag = 2. + hash(ixy, seed + 5u) * 3.;
//     bigstar.diag = ((bigstar.diag < 2.1) && (bigstar.sharpness == 2u) &&
//       (((bigstar.size < 15.5 * pixel_res) && (bigstar.size > 14.5 * pixel_res)) ||
//       ((bigstar.size < 13.5 * pixel_res) && (bigstar.size > 12.5 * pixel_res)) ||
//       ((bigstar.size < 11.5 * pixel_res) && (bigstar.size > 10.5 * pixel_res))) ?
//         1.5 : bigstar.diag);
//     bigstar.brightness = 1.55 * (((bigstar.size / pixel_res)
//       * shorter_res / 200.) / 13.);
//     bigstar.brightness *= (bigstar.diag < 1.6 ?
//       1.8 : ((hash(ixy, seed + 4u) + 1.) / 2.));
//     bigstar.shape = novaShape(bigstar, pixel_res);
//   } else {
//     bigstar.brightness = 1.55 * (((bigstar.size / pixel_res)
//       * shorter_res / 200.) / 13.);
//     bigstar.diag = 2.5 + hash(ixy, seed + 5u) * 0.5;
//     bigstar.shape = polarShape(bigstar, pixel_res);
//   }

float calc_star(vec2 coords, vec2 o)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;

  vec2 i = floor(coords);
  vec2 f = fract(coords);
  vec2 center = i + o;
  vec2 h = vec2(floor_multiple(hash(center, seed), pixel_res),
    floor_multiple(hash(center, seed + 1u), pixel_res));
  coords = o /* + h */ - f;

  float rd_bigstar = 1.2;//min(floor(hash(center, seed + 2u) * STAR_TYPES), STAR_TYPES - 1.);
  float size_hash = hash(center, seed + 3u);
//   size_hash *= size_hash;
//   size_hash *= size_hash;
//   size_hash *= size_hash;
  float size = (min(floor(size_hash * 10.), 9.) + 7.) * pixel_res;
  float ring_size = hash(center, seed + 4u) * 1.5;
  ring_size = ((ring_size < 0.5) || (size / pixel_res < 12.) ? 0. : ring_size);
  uint sharpness = (size > 11.5 * pixel_res ?
    1u + uint(max(1., ceil(hash(center, seed + 5u) * 15.))) : 2u);

  Star bigstar = Star(rd_bigstar, center, 0., size, 120., 1., 1., 2u, 2.,
    ring_size);
  if (bigstar.type < 0.5)
  {
    bigstar.brightness = bigstar.size * (hash(center, seed + 6u) + 1.);
    bool branch = hash(center, seed + 7u) > 0.5;
    bigstar.shape = (hash(center, seed + 7u) + 2.) * bigstar.size / 5.4;
    bigstar.shape *= branch ? 5. :
      (hash(center, seed + 7u) > .5 ? 2. : 0.2);
    bigstar.sharpness = branch ? 32u : 2u;
    return diamond(coords, bigstar);
  } else if (bigstar.type < 1.5) {
    bigstar.diag = 2. + hash(center, seed + 6u) * 3.;
    bigstar.diag = ((bigstar.diag < 2.1) && (bigstar.sharpness == 2u) &&
      (((bigstar.size < 15.5 * pixel_res) && (bigstar.size > 14.5 * pixel_res)) ||
      ((bigstar.size < 13.5 * pixel_res) && (bigstar.size > 12.5 * pixel_res)) ||
      ((bigstar.size < 11.5 * pixel_res) && (bigstar.size > 10.5 * pixel_res))) ?
        1.5 : bigstar.diag);
    bigstar.brightness = bigstar.size * (hash(center, seed + 7u) + 1.);
    bigstar.brightness *= (bigstar.diag < 1.6 ?
      1.8 : ((hash(center, seed + 8u) + 1.) / 2.));
    bigstar.shape = novaShape(bigstar, pixel_res);
    return nova(coords, bigstar);
  }

//   uint sharpness = (size > 11.5 * pixel_res ?
//     1u + uint(max(1., ceil(hash(i, seed + 6u) * 15.))) : 2u);

//   Star bigstar = Star(rd_bigstar, center, 0., size, 120., 0., 0., sharpness,
//     2., ring_size);

//   if (bigstar.type < 0.5)
//   {
//     bigstar.brightness = 1.55 * (((bigstar.size / pixel_res)
//       * shorter_res / 200.) / 13.);
//     bool branch = hash(i, seed + 3u) > 0.5;
//     bigstar.shape = (hash(i, seed + 3u) + 2.) * bigstar.size / 5.4;
//     bigstar.shape *= branch ? 5. :
//       (hash(i, seed + 3u) > .5 ? 2. : 0.2);
//     bigstar.shape = 5.;
//     bigstar.sharpness = branch ? 32u : 2u;
//     return diamond(coords, bigstar);
//   } else if (bigstar.type < 1.5) {
//     bigstar.diag = 2. + hash(i, seed + 5u) * 3.;
//     bigstar.diag = ((bigstar.diag < 2.1) && (bigstar.sharpness == 2u) &&
//       (((bigstar.size < 15.5 * pixel_res) && (bigstar.size > 14.5 * pixel_res)) ||
//       ((bigstar.size < 13.5 * pixel_res) && (bigstar.size > 12.5 * pixel_res)) ||
//       ((bigstar.size < 11.5 * pixel_res) && (bigstar.size > 10.5 * pixel_res))) ?
//         1.5 : bigstar.diag);
//     bigstar.brightness = 1.55 * (((bigstar.size / pixel_res)
//       * shorter_res / 200.) / 13.);
//     bigstar.brightness *= (bigstar.diag < 1.6 ?
//       1.8 : ((hash(i, seed + 4u) + 1.) / 2.));
//     bigstar.shape = novaShape(bigstar, pixel_res);
//     return nova(coords, bigstar);
//   } else {
//     bigstar.brightness = 1.55 * (((bigstar.size / pixel_res)
//       * shorter_res / 200.) / 13.);
//     bigstar.diag = 2.5 + hash(i, seed + 5u) * 0.5;
//     bigstar.shape = polarShape(bigstar, pixel_res);
//     return polar(coords, bigstar);
//   }
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
//    rad = hash(i + o, seed) * 0.5;
//    h = vec2(hash(i + o, seed + 1u), hash(i + o, seed + 2u));
//

    c = calc_star(coords, o);
    d = min(d, c);
  }
  return vec4(vec3(-d), 1.);
  //return vec4(vec3(sqrt(sqrt(max(-d, 0.))) * 12.), 1.);
}
