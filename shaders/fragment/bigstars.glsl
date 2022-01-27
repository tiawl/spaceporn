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

  float rd_bigstar = 1.;//min(floor(hash(ixy, seed) * STAR_TYPES), STAR_TYPES - 1.);
  float size_hash = hash(ixy, seed + 1u);
//   size_hash *= size_hash;
//   size_hash *= size_hash;
//   size_hash *= size_hash;
  float size = (min(floor(size_hash * 10.), 9.) + 7.) * pixel_res;
  float ring_size = hash(ixy, seed + 3u) * 1.5;
  ring_size = ((ring_size < 0.5) || (size / pixel_res < 12.) ? 0. : ring_size);
  uint sharpness = (size > 11.5 * pixel_res ?
    1u + uint(max(1., ceil(hash(ixy, seed + 6u) * 15.))) : 2u);
      //           NOVA                                    POLAR
      // 16u --> 5.0 | 3.5                            #  NOVA
      // 12u --> 4.5 | 3.5                            #  NOVA
      // 11u --> 4.5 | 3.5                            #  NOVA
      // 10u --> 4.5                                  #  NOVA
      //  8u --> 4.5                                  #  NOVA
      //  7u --> 4.3                                  #  NOVA
      //  6u --> less than 2.5                        #  less than 1.8
      //  4u --> less than 2.0                        #  less than 1.2
      //  3u --> less than 1.5                        #  less than 1.2
      //  2u --> if diag < 2. less than 1.0 else 4.5  #  less than 1.0

  Star bigstar = Star(rd_bigstar, center, 0., size, 120., 0., 0., sharpness,
    2., ring_size);
  if (bigstar.type < 0.5)
  {
    bigstar.brightness = (1. + float(bigstar.sharpness) / 7.) * (size / 13.)
      * ((hash(ixy, seed + 4u) + 1.) / 2.);
    bigstar.shape = 2.0 * (hash(ixy, seed + 3u) + 2.) * bigstar.size / 5.4;
    bigstar.sharpness = 2u;
  } else if (bigstar.type < 1.5) {
    bigstar.diag = 2. + hash(ixy, seed + 5u) * 3.;
    bigstar.diag = ((bigstar.diag < 2.1) && (bigstar.sharpness == 2u) &&
      (((bigstar.size < 15.5 * pixel_res) && (bigstar.size > 14.5 * pixel_res)) ||
      ((bigstar.size < 13.5 * pixel_res) && (bigstar.size > 12.5 * pixel_res)) ||
      ((bigstar.size < 11.5 * pixel_res) && (bigstar.size > 10.5 * pixel_res))) ?
        1.5 : bigstar.diag);
    bigstar.brightness = 1.55 * (size / 13.);
    bigstar.brightness *= (bigstar.diag < 1.6 ?
      1.8 : ((hash(ixy, seed + 4u) + 1.) / 2.));
    bigstar.shape = novaShape(bigstar, pixel_res);
  } else {
    bigstar.brightness = (1. + float(bigstar.sharpness) / 7.) * (size / 13.)
      * ((hash(ixy, seed + 4u) + 1.) / 2.);
    bigstar.diag = 2.5 + hash(ixy, seed + 5u) * 0.5;
    bigstar.shape = pixel_res * polarShape(bigstar);
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
