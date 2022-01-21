# include "hash.glsl"
# include "pixelspace.glsl"

float nova(vec2 uv, vec2 center, float size, float brightness, float shape)
{
  brightness = 1. / brightness;
  vec2 A = center + vec2(size, 0.);
  vec2 B = center;
  vec2 C = center + vec2(size / 2.1, size / 2.);

  vec2 buv = uv;
  uv.x = abs(uv.x - B.x) + B.x;
  uv.y = abs(uv.y - B.y) + B.y;
  if (uv.x - B.x < uv.y - B.y)
  {
    float tmp = uv.x - B.x + B.y;
    uv.x = uv.y + B.x - B.y;
    uv.y = tmp;
  }

  float insideOutside =
    sdBezier(uv, A, B, C, shape * size * 2.5, 1.) < 0.0 ? 1. : 0.;
  float d = sdRhombus(buv - B, vec2(size));

  float color = insideOutside > 0. ? 0. : (sign(d) < .5 ? 1. : 0.);
  float ratio = 2. / (20. + brightness * brightness);
  color *= 1.0 - ((hash(buv, seed) * ratio - ratio / 2.)
    + ((uv.x - B.x) + (uv.y - B.y)) * (brightness / sqrt(size)));

  float ring = opRing(buv - B, size * sqrt(1./brightness), 0.5 / pixels);
  ring = (sign(ring) < .5 ? 1. : 0.);
  color = max(color * 1.4, ring * 0.3);
  return color;
}
