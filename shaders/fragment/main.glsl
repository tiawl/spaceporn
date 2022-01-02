# version 330 core

precision highp float;

# include "bigstars.glsl"
# include "dust.glsl"
# include "nebulae.glsl"
# include "planets.glsl"
# include "stars.glsl"

void main()
{
  if (!motion)
  {
    time = 0.0;
  }

  float motion_radius = 2. * max(resolution.x, resolution.y);
  vec2 offset = 2 * motion_radius + motion_radius
    * vec2(sin(MOTION_SPEED * time), sin(MOTION_SPEED * time * 0.75));

  if (!animation)
  {
    time = 0.0;
  } else {
    time = fflags[3] / 50.;
  }

  vec2 UV = (gl_FragCoord.xy + offset) / resolution;
  UV.x *= resolution.x / resolution.y;

  vec2 px = floor(UV * pixels);
  vec2 uv = px / pixels;
  bool dith = dither(1., uv, UV);

  vec4 col = vec4(0.);

  col = planets(UV, px, dith);
//   if (col.x == -1.)
//   {
//     col = max(bigstars(UV), max(stars(px), max(dust(px, dith),
//       nebulae(px, dith)) * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));
//   }

  fragColor = col;
}
