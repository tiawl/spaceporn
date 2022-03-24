/*
 * Char Map, chars written with "0xab" a is X coord b is Y coord :
 * 
 *    0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
 * 1      
 * 2     !                    (  )     +     -  .  /
 * 3  0  1  2  3  4  5  6  7  8  9     ;           ?
 * 4  @  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O
 * 5  P  Q  R  S  T  U  V  W  X  Y  Z  [  \  ]  ^  _
 * 6     a  b  c  d  e  f  g  h  i  j  k  l  m  n  o
 * 7  p  q  r  s  t  u  v  w  x  y  z
 * 8  
 * 
 */

#define fontChannel iChannel0
#define SPACE_CHAR 0x02U
#define STOP_CHAR 0x0AU

vec4 fontCol;vec3 fontColFill;vec3 fontColBorder;vec4 fontBuffer;vec2 fontCaret;float fontSize;float fontSpacing;vec2 fontUV;void drawStr4(uint str){if (str < 0x100U){str = str * 0x100U + SPACE_CHAR;}if (str < 0x10000U){str = str * 0x100U + SPACE_CHAR;}if (str < 0x1000000U){str = str * 0x100U + SPACE_CHAR;}for (int i = 0; i < 4; i++){uint xy = (str >> 8 * (3 - i)) % 256U;if (xy != SPACE_CHAR){vec2 K = (fontUV - fontCaret) / fontSize;if (length(K) < 0.6){vec4 Q = texture(fontChannel, (K + vec2(float(xy / 16U) + 0.5,16. - float(xy % 16U) - 0.5)) / 16.);fontBuffer.rgb += Q.rgb * smoothstep(0.6, 0.4, length(K));if (max(abs(K.x), abs(K.y)) < 0.5){fontBuffer.a = min(Q.a, fontBuffer.a);}}}if (xy != STOP_CHAR){fontCaret.x += fontSpacing * fontSize;}}}void beginDraw(){fontBuffer = vec4(0., 0., 0. , 1.);fontCol = vec4(0.);fontCaret.x += fontSpacing * fontSize / 2.;}void endDraw(){float a = smoothstep(1., 0., smoothstep(0.51, 0.53, fontBuffer.a));float b = smoothstep(0., 1., smoothstep(0.48, 0.51, fontBuffer.a));fontCol.rgb = mix(fontColFill, fontColBorder, b);fontCol.a = a;}void _(uint str){beginDraw();drawStr4(str);endDraw();}void _(uvec2 str){beginDraw();drawStr4(str.x);drawStr4(str.y);endDraw();}void _(uvec3 str){beginDraw();drawStr4(str.x);drawStr4(str.y);drawStr4(str.z);endDraw();}void _(uvec4 str){beginDraw();drawStr4(str.x);drawStr4(str.y);drawStr4(str.z);drawStr4(str.w);endDraw();}vec2 viewport(vec2 b){return (b / iResolution.xy - vec2(0.5)) * vec2(iResolution.x / iResolution.y, 1.);}

// end of copy-pasting

float pixel_res;
float pix;
const float depth = 1. / 360.;

# define BIGSTARS_DENSITY 4.5
# define MAX_BIGSTAR_SZ 8.
# define COLS 18.
# define COL_SEED 0u
# define SEED 1u

# define DIAMOND 0u
# define NOVA    1u
# define POLAR   2u

struct Star
{
  uint type;
  vec2 center;
  float size;
  float power;
  float brightness;
  uint shape;
  float diag;
  float ring_size;
};

float floor2(float x, float base)
{
  return floor(x / base) * base;
}

// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdCircle(vec2 p, float r)
{
  return length(p) - r;
}

// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float opRing(vec2 p, float r1, float r2)
{
  return abs(sdCircle(p, r1)) - r2;
}

// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

// https://iquilezles.org/www/articles/smin/smin.htm
float smax(float a, float b, float k)
{
  float h = max(k - abs(a - b), 0.);
  return max(a, b) + h * h * 0.25 / k;
}

