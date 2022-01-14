# include "header.glsl"

vec4 use_atlas()
{
  vec2 UV = 0.02 * gl_FragCoord.xy / resolution;
  UV.x *= resolution.x / resolution.y;
  vec4 col = vec4(texture(atlas, vec3(UV, 0.)).xyz, 1.);
  return col;
}
