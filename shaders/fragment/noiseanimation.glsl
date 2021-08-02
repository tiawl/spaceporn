# include "pixelspace.glsl"

mat2 makem2(float theta)
{
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c,-s,s,c);
}

vec2 dualfbm(vec2 p, uint octaves)
{
  vec2 p2 = p * 2.7;
  vec2 basis =
    vec2(psfbm(p2 - time * 1.6, octaves), psfbm(p2 + time * 1.7, octaves));
  basis = (basis - .5) * .2;
  p += basis;

  return p * makem2(time * .2);
}
