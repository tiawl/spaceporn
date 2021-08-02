# version 330 core

# include "bigstars.glsl"
# include "dust.glsl"
# include "nebulae.glsl"
# include "planets.glsl"
# include "stars.glsl"

void main()
{
  vec2 m = vec2(0.);
  if (motion)
  {
    m = 2. * max(resolution.x, resolution.y) *
      vec2(sin(time), sin(time * 0.75));
  }

  if (!animation)
  {
    time = 0.0;
  }

  vec2 UV = (gl_FragCoord.xy + m) / resolution;
  UV.x *= resolution.x / resolution.y;

  vec2 uv = floor(UV * pixels) / pixels;
  bool psdith = dither(1., uv, UV);

  vec4 col = vec4(0.);

  col = planets(UV, uv);

  //if (col.x == 0.)
  if (col.x == -1.)
  {
    col = max(bigstars(UV), max(stars(uv), max(nebulae(uv, psdith),
      dust(uv, psdith)) * (sin(time * 2500.) * 0.025 + 1.)));
  }

  fragColor = col;
}
