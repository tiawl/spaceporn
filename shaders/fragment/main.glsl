# version 330 core

precision highp float;

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
    float radius = 2. * max(resolution.x, resolution.y);
    m = 2 * radius + radius
      * vec2(sin(MOTION_SPEED * time), sin(MOTION_SPEED * time * 0.75));
  }

  if (!animation)
  {
    time = 0.0;
  }

  vec2 UV = (gl_FragCoord.xy + m) / resolution;
  UV.x *= resolution.x / resolution.y;

  vec2 px = floor(UV * pixels);
  vec2 uv = floor(UV * pixels) / pixels;
  bool psdith = dither(1., uv, UV);

  vec4 col = vec4(0.);

//   col = planets(UV, uv);

//   if (col.x == 0.)
//   {
//     col = max(bigstars(UV), max(stars(uv), max(nebulae(uv, psdith),
//       dust(uv, psdith)) * (sin(time * 2500.) * 0.025 + 1.)));
//   }

  col = max(bigstars(UV), max(stars(px), max(dust(px, psdith),
    nebulae(px, psdith)) * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));

  fragColor = col;
}
