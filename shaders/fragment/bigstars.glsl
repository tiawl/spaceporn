# include "hash.glsl"
# include "star/diamond.glsl"
# include "star/nova.glsl"
# include "star/polar.glsl"

float calc_square(vec2 xy, vec2 offset)
{
  float dd = 300.;
  vec2 ixy = vec2(floor_multiple(xy.x, dd),
    floor_multiple(xy.y, dd));
  ixy -= offset;
  vec2 center = ixy + dd/2.;

  //center += 0.5 + 0.5 * hash(ixy, seed + 0u);

  float angle = radians(hash(ixy, seed + 1u) * 360.);
  center.x += 0.5 * sin(angle);
  center.y += 0.5 * cos(angle);

//   float rd_bigstar = ceil(hash(ixy, seed + 2u) * 6.);
//   if (rd_bigstar < 1.)
//   {
//     rd_bigstar = 1.;
//   }

  //return diamond(xy, center, 100., 15.5, .003);
  //return nova(xy, center, 100., 15.5, .003);
  return polar(xy, center, 100., 0.4);
}

vec4 bigstars(vec2 uv)
{
  //uv *= 0.001 * bigstars_density;
  uv *= 0.2;
  float col_value = max(max(max(calc_square(uv, vec2(0.0, 0.0)),
    calc_square(uv, vec2(0.0, 1.0))), calc_square(uv, vec2(1.0, 0.0))),
    calc_square(uv, vec2(1.0, 1.0)));
  return vec4(floor(col_value * NB_COLS) / NB_COLS);
}
