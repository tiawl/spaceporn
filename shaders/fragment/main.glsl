# include "common.glsl"
# include "space/main.glsl"
# include "planets/main.glsl"

vec4 atlas_main(vec2 UV)
{
  vec2 t = textureSize(atlas, 0).xy;

  if (!motion)
  {
    time = 0.;
  }

  float motion_radius = 2. * zoom;
  vec2 offset = (motion_radius / t.x)
    * vec2(sin(MOTION_SPEED * time), sin(MOTION_SPEED * time * 0.75));

  if (!animation)
  {
    time = 0.;
  } else {
    time = fflags[3] / 50.;
  }

  vec2 tUV = UV / t;
  tUV.x *= larger_res / shorter_res;
    tUV *= zoom;
    tUV += offset;
    vec2 unzoomed_tUV = tUV / zoom;
    vec2 unzoomed_px = pixels * unzoomed_tUV;
//     bool dith = dither(uv, unzoomed_UV);

    // STARS DONE -> TODO: bigstars
     vec4 col = vec4(0.);//space(unzoomed_px);
  return col;
}

vec4 slide_main(vec2 fragment)
{
  //time = 0.;

  vec2 UV = fragment / shorter_res;
  UV += 5.;
  UV = floor(UV * pixels) / pixels;
  UV *= zoom;
  bool dith = dither(fragment / shorter_res, UV / zoom);

  vec4 col = planets(UV, dith);
//   if (col.x <= -1.)
//   {
//     col = space(UV, dith);
//   }

  return col;
}

void main()
{
  vec4 col = vec4(0.);
  if (precomputed)
  {
    col = atlas_main(gl_FragCoord.xy);
  } else {
    col = slide_main(gl_FragCoord.xy);
  }

  gl_FragColor = col;
}
