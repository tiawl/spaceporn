# include "header.glsl"
# include "bigstars.glsl"
# include "dust.glsl"
# include "nebulae.glsl"
# include "planets.glsl"
# include "stars.glsl"

vec4 atlas_coords(vec2 UV)
{
  vec2 t = textureSize(atlas, 0).xy;

  if (!motion)
  {
    time = 0.0;
  }

  float motion_radius = 2. * zoom;
  vec2 offset = (motion_radius / t.x)
    * vec2(sin(MOTION_SPEED * time), sin(MOTION_SPEED * time * 0.75));

  if (!animation)
  {
    time = 0.0;
  } else {
    time = fflags[3] / 50.;
  }

  vec2 tUV = UV / t;
  tUV.x *= larger_res / shorter_res;
    tUV *= zoom;
    tUV += offset;
    vec2 unzoomed_tUV = tUV / zoom;
    vec2 unzoomed_px = pixels * unzoomed_tUV;
//     bool dith = dither(1., uv, unzoomed_UV);

    // STARS DONE -> TODO: bigstars
    vec4 col = stars(unzoomed_px);
  return col;
}

vec4 hash_coords(vec2 UV)
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

  UV.x *= larger_res / shorter_res;
  UV *= zoom;
  UV += offset;
  vec2 unzoomed_UV = UV / zoom;
  float px_ratio = shorter_res / pixels;

  vec2 unzoomed_px = floor(unzoomed_UV * pixels) * px_ratio;
  vec2 px = unzoomed_px * zoom;
  vec2 uv = ((px / px_ratio) / zoom) / pixels;
  bool dith = dither(1., uv, unzoomed_UV);

  vec4 col = nebulae(px, dith);//bigstars(unzoomed_px);
//   vec4 col = planets(px, dith);
//   if (col.x <= -1.)
//   {
//     col = max(bigstars(unzoomed_UV), max(stars(unzoomed_px), max(dust(px, dith),
//       nebulae(px, dith)) * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));
//   }

  return col;
}