vec2 rotation(vec2 p, float a)
{
  return p * mat2(cos(a), -sin(a),
                  sin(a),  cos(a));
}

// 3D hash function to simulate seeding:
// https://www.shadertoy.com/view/XlGcRh
uvec3 pcg3d(uvec3 v)
{
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return v;
}

// https://www.shadertoy.com/view/XlGcRh
float hash(vec2 s, uint hash_seed)
{
  float res;
  uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
  uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
  res = float(p) * (1. / float(0xffffffffu));
  return res;
}

// https://www.shadertoy.com/view/NsfyDs
float circles(vec2 p, float r, float w, uint s)
{
  vec3 col;
  vec2 i = floor(p), f = fract(p), h;

  float d = (sign(w) > -0.5 ? 8. : -1e9), c, rad, h2;
  for (int k = 0; k < 9; k++)
  {
    p = vec2(k % 3, k / 3) - 1.;
    h = vec2(hash(i + p, s + 89u), hash(i + p, s + 52u));
    c = length(p + h - f);
    
    if (sign(w) > -0.5)
    {
      // https://iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm
      col = 0.5 + 0.5 * sin(hash(i + p, SEED + 32u) * 2.5 + 3.5 + vec3(2.));  		
      h2 = smoothstep(0., 1., 0.5 + 0.5 * (d - c) / w);
	  d = mix(d, c, h2) - h2 * (1. - h2) * w / (1. + 3. * w);
    } else {
      rad = r / 2. + hash(i + p, s + 2u) * r;
      d = smax(d, rad - c, 0.3);
    }
  }
  return (sign(w) > -0.5 ? 1. - d : d);
}

float fbmVoronoi(vec2 U, uint seed)
{
  float r = (circles(6. * U, -1., 0.3, seed)) * 0.625
    + (circles(12. * U, -1., 0.3, seed + 314u)) * 0.25
    + (circles(24. * U, -1., 0.3, seed + 92u)) * 0.125;
  return r;
}

// https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
float fbmCircles(vec2 p, uint se)
{
  float s = 1., d = 0.;
  int o = 2;
  for(int i = 0; i < o; i++)
  {
    float n = s * circles(p, 0.5, -1., se);

    d = smax(d, n, 0.3 * s);

    p *= 2.;
    s = 0.5 * s;
  }
  return d;
}

// original author warned against discontinuities that I did not fix:
// https://www.shadertoy.com/view/fsKSWD
vec2 swirls(vec2 p, uint se, float sz, float ro)
{
  p *= 360. / sz;
  
  vec2 i = floor(p), f = fract(p), d;
  int k;
  float r, h;
  for (k = 0; k < 9; k++)
  {
    d = vec2(k % 3, k / 3) - 1.;
    d += hash(i + d, se + 222u);
    h = hash(i + d, 72u) * 2. - 1.;
    r = length(f - d) * (1. + abs(h));
    f = rotation(f - d, ro * sign(h) * (1. - smoothstep(0., 0.5, r))) + d;
    p = f + i;
  }
  return p / (360. / sz);
}

vec2 fbmSwirls(vec2 p, uint se)
{
  uint o = 3u;
  float sz = 42., ro = 1.5;
  for(uint i = 0u; i < o; i++)
  {
    p = swirls(p, se + i, sz, ro);
    sz *= 1.;
  }
  return p;
}

float diamond(vec2 coords, Star star)
{
  star.brightness = 1. / star.brightness;
  vec2 A = vec2(-star.size,         0.);
  vec2 B = vec2( star.size,         0.);
  vec2 C = vec2(        0.,  star.size);
  vec2 D = vec2(        0., -star.size);

  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float m = min(s1, s2);

  float color = (sign(m) < 0.5 ? -1. : 0.);
  color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;

  float ring = opRing(coords, star.size * star.ring_size,
    depth * BIGSTARS_DENSITY * (100. / pix) * 1.5);
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return color;
}

