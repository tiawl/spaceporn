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

  float motion_radius = 2. * zoom;
  vec2 offset = 2 * motion_radius + motion_radius
    * vec2(sin(MOTION_SPEED * time), sin(MOTION_SPEED * time * 0.75));

  if (!animation)
  {
    time = 0.0;
  } else {
    time = fflags[3] / 50.;
  }

  vec2 UV = gl_FragCoord.xy / resolution;
  UV.x *= resolution.x / resolution.y;
  UV *= zoom;
  UV += offset;
  vec2 unzoomed_UV = UV / zoom;
  float px_ratio = resolution.y / pixels;

  vec2 unzoomed_px = floor(unzoomed_UV * pixels) * px_ratio;
  vec2 px = unzoomed_px * zoom;
  vec2 uv = ((px / px_ratio) / zoom) / pixels;
  bool dith = dither(1., uv, unzoomed_UV);

  vec4 col = vec4(0.);

//   col = planets(px, dith);
//   if (col.x == -1.)
//   {
//     col = max(bigstars(unzoomed_UV), max(stars(unzoomed_px), max(dust(px, dith),
//       nebulae(px, dith)) * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));
//   }

  col = bigstars(unzoomed_UV);//vec4(texture(atlas, vec3(2. * gl_FragCoord.xy / resolution, 0.)).xyz, 1.);

  fragColor = col;
}
