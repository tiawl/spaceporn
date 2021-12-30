# include "pixelspace.glsl"

mat2 makem2(float theta)
{
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);
}

vec2 dualfbm(vec2 p, uint octaves, uint s)
{
  vec2 p2 = p * 0.007;
  vec2 basis = vec2(psfbm(p2 - time * 0.3, octaves, s),
    psfbm(p2 + time * 0.4, octaves, s));
  basis = (basis - .5) * 200.;
  p += basis;

  return p + 1000.;
}