float novapattern(vec2 coords, Star star)
{
  float res = 1e9;
  coords = abs(coords);
  if ((star.size / star.diag >= 1.5 * pixel_res) && (star.shape > 24u))
  {
    vec2 A = vec2(3. * pixel_res,      pixel_res);
    vec2 B = vec2(     pixel_res, 3. * pixel_res);
    vec2 C = vec2(2. * pixel_res,      pixel_res);
    vec2 D = vec2(     pixel_res, 2. * pixel_res);
    float s1 = sdSegment(coords, A, B) - depth;
    float s2 = sdSegment(coords, C, D) - depth;
    res = min(res, min(s1, s2));
  } else if (star.shape > 24u) {
    vec2 A = vec2(2. * pixel_res,      pixel_res);
    vec2 B = vec2(     pixel_res, 2. * pixel_res);
    res = min(res, sdSegment(coords, A, B) - depth);
  }
  if ((star.shape >= 30u) && (star.shape <= 32u))
  {
    if (star.size / star.diag >= 1.5 * pixel_res)
    {
      vec2 A = vec2(5. * pixel_res, 2. * pixel_res);
      vec2 B = vec2(4. * pixel_res, 2. * pixel_res);
      vec2 C = vec2(2. * pixel_res, 4. * pixel_res);
      vec2 D = vec2(2. * pixel_res, 5. * pixel_res);
      float s1 = sdSegment(coords, A, B) - depth;
      float s2 = sdSegment(coords, C, D) - depth;
      res = min(res, min(s1, s2));
    } else {
      vec2 A = vec2(3. * pixel_res, 3. * pixel_res);
      vec2 B = vec2(5. * pixel_res, 5. * pixel_res);
      res = min(res, sdSegment(coords, A, B) - depth);
    }
  } else if ((star.shape >= 33u) && (star.shape <= 35u)) {
    if (star.size / star.diag >= 1.5 * pixel_res)
    {
      vec2 A = vec2(5.  * pixel_res, 2.  * pixel_res);
      vec2 B = vec2(4.5 * pixel_res, 2.  * pixel_res);
      vec2 C = vec2(2.  * pixel_res, 4.5 * pixel_res);
      vec2 D = vec2(2.  * pixel_res, 5.  * pixel_res);
      float s1 = sdSegment(coords, A, B) - depth;
      float s2 = sdSegment(coords, C, D) - depth;
      res = min(res, min(s1, s2));
    } else {
      vec2 A = vec2(3. * pixel_res, 3. * pixel_res);
      vec2 B = vec2(5. * pixel_res, 5. * pixel_res);
      res = min(res, sdSegment(coords, A, B) - depth);
    }
  } else if ((star.shape >= 36u) && (star.shape <= 38u)) {
    if (star.size / star.diag >= 1.5 * pixel_res)
    {
      vec2 A = vec2(4.  * pixel_res, 2.  * pixel_res);
      vec2 B = vec2(3.5 * pixel_res, 2.  * pixel_res);
      vec2 C = vec2(2.  * pixel_res, 3.5 * pixel_res);
      vec2 D = vec2(2.  * pixel_res, 4.  * pixel_res);
      float s1 = sdSegment(coords, A, B) - depth;
      float s2 = sdSegment(coords, C, D) - depth;
      res = min(res, min(s1, s2));
    } else {
      vec2 A = vec2(3. * pixel_res, 3. * pixel_res);
      vec2 B = vec2(5. * pixel_res, 5. * pixel_res);
      res = min(res, sdSegment(coords, A, B) - depth);
    }
  }
  return res;
}

float nova(vec2 coords, Star star)
{
  star.brightness = 1. / star.brightness;

  float size = (star.shape == 39u ? 17. * pixel_res / star.size :
    (star.shape == 40u ? 11. * pixel_res / star.size : star.size));
  vec2 A = vec2(            -size,                0.);
  vec2 B = vec2(             size,                0.);
  vec2 C = vec2(               0.,              size);
  vec2 D = vec2(               0.,             -size);
  vec2 E = vec2(-size / star.diag,  size / star.diag);
  vec2 F = vec2( size / star.diag, -size / star.diag);
  vec2 G = vec2( size / star.diag,  size / star.diag);
  vec2 H = vec2(-size / star.diag, -size / star.diag);

  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(min(s1, s2), min(s3, s4)), novapattern(coords, star));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;

  size = (star.shape > 38u ? star.size * 0.35 + 70. / pix : star.size);
  float ring = opRing(coords, size * star.ring_size,
    depth * BIGSTARS_DENSITY * (100. / pix) * (star.size / pixel_res > 7. ? 1. : 1.5));
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return color;
}

