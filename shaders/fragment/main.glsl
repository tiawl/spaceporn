# include "header.glsl"
# include "coords.glsl"

void main()
{
  vec4 col = vec4(0.);
  vec2 UV = gl_FragCoord.xy / resolution;
  if (precomputed)
  {
    col = atlas_coords(UV);
  } else {
    col = hash_coords(UV);
  }

  gl_FragColor = col;
}
