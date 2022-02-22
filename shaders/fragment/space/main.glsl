# include "space/bigstars/main.glsl"
# include "space/nebula.glsl"
# include "space/stars.glsl"

vec4 space(vec2 coords, vec2 stars_coords, bool dith)
{
  //vec4 stars = stars(stars_coords);
  precomputed = (precomputed != NO_ATLAS ? STARS_DONE : NO_ATLAS);
  vec4 bigstars = bigstars(coords / zoom);
  //vec4 nebula = nebula(coords, dith);
  vec4 col = bigstars;//max(bigstars, max(stars, nebula));
  return col;
}
