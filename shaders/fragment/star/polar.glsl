# include "hash.glsl"
# include "pixelspace.glsl"

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
  float m = min(min(smin(s1 - depth, s3, star.shape, star.sharpness),
    smin(s2, s3, star.shape, star.sharpness)),
      min(smin(s1 - depth, s4, star.shape, star.sharpness),
        smin(s2, s4, star.shape, star.sharpness)));

  float color = (sign(m) < .5 ? -1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1.0 - ((hash((star.center + coords) * pixels, seed) * ratio
    - ratio / 2.) + (abs(coords.x) + abs(coords.y) + 0.1) * star.brightness);

  float ring = opRing(coords, star.size * star.ring_size,
    pixel_res / 2.);
  ring = (sign(ring) < .5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.15);

  return floor(color * PLANET_COLS) / PLANET_COLS;
}

float polarShape(Star star, float pixel_res)
{
  float shape;
  if (star.sharpness > 6u)
  {
    if (star.sharpness == 7u)
    {
      shape = 3. * pixel_res;
    } else if (star.sharpness == 8u) {
      shape = 3.18 * pixel_res;
    } else if ((star.sharpness >= 9u) && (star.sharpness <= 10u)) {
      shape = 3.372 * pixel_res;
    } else {
      float ratio = 0.053;
      ratio = (star.sharpness < 12u ? ratio * 0.5 : ratio);
      ratio = (star.sharpness < 15u ? ratio * 0.75 : ratio);
      ratio = (star.sharpness > 13u ? ratio + 0.013 : ratio);
      ratio = (star.sharpness > 15u ? ratio + 0.019 : ratio);
      shape = 0.219 + ratio * (hash(star.center, seed + 9u) * 0.5 + 0.5);
      shape *= star.size;
      shape *= (star.size / pixel_res < float(star.sharpness) ?
        1. + ((float(star.sharpness) - star.size / pixel_res) / 20.) : 1.);
    }
  } else {
    shape = 0.0001;
  }
  shape *= 2.73;
  return shape;
}
