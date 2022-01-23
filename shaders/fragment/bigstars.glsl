# include "hash.glsl"
# include "star/diamond.glsl"
# include "star/nova.glsl"
# include "star/polar.glsl"

float calc_square(vec2 xy)
{
  float pixel_res = shorter_res / pixels;
  float density = 20.;
  density = pixel_res * density * 2.;
  vec2 ixy = vec2(floor_multiple(xy.x, density),
    floor_multiple(xy.y, density));
  vec2 center = ixy + density / 2.;

  //center += 0.5 + 0.5 * hash(ixy, seed + 0u);

//   center.x += hash(ixy, seed + 1u) * (pixels / 2.);
//   center.y += hash(ixy, seed + 2u) * (pixels / 2.);

  float rd_bigstar = min(floor(hash(ixy, seed) * 3.), 2.0);

  float bigstar = 1.;
  if (rd_bigstar < 0.5)
  {
    bigstar = diamond(xy, center, 100., 15.5, 120., 2u);
  } else if (rd_bigstar < 1.5) {
    bigstar = nova(xy, center, 100., 15.5, 60., 2u, 2.);
  } else {
    bigstar = polar(xy, center, 100., 15.5, 45., 2u, 3.);
  }
  return bigstar;
}

vec4 bigstars(vec2 uv)
{
  //uv *= 0.001 * bigstars_density;
  //uv *= 0.2;
  float col_value = calc_square(uv);
  return vec4(floor(col_value * 20.) / 20.);
}
