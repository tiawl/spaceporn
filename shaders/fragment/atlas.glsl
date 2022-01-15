# include "header.glsl"

vec4 use_atlas(vec2 UV)
{
  vec4 col = vec4(texture(atlas, vec3(UV, 0.)).xyz, 1.);
  return col;
}
