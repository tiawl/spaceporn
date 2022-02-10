# include "hash.glsl"
# include "pixelspace.glsl"

float diamond(vec2 coords, Star star)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;

  star.brightness = 1. / star.brightness;
  vec2 A = vec2(-star.size,         0.);
  vec2 B = vec2( star.size,         0.);
  vec2 C = vec2(        0.,  star.size);
  vec2 D = vec2(        0., -star.size);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float m = smin(s1, s2, star.shape, star.sharpness);

  float color = (sign(m) < .5 ? -1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1.0 - ((hash(star.center + coords, seed) * ratio - ratio / 2.)
    + (abs(coords.x) + abs(coords.y)) * star.brightness * 1.2);

  float ring = opRing(coords, star.size * star.ring_size,
    pixel_res / 2.);
  ring = (sign(ring) < .5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.15);

  return floor(color * PLANET_COLS) / PLANET_COLS;
}
