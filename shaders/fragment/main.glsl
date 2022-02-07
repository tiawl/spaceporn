# include "header.glsl"
# include "coords.glsl"

void main()
{
  vec4 col = vec4(0.);
  if (precomputed)
  {
    col = atlas_main(gl_FragCoord.xy);
  } else {
    col = hash_main(gl_FragCoord.xy);
  }

  gl_FragColor = col;
}