float polar(vec2 coords, Star star)
{
  star.brightness = 1. / star.brightness;

  vec2 A = vec2(            -star.size,                                 0.);
  vec2 B = vec2(             star.size,                                 0.);
  vec2 C = vec2(                    0.,  star.size / (star.diag * 2. / 3.));
  vec2 D = vec2(                    0., -star.size / (star.diag * 2. / 3.));
  vec2 E = vec2(-star.size / star.diag,              star.size / star.diag);
  vec2 F = vec2( star.size / star.diag,             -star.size / star.diag);
  vec2 G = vec2( star.size / star.diag,              star.size / star.diag);
  vec2 H = vec2(-star.size / star.diag,             -star.size / star.diag);

  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(s1, s2), min(s3, s4));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;

  float ring = opRing(coords, star.size * star.ring_size,
    depth * BIGSTARS_DENSITY * (100. / pix) * (star.size / pixel_res > 7. ? 1. : 1.5));
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return color;
}

float calc_star(vec2 coords, vec2 center)
{
  float type = hash(center, SEED + 2u);
  uint rd_bigstar = (type < 0.15 ? NOVA : (type < 0.3 ? POLAR : DIAMOND));
  float size_hash = hash(center, SEED + 3u) * 0.05;
  float min_size = (rd_bigstar == DIAMOND ? 3. : 7.);
  float max_size = MAX_BIGSTAR_SZ - min_size;
  float size =
    (min(floor(size_hash * (max_size + 1.)), max_size) + min_size) * pixel_res * (pix / 150.);
  float brightness = hash(center, SEED + 4u) + 1.;
  float ring_size = hash(center, SEED + 5u) * 0.8;
  ring_size = (ring_size * size < pixel_res * 4. ? 0. : ring_size);
  float power = round(sin(iTime * (3. + 4. * hash(center, SEED + 6u)))) * 0.2 + 1.;

  float star = 0.;
  Star bigstar =
    Star(rd_bigstar, center, size, power, 1., 0u, 1., ring_size);
  if (bigstar.type == DIAMOND)
  {
    bool rotated = hash(bigstar.center, SEED + 7u) > 0.5;
    bigstar.brightness *= bigstar.size;
    bigstar.brightness *= bigstar.power;
    coords = rotation(coords, radians(rotated ? 45. : 0.));
    star = diamond(coords, bigstar);
  } else if (bigstar.type == NOVA) {
    bigstar.shape = uint(ceil(hash(bigstar.center, SEED + 7u) * 38.));
    bigstar.diag = (bigstar.shape > 38u ? 0. :
      (bigstar.shape < 25u ?
        1. + hash(bigstar.center, SEED + 8u) * 3.5 :
        hash(bigstar.center, SEED + 8u) > 0.5 ? bigstar.size / pixel_res :
        2. + hash(bigstar.center, SEED + 9u) * 3.));
    bigstar.brightness = (bigstar.shape > 38u ?
      100. / pix : bigstar.size * bigstar.brightness);
    bigstar.brightness *= bigstar.power;
    star = nova(coords, bigstar);
  } else {
    bigstar.brightness *= bigstar.size;
    bigstar.brightness *= bigstar.power;
    bigstar.diag = 2.5 + hash(bigstar.center, SEED + 7u) * 0.5;
    star = polar(coords, bigstar);
  }
  return star;
}

