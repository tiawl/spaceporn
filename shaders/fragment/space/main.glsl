# include "space/bigstars/main.glsl"
# include "space/dust.glsl"
# include "space/nebula.glsl"
# include "space/stars.glsl"

vec4 space(vec2 coords, vec2 stars_coords, bool dith)
{
  vec4 stars = stars(stars_coords);
  stars_computed = true;
  vec4 bigstars = bigstars(coords / zoom);
  vec4 dust = dust(coords, dith);
  vec4 nebula = nebula(coords, dith);
  vec4 col = max(bigstars, max(stars, max(dust, nebula)
    * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));
  return col;
}
