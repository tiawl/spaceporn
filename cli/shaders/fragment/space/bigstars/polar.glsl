# include "hash.glsl"
# include "space/bigstars/common.glsl"

float polar(vec2 coords, Star star)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;

  star.brightness = 1. / star.brightness;

  vec2 A = vec2(            -star.size,                                 0.);
  vec2 B = vec2(             star.size,                                 0.);
  vec2 C = vec2(                    0.,  star.size / (star.diag * 2. / 3.));
  vec2 D = vec2(                    0., -star.size / (star.diag * 2. / 3.));
  vec2 E = vec2(-star.size / star.diag,              star.size / star.diag);
  vec2 F = vec2( star.size / star.diag,             -star.size / star.diag);
  vec2 G = vec2( star.size / star.diag,              star.size / star.diag);
  vec2 H = vec2(-star.size / star.diag,             -star.size / star.diag);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(s1, s2), min(s3, s4));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1. - ((hash((star.center + coords) * pixels, seed) * ratio
    - ratio / 2.) + (abs(coords.x) + abs(coords.y)) * star.brightness);

  float ring = opRing(coords, star.size * star.ring_size,
    depth * BIGSTARS_DENSITY * (300. / pixels)
      * (star.size / pixel_res > 7. ? 1. : 1.5));
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return floor(color * PLANET_COLS) / PLANET_COLS;
}
