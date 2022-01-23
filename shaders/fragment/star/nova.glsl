# include "hash.glsl"
# include "pixelspace.glsl"

float nova(vec2 uv, vec2 center, float size, float brightness, float shape,
  uint sharpness, float diag)
{
  brightness = 1. / brightness;
  vec2 A = center + vec2(-size / diag,  size / diag);
  vec2 B = center + vec2( size / diag, -size / diag);
  vec2 C = center + vec2( size / diag,  size / diag);
  vec2 D = center + vec2(-size / diag, -size / diag);

  float depth = 1. / shorter_res;
  float s1 = sdBox(uv - center, vec2(size, depth));
  float s2 = sdBox(uv - center, vec2(depth, size));
  float s3 = sdSegment(uv, A, B) - depth;
  float s4 = sdSegment(uv, C, D) - depth;
  float m = min(min(smin(s1, s3, shape, sharpness),
      smin(s2, s3, shape, sharpness)),
    min(smin(s1, s4, shape, sharpness), smin(s2, s4, shape, sharpness)));

  float color = (sign(m) < .5 ? 1. : 0.);
  vec2 mirror_uv = vec2(abs(uv.x - center.x), abs(uv.y - center.y));

  float ratio = 2. / (20. + brightness * brightness);
  color *= 1.0 - ((hash(uv, seed) * ratio - ratio / 2.)
    + (mirror_uv.x + mirror_uv.y) * (brightness / sqrt(size)));

  float ring = opRing(uv - center, size * 0.8, 500. / pixels);
  ring = (sign(ring) < .5 ? 1. : 0.);
  color = max(color * 1.3, ring * 0.6);
  return color;
}
