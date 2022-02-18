# include "space/bigstars/main.glsl"
# include "space/dust.glsl"
# include "space/nebula.glsl"
# include "space/stars.glsl"

vec4 space(vec2 coords, bool dith)
{
  vec4 col = bigstars(coords / zoom);
//   vec4 col = max(bigstars(coords / zoom), max(stars(hcoords),
//     max(dust(coords, dith), nebula(coords, dith))
//       * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));
  return col;
}
