# include "pixelspace.glsl"

vec2 dualfbm(vec2 p, uint octaves, uint s)
{
  vec2 p2 = p * 0.4;
  vec2 basis = vec2(psfbm(p2 - time * 0.3, octaves, s),
    psfbm(p2 + time * 0.4, octaves, s));
  basis = (basis - .5) * 3.;
  p += basis;

  return p;
}
