# include "atlas.glsl"
# include "compute.glsl"

void main()
{
  vec4 col = vec4(0.);
  if (precomputed)
  {
    col = use_atlas();
  } else {
    col = compute();
  }

  fragColor = col;
}
