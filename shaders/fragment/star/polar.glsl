# include "hash.glsl"
# include "pixelspace.glsl"

float polar(vec2 uv, vec2 center, float size, float brightness)
{
  brightness = 1. / (size * brightness);
  size *= 2.;
  vec2 B = center;
  vec2 C = center + vec2(-size / 6.,  size / 6.);
  vec2 D = center + vec2( size / 6., -size / 6.);
  vec2 E = center + vec2( size / 6.,  size / 6.);
  vec2 F = center + vec2(-size / 6., -size / 6.);

  float depth = 0.35 * resolution.y / pixels;
  float s = sdBox(uv - B, vec2(size / 2., depth));
  float color = (sign(s) < 0.5 ? 1. : 0.);
  if (color < 1.)
  {
    s = sdBox(uv - B, vec2(depth, size / 4.5));
    color = (sign(s) < 0.5 ? 1. : 0.);
  }
  if (color < 1.)
  {
    s = sdSegment(uv, C, D) - depth;
    color = (sign(s) < 0.5 ? 1. : 0.);
  }
  if (color < 1.)
  {
    s = sdSegment(uv, E, F) - depth;
    color = (sign(s) < 0.5 ? 1. : 0.);
  }
  float ratio = 2. / (20. + brightness * brightness);
//   color *= 1.0 - ((hash(uv, seed) * ratio - ratio / 2.)
//     + (abs(uv.x - B.x) * 0.5 + abs(uv.y - B.y) * 1.) * brightness);

  return color;
}
