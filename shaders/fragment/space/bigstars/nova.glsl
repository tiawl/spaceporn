# include "hash.glsl"
# include "space/bigstars/common.glsl"

float novaShape(vec2 coords, Star star)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;
  float depth = 1. / shorter_res;
  float res;
  if ((star.shape == 0u) || (star.shape == 1u))
  {
    vec2 A = vec2(-3. * pixel_res,       pixel_res);
    vec2 B = vec2( 3. * pixel_res,       pixel_res);
    vec2 C = vec2(-3. * pixel_res,      -pixel_res);
    vec2 D = vec2( 3. * pixel_res,      -pixel_res);
    vec2 E = vec2(      pixel_res, -3. * pixel_res);
    vec2 F = vec2(      pixel_res,  3. * pixel_res);
    vec2 G = vec2(     -pixel_res, -3. * pixel_res);
    vec2 H = vec2(     -pixel_res,  3. * pixel_res);
    vec2 I = vec2(-2. * pixel_res, -2. * pixel_res);
    vec2 J = vec2( 2. * pixel_res, -2. * pixel_res);
    vec2 K = vec2(-2. * pixel_res,  2. * pixel_res);
    vec2 L = vec2( 2. * pixel_res,  2. * pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    float s5 = sdSegment(coords, I, J) - depth;
    float s6 = sdSegment(coords, K, L) - depth;
    res = min(min(min(s1, s2), min(s3, s4)), min(s5, s6));
  }
  if (star.shape == 1u)
  {
    vec2 A = vec2(-5. * pixel_res, -2. * pixel_res);
    vec2 B = vec2(-4. * pixel_res, -2. * pixel_res);
    vec2 C = vec2(-2. * pixel_res, -4. * pixel_res);
    vec2 D = vec2(-2. * pixel_res, -5. * pixel_res);
    vec2 E = vec2(-5. * pixel_res,  2. * pixel_res);
    vec2 F = vec2(-4. * pixel_res,  2. * pixel_res);
    vec2 G = vec2( 2. * pixel_res, -4. * pixel_res);
    vec2 H = vec2( 2. * pixel_res, -5. * pixel_res);
    vec2 I = vec2( 5. * pixel_res,  2. * pixel_res);
    vec2 J = vec2( 4. * pixel_res,  2. * pixel_res);
    vec2 K = vec2( 2. * pixel_res,  4. * pixel_res);
    vec2 L = vec2( 2. * pixel_res,  5. * pixel_res);
    vec2 M = vec2( 5. * pixel_res, -2. * pixel_res);
    vec2 N = vec2( 4. * pixel_res, -2. * pixel_res);
    vec2 O = vec2(-2. * pixel_res,  4. * pixel_res);
    vec2 P = vec2(-2. * pixel_res,  5. * pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    float s5 = sdSegment(coords, I, J) - depth;
    float s6 = sdSegment(coords, K, L) - depth;
    float s7 = sdSegment(coords, M, N) - depth;
    float s8 = sdSegment(coords, O, P) - depth;
    res = min(min(min(min(s1, s2), min(s3, s4)),
      min(min(s5, s6), min(s7, s8))), res);
  }
  return res;
}

float nova(vec2 coords, Star star)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;

  star.brightness = 1. / star.brightness;

  vec2 A = vec2(            -star.size,                     0.);
  vec2 B = vec2(             star.size,                     0.);
  vec2 C = vec2(                    0.,              star.size);
  vec2 D = vec2(                    0.,             -star.size);
  vec2 E = vec2(-star.size / star.diag,  star.size / star.diag);
  vec2 F = vec2( star.size / star.diag, -star.size / star.diag);
  vec2 G = vec2( star.size / star.diag,  star.size / star.diag);
  vec2 H = vec2(-star.size / star.diag, -star.size / star.diag);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(min(s1, s2), min(s3, s4)), novaShape(coords, star));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1. - ((hash((star.center + coords) * pixels, seed) * ratio
    - ratio / 2.) + (abs(coords.x) + abs(coords.y)) * star.brightness);

  float ring = opRing(coords, star.size * star.ring_size,
    pixel_res / (4.0 - star.ring_size * 0.75));
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * (star.diag < 1.6 ? 0.9 : 1.3),
    ring * sqrt(1.0 - star.ring_size / 2.));

  return floor(color * PLANET_COLS) / PLANET_COLS;
}
