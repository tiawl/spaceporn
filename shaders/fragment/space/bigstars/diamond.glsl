# include "hash.glsl"
# include "space/bigstars/common.glsl"

float diamond(vec2 coords, Star star)
{
  star.brightness = 1. / star.brightness;

  vec2 A = vec2(-star.size,         0.);
  vec2 B = vec2( star.size,         0.);
  vec2 C = vec2(        0.,  star.size);
  vec2 D = vec2(        0., -star.size);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float m = min(s1, s2);

  float color = (sign(m) < 0.5 ? -1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1. - ((hash((star.center + coords) * pixels, seed) * ratio
    - ratio / 2.) + (abs(coords.x) + abs(coords.y)) * star.brightness);

  float ring = opRing(coords, star.size * star.ring_size,
    depth * BIGSTARS_DENSITY * (300. / pixels) * 1.5);
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return floor(color * PLANET_COLS) / PLANET_COLS;
}
