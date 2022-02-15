struct Star
{
  float type;
  vec2 center;
  float size;
  float time_speed;
  float brightness;
  float shape;
  float diag;
  float ring_size;
};

float sdCircle(vec2 p, float r)
{
  return length(p) - r;
}

float opRing(vec2 p, float r1, float r2)
{
  return abs(sdCircle(p, r1)) - r2;
}

float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

float starPattern(vec2 coords, Star star)
{
  float pixel_res = BIGSTARS_DENSITY / pixels;
  float depth = 1. / shorter_res;
  float res = 1e9;
  if (star.shape == 17u) {
    vec2 A = vec2(-7. * pixel_res, -7. * pixel_res);
    vec2 B = vec2( 7. * pixel_res,  7. * pixel_res);
    vec2 C = vec2(-7. * pixel_res,  7. * pixel_res);
    vec2 D = vec2( 7. * pixel_res, -7. * pixel_res);
    vec2 E = vec2(-5. * pixel_res, -6. * pixel_res);
    vec2 F = vec2( 6. * pixel_res,  5. * pixel_res);
    vec2 G = vec2(-6. * pixel_res, -5. * pixel_res);
    vec2 H = vec2( 5. * pixel_res,  6. * pixel_res);
    vec2 I = vec2(-5. * pixel_res,  6. * pixel_res);
    vec2 J = vec2( 6. * pixel_res, -5. * pixel_res);
    vec2 K = vec2(-6. * pixel_res,  5. * pixel_res);
    vec2 L = vec2( 5. * pixel_res, -6. * pixel_res);
    vec2 M = vec2(-4. * pixel_res, -5. * pixel_res);
    vec2 N = vec2( 5. * pixel_res,  4. * pixel_res);
    vec2 O = vec2(-5. * pixel_res, -4. * pixel_res);
    vec2 P = vec2( 4. * pixel_res,  5. * pixel_res);
    vec2 Q = vec2(-4. * pixel_res,  5. * pixel_res);
    vec2 R = vec2( 5. * pixel_res, -4. * pixel_res);
    vec2 S = vec2(-5. * pixel_res,  4. * pixel_res);
    vec2 T = vec2( 4. * pixel_res, -5. * pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    float s5 = sdSegment(coords, I, J) - depth;
    float s6 = sdSegment(coords, K, L) - depth;
    float s7 = sdSegment(coords, M, N) - depth;
    float s8 = sdSegment(coords, O, P) - depth;
    float s9 = sdSegment(coords, Q, R) - depth;
    float s10 = sdSegment(coords, S, T) - depth;
    res = min(min(min(min(s1, s2), min(s3, s4)),
      min(min(s5, s6), min(s7, s8))), min(s9, s10));
    star.shape = 0u;
  } else if (star.shape == 18u) {
    vec2 A = vec2(-4. * pixel_res, -4. * pixel_res);
    vec2 B = vec2( 4. * pixel_res,  4. * pixel_res);
    vec2 C = vec2(-4. * pixel_res,  4. * pixel_res);
    vec2 D = vec2( 4. * pixel_res, -4. * pixel_res);
    vec2 E = vec2(-3. * pixel_res, -2. * pixel_res);
    vec2 F = vec2( 3. * pixel_res, -2. * pixel_res);
    vec2 G = vec2(-3. * pixel_res,  2. * pixel_res);
    vec2 H = vec2( 3. * pixel_res,  2. * pixel_res);
    vec2 I = vec2(-2. * pixel_res, -3. * pixel_res);
    vec2 J = vec2(-2. * pixel_res,  3. * pixel_res);
    vec2 K = vec2( 2. * pixel_res, -3. * pixel_res);
    vec2 L = vec2( 2. * pixel_res,  3. * pixel_res);
    vec2 M = vec2(      pixel_res,              0.);
    vec2 N = vec2(     -pixel_res,              0.);
    vec2 O = vec2(             0.,       pixel_res);
    vec2 P = vec2(             0.,      -pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    float s5 = sdSegment(coords, I, J) - depth;
    float s6 = sdSegment(coords, K, L) - depth;
    float s7 = sdSegment(coords, M, N) - depth;
    float s8 = sdSegment(coords, O, P) - depth;
    res = min(min(min(s1, s2), min(s3, s4)), min(min(s5, s6), min(s7, s8)));
    star.shape = 0u;
  } else if (star.shape == 19u) {
    vec2 A =  vec2( -9. * pixel_res,  -9. * pixel_res);
    vec2 B =  vec2(  9. * pixel_res,   9. * pixel_res);
    vec2 C =  vec2( -9. * pixel_res,   9. * pixel_res);
    vec2 D =  vec2(  9. * pixel_res,  -9. * pixel_res);
    vec2 E =  vec2( -6. * pixel_res,   7. * pixel_res);
    vec2 F =  vec2(  7. * pixel_res,  -6. * pixel_res);
    vec2 G =  vec2(  6. * pixel_res,  -7. * pixel_res);
    vec2 H =  vec2( -7. * pixel_res,   6. * pixel_res);
    vec2 I =  vec2( -6. * pixel_res,  -7. * pixel_res);
    vec2 J =  vec2(  7. * pixel_res,   6. * pixel_res);
    vec2 K =  vec2(  6. * pixel_res,   7. * pixel_res);
    vec2 L =  vec2( -7. * pixel_res,  -6. * pixel_res);
    vec2 M =  vec2( -4. * pixel_res,   6. * pixel_res);
    vec2 N =  vec2(  6. * pixel_res,  -4. * pixel_res);
    vec2 O =  vec2(  4. * pixel_res,  -6. * pixel_res);
    vec2 P =  vec2( -6. * pixel_res,   4. * pixel_res);
    vec2 Q =  vec2( -4. * pixel_res,  -6. * pixel_res);
    vec2 R =  vec2(  6. * pixel_res,   4. * pixel_res);
    vec2 S =  vec2(  4. * pixel_res,   6. * pixel_res);
    vec2 T =  vec2( -6. * pixel_res,  -4. * pixel_res);
    vec2 U =  vec2( -2. * pixel_res,  -9. * pixel_res);
    vec2 V =  vec2( -2. * pixel_res,   9. * pixel_res);
    vec2 W =  vec2(      -pixel_res, -12. * pixel_res);
    vec2 X =  vec2(      -pixel_res,  12. * pixel_res);
    vec2 Y =  vec2(  2. * pixel_res,  -9. * pixel_res);
    vec2 Z =  vec2(  2. * pixel_res,   9. * pixel_res);
    vec2 AA = vec2(       pixel_res, -12. * pixel_res);
    vec2 BB = vec2(       pixel_res,  12. * pixel_res);
    vec2 CC = vec2( -9. * pixel_res,  -2. * pixel_res);
    vec2 DD = vec2(  9. * pixel_res,  -2. * pixel_res);
    vec2 EE = vec2(-12. * pixel_res,       -pixel_res);
    vec2 FF = vec2( 12. * pixel_res,       -pixel_res);
    vec2 GG = vec2( -9. * pixel_res,   2. * pixel_res);
    vec2 HH = vec2(  9. * pixel_res,   2. * pixel_res);
    vec2 II = vec2(-12. * pixel_res,        pixel_res);
    vec2 JJ = vec2( 12. * pixel_res,        pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    float s5 = sdSegment(coords, I, J) - depth;
    float s6 = sdSegment(coords, K, L) - depth;
    float s7 = sdSegment(coords, M, N) - depth;
    float s8 = sdSegment(coords, O, P) - depth;
    float s9 = sdSegment(coords, Q, R) - depth;
    float s10 = sdSegment(coords, S, T) - depth;
    float s11 = sdSegment(coords, U, V) - depth;
    float s12 = sdSegment(coords, W, X) - depth;
    float s13 = sdSegment(coords, Y, Z) - depth;
    float s14 = sdSegment(coords, AA, BB) - depth;
    float s15 = sdSegment(coords, CC, DD) - depth;
    float s16 = sdSegment(coords, EE, FF) - depth;
    float s17 = sdSegment(coords, GG, HH) - depth;
    float s18 = sdSegment(coords, II, JJ) - depth;
    res = min(min(min(min(min(s1, s2), min(s3, s4)),
      min(min(s5, s6), min(s7, s8))),
          min(min(min(s9, s10), min(s11, s12)),
      min(min(s13, s14), min(s15, s16)))), min(s17, s18));
    star.shape = 0u;
  } else if (star.shape == 20u) {
    vec2 A =  vec2(-7. * pixel_res, -7. * pixel_res);
    vec2 B =  vec2( 7. * pixel_res,  7. * pixel_res);
    vec2 C =  vec2(-7. * pixel_res,  7. * pixel_res);
    vec2 D =  vec2( 7. * pixel_res, -7. * pixel_res);
    vec2 E =  vec2(-5. * pixel_res,  6. * pixel_res);
    vec2 F =  vec2( 6. * pixel_res, -5. * pixel_res);
    vec2 G =  vec2( 5. * pixel_res, -6. * pixel_res);
    vec2 H =  vec2(-6. * pixel_res,  5. * pixel_res);
    vec2 I =  vec2(-5. * pixel_res, -6. * pixel_res);
    vec2 J =  vec2( 6. * pixel_res,  5. * pixel_res);
    vec2 K =  vec2( 5. * pixel_res,  6. * pixel_res);
    vec2 L =  vec2(-6. * pixel_res, -5. * pixel_res);
    vec2 M =  vec2(-3. * pixel_res,  5. * pixel_res);
    vec2 N =  vec2( 5. * pixel_res, -3. * pixel_res);
    vec2 O =  vec2( 3. * pixel_res, -5. * pixel_res);
    vec2 P =  vec2(-5. * pixel_res,  3. * pixel_res);
    vec2 Q =  vec2(-3. * pixel_res, -5. * pixel_res);
    vec2 R =  vec2( 5. * pixel_res,  3. * pixel_res);
    vec2 S =  vec2( 3. * pixel_res,  5. * pixel_res);
    vec2 T =  vec2(-5. * pixel_res, -3. * pixel_res);
    vec2 U =  vec2(-2. * pixel_res, -6. * pixel_res);
    vec2 V =  vec2(-2. * pixel_res,  6. * pixel_res);
    vec2 W =  vec2(     -pixel_res, -8. * pixel_res);
    vec2 X =  vec2(     -pixel_res,  8. * pixel_res);
    vec2 Y =  vec2( 2. * pixel_res, -6. * pixel_res);
    vec2 Z =  vec2( 2. * pixel_res,  6. * pixel_res);
    vec2 AA = vec2(      pixel_res, -8. * pixel_res);
    vec2 BB = vec2(      pixel_res,  8. * pixel_res);
    vec2 CC = vec2(-6. * pixel_res, -2. * pixel_res);
    vec2 DD = vec2( 6. * pixel_res, -2. * pixel_res);
    vec2 EE = vec2(-8. * pixel_res,      -pixel_res);
    vec2 FF = vec2( 8. * pixel_res,      -pixel_res);
    vec2 GG = vec2(-6. * pixel_res,  2. * pixel_res);
    vec2 HH = vec2( 6. * pixel_res,  2. * pixel_res);
    vec2 II = vec2(-8. * pixel_res,       pixel_res);
    vec2 JJ = vec2( 8. * pixel_res,       pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    float s5 = sdSegment(coords, I, J) - depth;
    float s6 = sdSegment(coords, K, L) - depth;
    float s7 = sdSegment(coords, M, N) - depth;
    float s8 = sdSegment(coords, O, P) - depth;
    float s9 = sdSegment(coords, Q, R) - depth;
    float s10 = sdSegment(coords, S, T) - depth;
    float s11 = sdSegment(coords, U, V) - depth;
    float s12 = sdSegment(coords, W, X) - depth;
    float s13 = sdSegment(coords, Y, Z) - depth;
    float s14 = sdSegment(coords, AA, BB) - depth;
    float s15 = sdSegment(coords, CC, DD) - depth;
    float s16 = sdSegment(coords, EE, FF) - depth;
    float s17 = sdSegment(coords, GG, HH) - depth;
    float s18 = sdSegment(coords, II, JJ) - depth;
    res = min(min(min(min(min(s1, s2), min(s3, s4)),
      min(min(s5, s6), min(s7, s8))),
          min(min(min(s9, s10), min(s11, s12)),
      min(min(s13, s14), min(s15, s16)))), min(s17, s18));
    star.shape = 0u;
  } else if ((star.size / star.diag >= 1.5 * pixel_res) && (star.shape >= 8u)) {
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
  } else if (star.shape >= 8u) {
    vec2 A = vec2(-2. * pixel_res,       pixel_res);
    vec2 B = vec2( 2. * pixel_res,       pixel_res);
    vec2 C = vec2(-2. * pixel_res,      -pixel_res);
    vec2 D = vec2( 2. * pixel_res,      -pixel_res);
    vec2 E = vec2(      pixel_res, -2. * pixel_res);
    vec2 F = vec2(      pixel_res,  2. * pixel_res);
    vec2 G = vec2(     -pixel_res, -2. * pixel_res);
    vec2 H = vec2(     -pixel_res,  2. * pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    float s3 = sdSegment(coords, E, F) - depth;
    float s4 = sdSegment(coords, G, H) - depth;
    res = min(min(s1, s2), min(s3, s4));
  }
  if (star.shape == 14u)
  {
    if (star.size / star.diag >= 1.5 * pixel_res)
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
    } else {
      vec2 A = vec2(-3.  * pixel_res, -3.  * pixel_res);
      vec2 B = vec2(-3.5 * pixel_res, -3.5 * pixel_res);
      vec2 C = vec2(-3.  * pixel_res,  3.  * pixel_res);
      vec2 D = vec2(-3.5 * pixel_res,  3.5 * pixel_res);
      vec2 E = vec2( 3.  * pixel_res, -3.  * pixel_res);
      vec2 F = vec2( 3.5 * pixel_res, -3.5 * pixel_res);
      vec2 G = vec2( 3.  * pixel_res,  3.  * pixel_res);
      vec2 H = vec2( 3.5 * pixel_res,  3.5 * pixel_res);
      float s1 = sdSegment(coords, A, B) - depth;
      float s2 = sdSegment(coords, C, D) - depth;
      float s3 = sdSegment(coords, E, F) - depth;
      float s4 = sdSegment(coords, G, H) - depth;
      res = min(min(min(s1, s2), min(s3, s4)), res);
    }
  } else if (star.shape == 15u) {
    if (star.size / star.diag >= 1.5 * pixel_res)
    {
      vec2 A = vec2(-5.  * pixel_res, -2.  * pixel_res);
      vec2 B = vec2(-4.5 * pixel_res, -2.  * pixel_res);
      vec2 C = vec2(-2.  * pixel_res, -4.5 * pixel_res);
      vec2 D = vec2(-2.  * pixel_res, -5.  * pixel_res);
      vec2 E = vec2(-5.  * pixel_res,  2.  * pixel_res);
      vec2 F = vec2(-4.5 * pixel_res,  2.  * pixel_res);
      vec2 G = vec2( 2.  * pixel_res, -4.5 * pixel_res);
      vec2 H = vec2( 2.  * pixel_res, -5.  * pixel_res);
      vec2 I = vec2( 5.  * pixel_res,  2.  * pixel_res);
      vec2 J = vec2( 4.5 * pixel_res,  2.  * pixel_res);
      vec2 K = vec2( 2.  * pixel_res,  4.5 * pixel_res);
      vec2 L = vec2( 2.  * pixel_res,  5.  * pixel_res);
      vec2 M = vec2( 5.  * pixel_res, -2.  * pixel_res);
      vec2 N = vec2( 4.5 * pixel_res, -2.  * pixel_res);
      vec2 O = vec2(-2.  * pixel_res,  4.5 * pixel_res);
      vec2 P = vec2(-2.  * pixel_res,  5.  * pixel_res);
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
    } else {
      vec2 A = vec2(-3. * pixel_res, -3. * pixel_res);
      vec2 B = vec2(-4. * pixel_res, -4. * pixel_res);
      vec2 C = vec2(-3. * pixel_res,  3. * pixel_res);
      vec2 D = vec2(-4. * pixel_res,  4. * pixel_res);
      vec2 E = vec2( 3. * pixel_res, -3. * pixel_res);
      vec2 F = vec2( 4. * pixel_res, -4. * pixel_res);
      vec2 G = vec2( 3. * pixel_res,  3. * pixel_res);
      vec2 H = vec2( 4. * pixel_res,  4. * pixel_res);
      float s1 = sdSegment(coords, A, B) - depth;
      float s2 = sdSegment(coords, C, D) - depth;
      float s3 = sdSegment(coords, E, F) - depth;
      float s4 = sdSegment(coords, G, H) - depth;
      res = min(min(min(s1, s2), min(s3, s4)), res);
    }
  } else if (star.shape == 16u) {
    if (star.size / star.diag >= 1.5 * pixel_res)
    {
      vec2 A = vec2(-4.  * pixel_res, -2.  * pixel_res);
      vec2 B = vec2(-3.5 * pixel_res, -2.  * pixel_res);
      vec2 C = vec2(-2.  * pixel_res, -3.5 * pixel_res);
      vec2 D = vec2(-2.  * pixel_res, -4.  * pixel_res);
      vec2 E = vec2(-4.  * pixel_res,  2.  * pixel_res);
      vec2 F = vec2(-3.5 * pixel_res,  2.  * pixel_res);
      vec2 G = vec2( 2.  * pixel_res, -3.5 * pixel_res);
      vec2 H = vec2( 2.  * pixel_res, -4.  * pixel_res);
      vec2 I = vec2( 4.  * pixel_res,  2.  * pixel_res);
      vec2 J = vec2( 3.5 * pixel_res,  2.  * pixel_res);
      vec2 K = vec2( 2.  * pixel_res,  3.5 * pixel_res);
      vec2 L = vec2( 2.  * pixel_res,  4.  * pixel_res);
      vec2 M = vec2( 4.  * pixel_res, -2.  * pixel_res);
      vec2 N = vec2( 3.5 * pixel_res, -2.  * pixel_res);
      vec2 O = vec2(-2.  * pixel_res,  3.5 * pixel_res);
      vec2 P = vec2(-2.  * pixel_res,  4.  * pixel_res);
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
    } else {
      vec2 A = vec2(-3. * pixel_res, -3. * pixel_res);
      vec2 B = vec2(-5. * pixel_res, -5. * pixel_res);
      vec2 C = vec2(-3. * pixel_res,  3. * pixel_res);
      vec2 D = vec2(-5. * pixel_res,  5. * pixel_res);
      vec2 E = vec2( 3. * pixel_res, -3. * pixel_res);
      vec2 F = vec2( 5. * pixel_res, -5. * pixel_res);
      vec2 G = vec2( 3. * pixel_res,  3. * pixel_res);
      vec2 H = vec2( 5. * pixel_res,  5. * pixel_res);
      float s1 = sdSegment(coords, A, B) - depth;
      float s2 = sdSegment(coords, C, D) - depth;
      float s3 = sdSegment(coords, E, F) - depth;
      float s4 = sdSegment(coords, G, H) - depth;
      res = min(min(min(s1, s2), min(s3, s4)), res);
    }
  }
  return res;
}

