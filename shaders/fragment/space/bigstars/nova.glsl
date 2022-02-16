# include "hash.glsl"
# include "space/bigstars/common.glsl"

float nova(vec2 coords, Star star)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;

  star.brightness = 1. / star.brightness;

  float size = (star.shape >= 17u ?
    (star.shape == 19u ? 17. * pixel_res / star.size :
      (star.shape == 20u ? 11. * pixel_res / star.size : 0.)) : star.size);
  vec2 A = vec2(            -size,                0.);
  vec2 B = vec2(             size,                0.);
  vec2 C = vec2(               0.,              size);
  vec2 D = vec2(               0.,             -size);
  vec2 E = vec2(-size / star.diag,  size / star.diag);
  vec2 F = vec2( size / star.diag, -size / star.diag);
  vec2 G = vec2( size / star.diag,  size / star.diag);
  vec2 H = vec2(-size / star.diag, -size / star.diag);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(min(s1, s2), min(s3, s4)), starPattern(coords, star));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1. - ((hash((star.center + coords) * pixels, seed) * ratio
    - ratio / 2.) + (abs(coords.x) + abs(coords.y)) * star.brightness);

  size = (star.shape == 18u ? star.size * 0.1 + 50. / pixels  :
    (star.shape >= 19u ? star.size * 0.35 + 70. / pixels: star.size));
  float ring = opRing(coords +
    (star.shape == 18u ? vec2(-pixel_res * 0.5, pixel_res * 0.5) :
      (star.shape == 17u ? vec2(pixel_res * 0.5, -pixel_res * 0.5) :
        vec2(0.))), size * star.ring_size,
          pixel_res / (4.0 - star.ring_size * 0.75));
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * sqrt(1.0 - star.ring_size / 2.));

  return floor(color * PLANET_COLS) / PLANET_COLS;
}