vec3 bigstars(vec2 coords)
{
  coords *= BIGSTARS_DENSITY;
  float d = 1e9, c;

  pixel_res = BIGSTARS_DENSITY / pix;

  vec2 i = floor(coords);
  vec2 f = fract(coords);
  vec2 h, o, p, center, tmp;

  for (int k = 0; k < 9; k++)
  {
    o = vec2(k % 3, k / 3) - 1.;

    center = i + o;
    h = vec2(hash(center, SEED), hash(center, SEED + 1u));
    p = vec2(floor2(o.x + h.x - f.x, pixel_res),
      floor2(o.y + h.y - f.y, pixel_res));

    c = calc_star(p, center);
    if (c < d)
    {
      d = c;
      tmp = p;
    }
  }
  
  vec2 U = (coords + tmp) / BIGSTARS_DENSITY;
  float fv = fbmVoronoi(0.25 * U, SEED);
  
  return vec3(-d * fv * fv * 0.5, U * pix);
}

vec3 hsv2rgb(vec3 c)
{
  vec3 rgb = clamp(abs(mod(c.x * 6.
    + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  return c.z * mix(vec3(1.), rgb, c.y);
}

// https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes
vec3 color(float sm, uint cseed)
{
  float var = 0.01 * sin(iTime * 50.);
  float hu, sa = 0., br = 0.;
  sa += var * 2.;
  hu = radians(6.2832 * (9. * hash(vec2(1.), cseed)
    + sm * (hash(vec2(10.), cseed) * 0.25)));
  if (sm < 2.5)
  {
    sa += 0.2 + 0.15 * sm;
  } else if (sm < 4.5) {
    sa += 0.35 + 0.1 * (sm - 2.);
  } else {
    sa += 0.55 - 0.07 * (sm - 4.);
  }
  if (sm < 3.5)
  {
    br += 0.1 + 0.1 * sm;
  } else if (sm < 6.5) {
    br += 0.5 + 0.075 * (sm - 3.);
  } else {
    br += 0.7 + 0.1 * (sm - 6.);
  }
  return hsv2rgb(vec3(hu, sa, br));
}

void starfield(vec2 u, out vec4 O)
{
  vec2 bU = 2. + (u - iResolution.xy * 0.5) / iResolution.y + iTime * 0.05;
  vec2 U = floor(bU * pix) / pix;
  bool dith = mod(bU.x + U.y, 2. / pix) < 1. / pix;
  
  float fv = fbmVoronoi(0.25 * U, SEED);
  vec2 aU = fbmSwirls(U, SEED) * 10.;
  float g = max(fbmCircles(aU, SEED + 10u), fbmCircles(aU, SEED + 20u));
  g = smax(-1., g, 3.2) * fv * fv;
  g *= (dith ? 1.35 : 1.5);
  
  vec3 b = bigstars(U) * vec3(4., 1., 1.);

  g = max(b.x, g);
  g = floor(g * COLS) / COLS;
  O = vec4(color(10. * g, COL_SEED), 1.) * (iTime > 3. ? (4. - iTime) / 2. : 1.);
}

uvec4 _How_to_make_this_ = uvec4(0x84F67702, 0x47F602D6, 0x16B65602, 0x47869637);
uvec4 _starfield_X_ =      uvec4(0x02020237, 0x47162766, 0x9656C646, 0x02F3);
uvec4 _XX_Circles_ =       uvec4(0x13E20234, 0x962736C6, 0x5637,     SPACE_CHAR);
uvec4 _Draw_a_circled_l_ = uvec4(0x44271677, 0x02160236, 0x962736C6, 0x564602C6);
uvec4  _ight_ =            uvec4(0x96768647, SPACE_CHAR, SPACE_CHAR, SPACE_CHAR);
uvec4 _Then_a_full_grid_ = uvec4(0x458656E6, 0x02160266, 0x57C6C602, 0x76279646);
uvec4 _Randomize_their_ =  uvec4(0x2516E646, 0xF6D696A7, 0x56024786, 0x569627);
uvec4 _size_ =             uvec4(0x27164696, 0x5737,     SPACE_CHAR, SPACE_CHAR);
uvec4 _position_ =         uvec4(0x07F63796, 0x4796F6E6, SPACE_CHAR, SPACE_CHAR);
uvec4 _Reduce_color_num_ = uvec4(0x25564657, 0x36560236, 0xF6C6F627, 0x02E657D6);
uvec4 _ber_ =              uvec4(0x265627,   SPACE_CHAR, SPACE_CHAR, SPACE_CHAR);
uvec4 _Smooth_intersect_ = uvec4(0x35D6F6F6, 0x47860296, 0xE6475627, 0x37563647);
uvec4 _ions_ =             uvec4(0x96F6E637, SPACE_CHAR, SPACE_CHAR, SPACE_CHAR);
uvec4 _Add_more_circles_ = uvec4(0x14464602, 0xD6F62756, 0x02369627, 0x36C65637);
uvec4 _Increase_light_ =   uvec4(0x94E63627, 0x56163756, 0x02C69676, 0x8647);
uvec4 _Apply_noisy_shap_ = uvec4(0x140707C6, 0x9702E6F6, 0x96379702, 0x37861607);
uvec4  _e_ =               uvec4(0x56,       SPACE_CHAR, SPACE_CHAR, SPACE_CHAR);
uvec4 _XX_Swirls_ =        uvec4(0x23E20235, 0x779627C6, 0x37,       SPACE_CHAR);
uvec4 _Draw_a_swirl_ =     uvec4(0x44271677, 0x02160237, 0x779627C6, SPACE_CHAR);
uvec4 _rotation_ =         uvec4(0x27F64716, 0x4796F6E6, SPACE_CHAR, SPACE_CHAR);

bool text(vec2 u, out vec4 O)
{
  bool b = false;
  O = vec4(0.);
  if (fontCol.w > 0.)
  {
    O = vec4((0.6 + 0.6 * cos(6.3 *
      ((u.x * 6. - iResolution.x * 0.25) / (3.14 * iResolution.y)) + vec4(0., 23., 21., 0.))
      * 0.85 + 0.15) * fontCol.x);
    b = true;
  }
  return b;
}

void mainImage(out vec4 O, vec2 u)
{
  pix = 150.;
  
  fontSize = 0.075;
  fontSpacing = 0.45;
  fontUV = viewport(u);
  fontColFill = vec3(1.);
  fontColBorder = vec3(0.);
  
  O = vec4(0.);
    
  if (iTime < 4.)
  {
    fontSize = 0.1;
    fontCaret = vec2(-0.4, 0.1);
    _(_How_to_make_this_);
    if (text(u, O)) return;

    fontCaret = vec2(-0.425, 0.0);
    _(_starfield_X_);
    if (text(u, O)) return;
     
    starfield(u, O);
  } else if (iTime < 6.) {
    fontSize = 0.1;
    fontCaret = vec2(-0.25, 0.05);
    _(_XX_Circles_);
    text(u, O);
    O *= (iTime > 5. ? (6. - iTime) / 2. : 1.);
  } else if (iTime < 8.) {
    fontCaret = vec2(-0.825, 0.4);    
    _(_Draw_a_circled_l_);
    if (text(u, O)) return;
    
    fontCaret = vec2(-0.29, 0.4); 
    _(_ight_);
    if (text(u, O)) return;
    
    vec2 U = (u - iResolution.xy * 0.5) / iResolution.y;
    O = vec4(vec3(0.5 - length(U)), 1.) * min(1., iTime - 6.);
  } else if (iTime < 10.) {
    fontCaret = vec2(-0.825, 0.4);    
    _(_Then_a_full_grid_);
    if (text(u, O)) return;
    
    vec2 U = (iTime > 8. ? min(1., (iTime - 8.) * 0.5) * 9. + 1. : 1.)
      * (u - iResolution.xy * 0.5) / iResolution.y;
    vec2 i = floor(U), f = fract(U), p = U;

    float d = 0., c;
    for (int k = 0; k < 9; k++)
    {
      p = vec2(k % 3, k / 3) - 1.;
      p -= f;

      c = 0.5 - length(p);
      d = max(d, c);
    }
    O = vec4(vec3(max((9. - iTime), 0.) * (-length(U) + 0.5) + d * min(1., iTime - 8.)), 1.);
  } else if (iTime < 20.) {
    if ((iTime < 14.) || ((iTime > 15.) && (iTime < 19.)))
    {
      fontCaret = vec2(-0.825, 0.4);
      _((iTime < 14. ? _Randomize_their_ : (iTime < 17. ? _Reduce_color_num_ : _Smooth_intersect_)));
      if (text(u, O)) return;
    
      fontCaret = vec2(-0.29, 0.4);
      _((iTime < 12. ? _size_ : (iTime < 14. ? _position_ : (iTime < 17. ? _ber_ : _ions_))));
      if (text(u, O)) return;
    }
    
    vec2 U = (iTime < 14. ? 10. * (2. + (u - iResolution.xy * 0.5) / iResolution.y) : 
      (iTime < 19. ? 20. + (max(0., 15. - iTime) * 7. + 3.) * (u - iResolution.xy * 0.5) / iResolution.y :
        20. + (min(1., iTime - 19.) * 7. + 3.) * (u - iResolution.xy * 0.5) / iResolution.y));
    uint seed = SEED + 10u;
    vec2 i = floor(U), f = fract(U), p = U, h;

    float d = 0., c, rad;
    for (int k = 0; k < 9; k++)
    {
      p = vec2(k % 3, k / 3) - 1.;
      rad = max((12. - iTime) * 0.5, 0.) * 0.5
        + (0.25 + hash(i + p, seed + 2u) * 0.5) * min(1., (iTime - 10.) * 0.5);
      h = clamp((iTime - 12.) * 0.5, 0., 1.) * vec2(hash(i + p, seed + 89u), hash(i + p, seed + 52u));
      p += h - f;

      c = rad - length(p);
      d = (iTime < 17. ? max(d, c) : smax(d, c, min(1., iTime - 17.) * 0.3));
    }
    O = vec4(vec3(d), 1.);
    if (iTime > 15.)
    {
      float cols = max(0., 16. - iTime) * 100. + COLS;
      O = floor(O * cols) / cols;
    }
  } else if (iTime < 25.) {
    fontCaret = vec2(-0.825, 0.4);    
    _((iTime < 22. ? _Add_more_circles_ : _Increase_light_));
    if (text(u, O)) return;
    
    vec2 U = 10. * (2. + (u - iResolution.xy * 0.5) / iResolution.y);
    float g = max(fbmCircles(U, SEED + 10u), fbmCircles(U, SEED + 20u));
    O = vec4(vec3((iTime < 22. ? max(0., 0.5 * (22. - iTime)) * (circles(U, 0.5, -1., SEED + 10u))
      + min(1., (iTime - 20.) * 0.5) * g : max(0., 0.5 * (24. - iTime)) * g
      + min(1., (iTime - 22.) * 0.5) * smax(-1., g, 3.2 * min(1., (iTime - 22.) * 0.5)))), 1.);;
    O = floor(O * COLS) / COLS;
  } else if (iTime < 28.) {
    fontCaret = vec2(-0.825, 0.4);    
    _(_Apply_noisy_shap_);
    if (text(u, O))
    {
      O *= clamp(28. - iTime, 0., 1.); return;
    }
    
    fontCaret = vec2(-0.29, 0.4);
    _(_e_);
    if (text(u, O))
    {
      O *= clamp(28. - iTime, 0., 1.); return;
    }
    
    vec2 bU = 2. + (u - iResolution.xy * 0.5) / iResolution.y;
    vec2 U = 10. * bU;
    float fv = fbmVoronoi(0.25 * bU, SEED);
    fv *= fv * 1.5;
    float g = max(fbmCircles(U, SEED + 10u), fbmCircles(U, SEED + 20u));
    g = smax(-1., g, 3.2);
    O = vec4(vec3(g * (min(1., iTime - 25.) * fv + max(0., 26. - iTime))), 1.);
    O = (floor(O * COLS) / COLS) * clamp(28. - iTime, 0., 1.);
  } else if (iTime < 30.) {
    fontSize = 0.1;
    fontCaret = vec2(-0.225, 0.05);
    _(_XX_Swirls_);
    text(u, O);
    O *= (30. - iTime) * 0.5;
  } else if (iTime < 33.) {
    if (iTime > 31.)
    {
      fontCaret = vec2(-0.825, 0.4);    
      _(_Draw_a_swirl_);
      if (text(u, O)) return;
    }
    
    vec2 U = (u - iResolution.xy * 0.5) / iResolution.y;
    U = rotation(U, 5. * clamp((iTime - 31.) * 0.5, 0., 1.) * (1. - smoothstep(0., 0.5, length(U))));
    pix = 2.;
    vec2 UU = floor(U * pix) / pix;
    bool d1 = mod(U.x + UU.y, 2. / pix) < 1. / pix;
    
    pix = sqrt(pix);
    U = rotation(U, 0.7853);
    UU = floor(U * pix) / pix;
    bool d2 = mod(U.x + UU.y, 2. / pix) < 1. / pix;
    
    O = vec4(vec3(0.2 + 0.2 * (float(d1 || d2) - float(d1 && d2))), 1.) * min(1., iTime - 30.);   
  } else if (iTime < 38.) {
    fontCaret = vec2(-0.825, 0.4);    
    _((iTime < 35. ? _Then_a_full_grid_ : _Randomize_their_));
    if (text(u, O)) return;
    
    if (iTime > 35.)
    {
      fontCaret = vec2(-0.29, 0.4);    
      _(_rotation_);
      if (text(u, O)) return;
    }
    
    vec2 U = (iTime < 35. ?
      (min(1., (iTime - 33.) * 0.5) * 9. + 1.) * (u - iResolution.xy * 0.5) / iResolution.y :
      10. * (2. + (u - iResolution.xy * 0.5) / iResolution.y));
    
    if (length(U) > 0.5)
    {
      vec2 i = floor(U), f = fract(U), d;
      int k;
      float r, h;
      for (k = 0; k < 9; k++)
      {
        d = vec2(k % 3, k / 3) - 1.;
        h = hash(i + d, SEED + 72u) * 2. - 1.;
        r = length(f - d) * (1. + abs(h) * clamp(iTime - 35., 0., 1.));
        f = rotation(f - d, (iTime < 35. ? 5. * clamp((iTime - 33.) * 0.5, 0., 1.)
          * (1. - smoothstep(0., 0.5, r)) :
          (5. * clamp(0.5 * (37. - iTime), 0., 1.) * (1. - smoothstep(0., 0.5, length(f - d))) +
           1.5 * clamp(0.5 * (iTime - 35.), 0., 1.) * sign(h) * (1. - smoothstep(0., 0.5, r))))) + d;
        U = f + i;
      }
    } else {
      U = rotation(U, 5. * (1. - smoothstep(0., 0.5, length(U))));
    }
    
    pix = 2.;
    vec2 UU = floor(U * pix) / pix;
    bool d1 = mod(U.x + UU.y, 2. / pix) < 1. / pix;
    
    pix = sqrt(pix);
    U = rotation(U, 0.7853);
    UU = floor(U * pix) / pix;
    bool d2 = mod(U.x + UU.y, 2. / pix) < 1. / pix;
    
    O = vec4(vec3(0.2 + 0.2 * (float(d1 || d2) - float(d1 && d2))), 1.);
  } else {
    vec2 U = 2. + (u - iResolution.xy * 0.5) / iResolution.y;
    float fv = fbmVoronoi(0.25 * U, SEED);
    fv *= fv * 1.5;
    vec2 aU = fbmSwirls(U, SEED) * 10.;
    float g = max(fbmCircles(aU, SEED + 10u), fbmCircles(aU, SEED + 20u));
    g = smax(-1., g, 3.2);
    O = vec4(vec3(g * fv), 1.);
    O = floor(O * COLS) / COLS;
  }
}
