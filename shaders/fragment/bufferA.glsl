const int KEY_SPACE = 32;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
  float space = texelFetch(iChannel1, ivec2(KEY_SPACE, 0), 0).x;

  fragColor.x = (space > 0.5 ? 1. : 0.);
  if ((iFrame < 1) || (fragColor.w != iResolution.y))
  {
    fragColor = vec4(0., 0., 0., iResolution.y);
  }
}
