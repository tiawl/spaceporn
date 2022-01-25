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
  size_hash *= size_hash;
  size_hash *= size_hash;
  size_hash *= size_hash;
  float size = (min(floor(size_hash * 14.), 13.) + 3.) * pixel_res;

  Star bigstar = Star(rd_bigstar, center, 0., size, 120., 15.5, 0., 2u, 2.);
  if (bigstar.type < 0.5)
  {
    //bigstar.shape = 100.;
  } else if (bigstar.type < 1.5) {
    //bigstar.shape = 60.;
    bigstar.diag = 2.;
  } else {
    //bigstar.shape = 35.;
    bigstar.diag = 3.;
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
