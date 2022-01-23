# include "hash.glsl"
# include "pixelspace.glsl"

float diamond(vec2 uv, vec2 center, float size, float brightness, float shape,
  uint sharpness)
{
  brightness = 1. / brightness;

  float depth = 1. / shorter_res;
  float s1 = sdBox(uv - center, vec2(size, depth));
  float s2 = sdBox(uv - center, vec2(depth, size));
  float m = smin(s1, s2, shape, sharpness);

  float color = (sign(m) < .5 ? 1. : 0.);
  float ratio = 2. / (20. + brightness * brightness);
  vec2 mirror_uv = vec2(abs(uv.x - center.x), abs(uv.y - center.y));
  color *= 1.0 - ((hash(uv, seed) * ratio - ratio / 2.)
    + (mirror_uv.x + mirror_uv.y) * (brightness / sqrt(size)));

  float ring = opRing(uv - center, size * 0.8, 500. / pixels);
  ring = (sign(ring) < .5 ? 1. : 0.);
  color = max(color * 1.3, ring * 0.6);
  return color;
}
