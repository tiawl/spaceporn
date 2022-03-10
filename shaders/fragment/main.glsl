# include "common.glsl"
# include "space/main.glsl"
# include "planets/main.glsl"

vec4 atlas_main(vec2 fragCoords)
{
  if (((mode > ANIM_MOTION_MODE / 2.) &&
    (mode < (ANIM_MOTION_MODE + ANIM_MODE) / 2.)) ||
      ((mode > (ANIM_MODE + MOTION_MODE) / 2.) &&
        (mode < (MOTION_MODE + BGGEN_MODE) / 2.)))
  {
    time = 0.;
  }

  float motion_radius = 2. * zoom; //TODO: rework this distance
  vec2 offset = (motion_radius / textureSize(atlas, 0).x)
    * vec2(sin(MOTION_SPEED * time), sin(MOTION_SPEED * time * 0.75));

  if ((mode > ANIM_MOTION_MODE / 2.) &&
    (mode < (ANIM_MODE + MOTION_MODE) / 2.))
  {
    time = fflags[3] / 50.;
  } else {
    time = 0.;
  }

  vec2 UV = fragCoords / shorter_res;
  UV += offset;
  vec2 stars_UV = UV * pixels;
  UV = floor(stars_UV) / pixels;
  UV *= zoom;
  bool dith = dither(fragCoords / shorter_res, UV / zoom);

  vec4 col = planets(UV, dith);
  if (col.x <= -1.)
  {
    col = space(UV, stars_UV, dith);
  }
  return col;
}

vec4 slide_main(vec2 fragCoords)
{
  time = 0.;
  const float offset = 5.;

  vec2 UV = fragCoords / shorter_res;
  UV += offset;
  vec2 stars_UV = UV * pixels;
  UV = floor(stars_UV) / pixels;
  UV *= zoom;
  bool dith = dither(fragCoords / shorter_res, UV / zoom);

  vec4 col = planets(UV, dith);
  if (col.x <= -1.)
  {
    col = space(UV, stars_UV, dith);
  }

  return col;
}

void main()
{
  vec4 col = vec4(0.);
  if (mode < (SLIDE_MODE + BGGEN_MODE) / 2.)
  {
    col = slide_main(gl_FragCoord.xy);
  } else {
    col = atlas_main(gl_FragCoord.xy);
  }

  gl_FragColor = col;
}
