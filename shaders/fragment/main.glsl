# include "header.glsl"
# include "bigstars.glsl"
# include "dust.glsl"
# include "nebula.glsl"
# include "planets.glsl"
# include "stars.glsl"

vec4 atlas_main(vec2 UV)
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

vec4 hash_main(vec2 coords)
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

  vec2 UV = coords / shorter_res;
  UV += offset;
  UV = floor(UV * pixels) / pixels;
  UV *= zoom;
  bool dith = dither(1., coords / shorter_res, UV / zoom);
  //return stars(UV * pixels / zoom); DONE
  //return bigstars(UV / zoom); DONE
  //return dust(UV, dith); DONE
  //return nebula(UV, dith); DONE
  //return max(nebula(UV, dith), dust(UV, dith)) * 0.8 * (sin(time * 2500.) * 0.015 + 1.); DONE
  //TODO: planets

//  UV.x *= larger_res / shorter_res;
//  UV *= zoom;
//  UV += offset;
//  vec2 unzoomed_UV = UV / zoom;
//  float px_ratio = shorter_res / pixels;
//
//  vec2 unzoomed_px = floor(unzoomed_UV * pixels) * px_ratio;
//  vec2 px = unzoomed_px * zoom;
//  vec2 uv = ((px / px_ratio) / zoom) / pixels;
//  bool dith = dither(1., uv, unzoomed_UV);

//   vec4 col = bigstars(unzoomed_px);
//   vec4 col = planets(px, dith);
//   if (col.x <= -1.)
//   {
//     col = max(bigstars(unzoomed_UV), max(stars(unzoomed_px), max(dust(px, dith),
//       nebula(px, dith)) * 0.8 * (sin(time * 2500.) * 0.015 + 1.)));
//   }

//   return col;
}

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
