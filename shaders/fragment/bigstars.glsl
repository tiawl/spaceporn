# include "hash.glsl"
# include "star/diamond.glsl"
# include "star/nova.glsl"
# include "star/polar.glsl"

# define STAR_TYPES 3.

Star calc_star(vec2 xy)
{
  float pixel_res = shorter_res / pixels;
  float density = 20.;
  density *= round(pixels / 100.);
  density = pixel_res * density;
  vec2 ixy = vec2(floor_multiple(xy.x, density),
    floor_multiple(xy.y, density));
  vec2 center = ixy + density / 2.;

  //center += 0.5 + 0.5 * hash(ixy, seed + 0u);

//   center.x += hash(ixy, seed + 1u) * (pixels / 2.);
//   center.y += hash(ixy, seed + 2u) * (pixels / 2.);

  float rd_bigstar = 0.;//min(floor(hash(ixy, seed) * STAR_TYPES), STAR_TYPES - 1.);
  float size_hash = hash(ixy, seed + 1u);
//   size_hash *= size_hash;
//   size_hash *= size_hash;
//   size_hash *= size_hash;
  float size = (min(floor(size_hash * 10.), 9.) + 7.) * pixel_res;
  float ring_size = hash(ixy, seed + 3u) * 1.5;
  ring_size = ((ring_size < 0.5) || (size / pixel_res < 12.) ? 0. : ring_size);
  uint sharpness = 1u + uint(max(1., ceil(hash(ixy, seed + 6u) * 15.)));

  Star bigstar = Star(rd_bigstar, center, 0., size, 120., 0., 0., sharpness,
    2., ring_size);
  if (bigstar.type < 0.5)
  {
    bigstar.brightness = (1. + float(bigstar.sharpness) / 7.) * (size / 13.)
      * ((hash(ixy, seed + 4u) + 1.) / 2.);
    bigstar.shape = 2.0 * (hash(ixy, seed + 3u) + 2.) * bigstar.size / 5.4;
    bigstar.sharpness = 2u;
  } else if (bigstar.type < 1.5) {
    bigstar.brightness = (1. + float(bigstar.sharpness) / 15.) * 1.55
      * (size / 13.) * ((hash(ixy, seed + 4u) + 1.) / 2.);
    bigstar.shape = (2. + (0.5 * float(bigstar.sharpness))) * hash(ixy, seed + 3u)
      * bigstar.size / 5.4;
    bigstar.diag = 2. + hash(ixy, seed + 5u) * 3.;
  } else {
    bigstar.brightness = (1. + float(bigstar.sharpness) / 7.) * (size / 13.)
      * ((hash(ixy, seed + 4u) + 1.) / 2.);
    bigstar.shape = (1. + float(bigstar.sharpness) / 2.) * hash(ixy, seed + 3u)
      * bigstar.size / 5.4;
    bigstar.diag = 2.5 + hash(ixy, seed + 5u) * 0.5;
  }
  return bigstar;
}

vec4 bigstars(vec2 uv)
{
  Star bigstar = calc_star(uv);
  if (bigstar.type < 0.5)
  {
    return diamond(uv, bigstar);
  } else if (bigstar.type < 1.5) {
    return nova(uv, bigstar);
  } else {
    return polar(uv, bigstar);
  }
}
