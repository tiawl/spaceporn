# define BufferAChannel iChannel0
# define fontChannel    iChannel1
# define SPACE_CHAR 0x02U
# define STOP_CHAR  0x0AU

# define _How_to_make_this_ uvec4(0x84F677,   0x47F602D6, 0x16B656,   0x47869637)
# define _starfield_X_      uvec4(0x02020237, 0x47162766, 0x9656C646, 0x02F3)
# define _XX_Details_       uvec4(0x43E20244, 0x56471696, 0xC637,     SPACE_CHAR)
# define _Add_pixelization_ uvec4(0x144646,   0x07968756, 0xC696A716, 0x4796F6E6)
# define _Add_dithering_    uvec4(0x144646,   0x46964786, 0x562796E6, 0x76)
# define _Colorize_         uvec4(0x34F6C6F6, 0x2796A756, SPACE_CHAR, SPACE_CHAR)
# define _Animate_stars_    uvec4(0x14E696D6, 0x164756,   0x37471627, 0x37)
# define _Animate_color_    uvec4(0x14E696D6, 0x164756,   0x36F6C6F6, 0x27)

# define FONT_NB int[](0x03, 0x13, 0x23, 0x33, 0x43, 0x53, 0x63, 0x73, 0x83, 0x93)

vec4 fontCol;vec3 fontColFill;vec3 fontColBorder;vec4 fontBuffer;vec2 fontCaret;float fontSize;float fontSpacing;vec2 fontUV;float log10(float x){if (x < 9.9999){return 0.;} else if (x < 99.9999) {return 1.;} else if (x < 999.9999) {return 2.;} else if (x < 9999.9999) {return 3.;} else if (x < 99999.9999) {return 4.;} else {return floor(log(x) / log(10.));}}vec4 fontTextureLookup(vec2 xy){float dxy = 1024.*1.5;vec2 dx = vec2(1.,0.)/dxy;vec2 dy = vec2(0.,1.)/dxy;return (texture(fontChannel,xy + dx + dy)+texture(fontChannel,xy + dx - dy)+texture(fontChannel,xy - dx - dy)+texture(fontChannel,xy - dx + dy)+2.*texture(fontChannel,xy))/6.;}void drawStr4(uint str){if (str < 0x100U){str = str * 0x100U + SPACE_CHAR;}if (str < 0x10000U){str = str * 0x100U + SPACE_CHAR;}if (str < 0x1000000U){str = str * 0x100U + SPACE_CHAR;}for (int i = 0; i < 4; i++){uint xy = (str >> 8 * (3 - i)) % 256U;if (xy != SPACE_CHAR){vec2 K = (fontUV - fontCaret) / fontSize;if (length(K) < 0.6){vec4 Q = fontTextureLookup((K + vec2(float(xy / 16U) + 0.5,16. - float(xy % 16U) - 0.5)) / 16.);fontBuffer.rgb += Q.rgb * smoothstep(0.6, 0.4, length(K));if (max(abs(K.x), abs(K.y)) < 0.5){fontBuffer.a = min(Q.a, fontBuffer.a);}}}if (xy != STOP_CHAR){fontCaret.x += fontSpacing * fontSize;}}}void beginDraw(){fontBuffer = vec4(0., 0., 0. , 1.);fontCol = vec4(0.);fontCaret.x += fontSpacing * fontSize / 2.;}void endDraw(){float a = smoothstep(1., 0., smoothstep(0.51, 0.53, fontBuffer.a));float b = smoothstep(0., 1., smoothstep(0.48, 0.51, fontBuffer.a));fontCol.rgb = mix(fontColFill, fontColBorder, b);fontCol.a = a;}void _(uint str){beginDraw();drawStr4(str);endDraw();}void _(uvec2 str){beginDraw();drawStr4(str.x);drawStr4(str.y);endDraw();}void _(uvec3 str){beginDraw();drawStr4(str.x);drawStr4(str.y);drawStr4(str.z);endDraw();}void _(uvec4 str){beginDraw();drawStr4(str.x);drawStr4(str.y);drawStr4(str.z);drawStr4(str.w);endDraw();}vec2 viewport(vec2 b){return (b / iResolution.xy - vec2(0.5)) * vec2(iResolution.x / iResolution.y, 1.);}

# define BIGSTARS_DENSITY 4.5
# define MAX_BIGSTAR_SZ 8.
# define COLS 18.
# define COL_SEED 0u
# define SEED 1u
# define SWIRLS_RADIUS 0.5

# define DIAMOND 0u
# define NOVA    1u
# define POLAR   2u

float pixel_res;float pix;float time;const float depth = 1. / 360.;struct Star{uint type;vec2 center;float size;float power;float brightness;uint shape;float diag;float ring_size;};float floor2(float x, float base){return floor(x / base) * base;}float sdCircle(vec2 p, float r){return length(p) - r;}float opRing(vec2 p, float r1, float r2){return abs(sdCircle(p, r1)) - r2;}float sdSegment(vec2 p, vec2 a, vec2 b){vec2 pa = p - a;vec2 ba = b - a;float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);return length(pa - ba * h);}float smax(float a, float b, float k){float h = max(k - abs(a - b), 0.);return max(a, b) + h * h * 0.25 / k;}vec2 rotation(vec2 p, float a){return p * mat2(cos(a), -sin(a), sin(a),cos(a));}uvec3 pcg3d(uvec3 v){v = v * 1664525u + 1013904223u;v.x += v.y * v.z;v.y += v.z * v.x;v.z += v.x * v.y;v ^= v >> 16u;v.x += v.y * v.z;v.y += v.z * v.x;v.z += v.x * v.y;return v;}float hash(vec2 s, uint hash_seed){float res;uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));res = float(p) * (1. / float(0xffffffffu));return res;}float circles(vec2 p, float r, float w, uint s){vec3 col;vec2 i = floor(p), f = fract(p), h;int k, q;float d = (sign(w) > -0.5 ? 8. : -1e9), c, rad, h2;for (k = -1; k < 2; k++){for (q = -1; q < 2; q++){p = vec2(k, q);h = vec2(hash(i + p, s + 89u), hash(i + p, s + 52u));c = length(p + h - f);if (sign(w) > -0.5){col = 0.5 + 0.5 * sin(hash(i + p, SEED + 32u) * 2.5 + 3.5 + vec3(2.));h2 = smoothstep(0., 1., 0.5 + 0.5 * (d - c) / w);d = mix(d, c, h2) - h2 * (1. - h2) * w / (1. + 3. * w);} else {rad = r / 2. + hash(i + p, s + 2u) * r;d = smax(d, rad - c, 0.3);}}}return (sign(w) > -0.5 ? 1. - d : d);}float fbmVoronoi(vec2 U, uint seed){float r = (circles(1.5 * U, -1., 0.3, seed)) * 0.625 + (circles(3. * U, -1., 0.3, seed + 314u)) * 0.25 + (circles(6. * U, -1., 0.3, seed + 92u)) * 0.125;return r;}float fbmCircles(vec2 p, uint se){float s = 1., d = 0.;int o = 2;for (int i = 0; i < o; i++){float n = s * circles(p, 0.5, -1., se);d = smax(d, n, 0.3 * s);p *= 2.;s = 0.5 * s;}return d;}vec2 swirls(vec2 p, uint se, float ro){vec2 i = round(p), d, cc;int k, q;float r, h;for (k = -1; k < 2; k++){for (q = -1; q < 2; q++){cc = i + vec2(k, q);d = cc + vec2(hash(cc, se + 222u), hash(cc, se + 278u)) - vec2(0.5);h = hash(cc, se + 72u)  * 2. - 1.;p -= d;r = ro * sign(h) * smoothstep(0., SWIRLS_RADIUS, (SWIRLS_RADIUS - length(p)) * abs(h));p = rotation(p, r) + d;}}return p;}vec2 fbmSwirls(vec2 p, uint se){uint o = 3u;float sz = 42., ro = 1.5;p *= 360. / sz;for (uint i = 0u; i < o; i++){p = swirls(p, se + i, ro);}return p / (360. / sz);}float diamond(vec2 coords, Star star){star.brightness = 1. / star.brightness;vec2 A = vec2(-star.size, 0.);vec2 B = vec2( star.size, 0.);vec2 C = vec2(0.,star.size);vec2 D = vec2(0., -star.size);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;float m = min(s1, s2);float color = (sign(m) < 0.5 ? -1. : 0.);color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;float ring = opRing(coords, star.size * star.ring_size,depth * BIGSTARS_DENSITY * (100. / pix) * 1.5);ring = (sign(ring) < 0.5 ? -1. : 0.);color = min(color * 1.3, ring * 0.5 * star.power);return color;}float novapattern(vec2 coords, Star star){float res = 1e9;coords = abs(coords);if ((star.size / star.diag >= 1.5 * pixel_res) && (star.shape > 24u)){vec2 A = vec2(3. * pixel_res, pixel_res);vec2 B = vec2(pixel_res, 3. * pixel_res);vec2 C = vec2(2. * pixel_res, pixel_res);vec2 D = vec2(pixel_res, 2. * pixel_res);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;res = min(res, min(s1, s2));} else if (star.shape > 24u) {vec2 A = vec2(2. * pixel_res, pixel_res);vec2 B = vec2(pixel_res, 2. * pixel_res);res = min(res, sdSegment(coords, A, B) - depth);}if ((star.shape >= 30u) && (star.shape <= 32u)){if (star.size / star.diag >= 1.5 * pixel_res){vec2 A = vec2(5. * pixel_res, 2. * pixel_res);vec2 B = vec2(4. * pixel_res, 2. * pixel_res);vec2 C = vec2(2. * pixel_res, 4. * pixel_res);vec2 D = vec2(2. * pixel_res, 5. * pixel_res);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;res = min(res, min(s1, s2));} else {vec2 A = vec2(3. * pixel_res, 3. * pixel_res);vec2 B = vec2(5. * pixel_res, 5. * pixel_res);res = min(res, sdSegment(coords, A, B) - depth);}} else if ((star.shape >= 33u) && (star.shape <= 35u)) {if (star.size / star.diag >= 1.5 * pixel_res){vec2 A = vec2(5.* pixel_res, 2.* pixel_res);vec2 B = vec2(4.5 * pixel_res, 2.* pixel_res);vec2 C = vec2(2.* pixel_res, 4.5 * pixel_res);vec2 D = vec2(2.* pixel_res, 5.* pixel_res);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;res = min(res, min(s1, s2));} else {vec2 A = vec2(3. * pixel_res, 3. * pixel_res);vec2 B = vec2(5. * pixel_res, 5. * pixel_res);res = min(res, sdSegment(coords, A, B) - depth);}} else if ((star.shape >= 36u) && (star.shape <= 38u)) {if (star.size / star.diag >= 1.5 * pixel_res){vec2 A = vec2(4.* pixel_res, 2.* pixel_res);vec2 B = vec2(3.5 * pixel_res, 2.* pixel_res);vec2 C = vec2(2.* pixel_res, 3.5 * pixel_res);vec2 D = vec2(2.* pixel_res, 4.* pixel_res);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;res = min(res, min(s1, s2));} else {vec2 A = vec2(3. * pixel_res, 3. * pixel_res);vec2 B = vec2(5. * pixel_res, 5. * pixel_res);res = min(res, sdSegment(coords, A, B) - depth);}}return res;}float nova(vec2 coords, Star star){star.brightness = 1. / star.brightness;float size = (star.shape == 39u ? 17. * pixel_res / star.size :(star.shape == 40u ? 11. * pixel_res / star.size : star.size));vec2 A = vec2(-size, 0.);vec2 B = vec2(size, 0.);vec2 C = vec2(0., size);vec2 D = vec2(0., -size);vec2 E = vec2(-size / star.diag,size / star.diag);vec2 F = vec2( size / star.diag, -size / star.diag);vec2 G = vec2( size / star.diag,size / star.diag);vec2 H = vec2(-size / star.diag, -size / star.diag);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;float s3 = sdSegment(coords, E, F) - depth;float s4 = sdSegment(coords, G, H) - depth;float m = min(min(min(s1, s2), min(s3, s4)), novapattern(coords, star));float color = (sign(m) < 0.5 ? -1. : 0.);color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;size = (star.shape > 38u ? star.size * 0.35 + 70. / pix : star.size);float ring = opRing(coords, size * star.ring_size,depth * BIGSTARS_DENSITY * (100. / pix) * (star.size / pixel_res > 7. ? 1. : 1.5));ring = (sign(ring) < 0.5 ? -1. : 0.);color = min(color * 1.3, ring * 0.5 * star.power);return color;}float polar(vec2 coords, Star star){star.brightness = 1. / star.brightness;vec2 A = vec2(-star.size, 0.);vec2 B = vec2(star.size, 0.);vec2 C = vec2(0.,star.size / (star.diag * 2. / 3.));vec2 D = vec2(0., -star.size / (star.diag * 2. / 3.));vec2 E = vec2(-star.size / star.diag, star.size / star.diag);vec2 F = vec2( star.size / star.diag, -star.size / star.diag);vec2 G = vec2( star.size / star.diag, star.size / star.diag);vec2 H = vec2(-star.size / star.diag, -star.size / star.diag);float s1 = sdSegment(coords, A, B) - depth;float s2 = sdSegment(coords, C, D) - depth;float s3 = sdSegment(coords, E, F) - depth;float s4 = sdSegment(coords, G, H) - depth;float m = min(min(s1, s2), min(s3, s4));float color = (sign(m) < 0.5 ? -1. : 0.);color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;float ring = opRing(coords, star.size * star.ring_size,depth * BIGSTARS_DENSITY * (100. / pix) * (star.size / pixel_res > 7. ? 1. : 1.5));ring = (sign(ring) < 0.5 ? -1. : 0.);color = min(color * 1.3, ring * 0.5 * star.power);return color;}float calc_star(vec2 coords, vec2 center, bool anim){float type = hash(center, SEED + 2u);uint rd_bigstar = (type < 0.15 ? NOVA : (type < 0.3 ? POLAR : DIAMOND));float size_hash = hash(center, SEED + 3u) * 0.05;float min_size = (rd_bigstar == DIAMOND ? 3. : 7.);float max_size = MAX_BIGSTAR_SZ - min_size;float size =(min(floor(size_hash * (max_size + 1.)), max_size) + min_size) * pixel_res * (pix / 150.);float brightness = hash(center, SEED + 4u) + 1.;float ring_size = hash(center, SEED + 5u) * 0.8;ring_size = (ring_size * size < pixel_res * 4. ? 0. : ring_size);float power = round(sin((anim ? iTime : 1.) * (3. + 4. * hash(center, SEED + 6u)))) * 0.2 + 1.;float star = 0.;Star bigstar =Star(rd_bigstar, center, size, power, 1., 0u, 1., ring_size);if (bigstar.type == DIAMOND){bool rotated = hash(bigstar.center, SEED + 7u) > 0.5;bigstar.brightness *= bigstar.size;bigstar.brightness *= bigstar.power;coords = rotation(coords, radians(rotated ? 45. : 0.));star = diamond(coords, bigstar);} else if (bigstar.type == NOVA) {bigstar.shape = uint(ceil(hash(bigstar.center, SEED + 7u) * 38.));bigstar.diag = (bigstar.shape > 38u ? 0. :(bigstar.shape < 25u ?1. + hash(bigstar.center, SEED + 8u) * 3.5 :hash(bigstar.center, SEED + 8u) > 0.5 ? bigstar.size / pixel_res :2. + hash(bigstar.center, SEED + 9u) * 3.));bigstar.brightness = (bigstar.shape > 38u ?100. / pix : bigstar.size * bigstar.brightness);bigstar.brightness *= bigstar.power;star = nova(coords, bigstar);} else {bigstar.brightness *= bigstar.size;bigstar.brightness *= bigstar.power;bigstar.diag = 2.5 + hash(bigstar.center, SEED + 7u) * 0.5;star = polar(coords, bigstar);}return star;}vec3 bigstars(vec2 coords, bool anim, bool l){coords *= BIGSTARS_DENSITY;float d = 1e9, c;pixel_res = BIGSTARS_DENSITY / pix;vec2 i = floor(coords);vec2 f = fract(coords);vec2 h, o, p, center, tmp;for (int k = 0; k < 9; k++){o = vec2(k % 3, k / 3) - 1.;center = i + o;h = vec2(hash(center, SEED), hash(center, SEED + 1u));p = vec2(floor2(o.x + h.x - f.x, pixel_res),floor2(o.y + h.y - f.y, pixel_res));c = calc_star(p, center, anim);if (c < d){d = c;tmp = p;}}vec2 U = (coords + tmp) / BIGSTARS_DENSITY;float fv = fbmVoronoi(U, SEED);return vec3(l ? -d * fv * fv * 0.5 : -d, U * pix);}vec3 hsv2rgb(vec3 c){vec3 rgb = clamp(abs(mod(c.x * 6.+ vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);return c.z * mix(vec3(1.), rgb, c.y);}vec3 color(float sm, uint cseed, bool t){float var = (t ? 0.01 * sin(iTime * 50.) : 0.);float hu, sa = 0., br = 0.;sa += var * 2.;hu = radians(6.2832 * (9. * hash(vec2(1.), cseed)+ sm * (hash(vec2(10.), cseed) * 0.25)));if (sm < 2.5){sa += 0.2 + 0.15 * sm;} else if (sm < 4.5) {sa += 0.35 + 0.1 * (sm - 2.);} else {sa += 0.55 - 0.07 * (sm - 4.);}if (sm < 3.5){br += 0.1 + 0.1 * sm;} else if (sm < 6.5) {br += 0.5 + 0.075 * (sm - 3.);} else {br += 0.7 + 0.1 * (sm - 6.);}return hsv2rgb(vec3(hu, sa, br));}

void starfield(vec2 u, out vec4 O)
{
  vec2 bU = 2.1 + (u - iResolution.xy * 0.5) / iResolution.y + time * 0.05;
  vec2 U = floor(bU * pix) / pix;
  bool dith = mod(bU.x + U.y, 2. / pix) < 1. / pix;

  float fv = fbmVoronoi(U, SEED);
  vec2 aU = fbmSwirls(U, SEED) * 10.;
  float g = max(fbmCircles(aU, SEED + 10u), fbmCircles(aU, SEED + 20u));
  g = smax(-1., g, 3.2) * fv * fv;
  g *= (dith ? 1.35 : 1.5);

  vec3 b = bigstars(U, true, true) * vec3(4., 1., 1.);

  g = max(b.x, g);
  g = floor(g * COLS) / COLS;
  O = vec4(color(10. * g, COL_SEED, true), 1.);
}

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
  pix = iResolution.y;
  vec2 v = viewport(u);
  fontSize = 0.075;
  fontSpacing = 0.45;
  fontUV = viewport(u);
  fontColFill = vec3(1.);
  fontColBorder = vec3(0.);
  uvec4 txt = uvec4(0x02020202);

  time = min(VIDEO_LENGTH, iTime + texelFetch(BufferAChannel, ivec2(u), 0).x);

  O = vec4(0.);

  fontCaret = vec2(-0.85, -0.45);
  float p = time * 10., power;
  float chars = log10(p) + 1.;
  int str = (p < 10. ? 0x020203E2 : 0x02020202), a = 0;
  while (chars > 0.5)
  {
    chars -= 1.;
    power = pow(10., chars);
    str = (str << 8) + FONT_NB[int(p / power)];
    if ((time * 10. >= 100. && a == 1) || (time * 10. >= 10. && time * 10. <= 100. && a == 0))
      str = (str << 8) + 0xE2;
    p = floor(mod(p, power));
    a++;
  }
  _(uvec3(str, 0xF22313E2, 0x03));
  if (text(u, O)) return;

  if (time < 4.)
  {
    fontSize = 0.1;
    if (v.y > 0.15)
    {
      fontCaret = vec2(-0.4, 0.2);
      txt = _How_to_make_this_;
    } else if (v.y > 0.) {
      fontCaret = vec2(-0.425, 0.1);
      txt = _starfield_X_;
    } else {
      fontCaret = vec2(-0.275, -0.15);
      txt = _XX_Details_;
    }
  } else if (time < 6.) {
  } else if (time < 8.) {
    fontCaret = vec2(-0.825, 0.4);
    txt = _Add_pixelization_;
  } else if (time < 10.) {
    fontCaret = vec2(-0.825, 0.4);
    txt = _Add_dithering_;
  } else if (time < 12.) {
    fontCaret = vec2(-0.825, 0.4);
    txt = _Colorize_;
  } else if (time < 15.) {
    fontCaret = vec2(-0.825, 0.4);
    txt = _Animate_stars_;
  } else if (time < 17.) {
    fontCaret = vec2(-0.825, 0.4);
    txt = _Animate_color_;
  }

  _(txt);
  if (text(u, O)) { O *= (time > 3. && time < 4. ? (4. - time) * 0.5 : 1.); return; }

  if ((time < 4.) || (time > 17.))
  {
    pix = 150.;
    time -= (time > 17. ? 17. : 0.);
    starfield(u, O);
    O *= (time > 3. ? (4. - time) * 0.5 : 1.);
  } else {
    pix = iResolution.y * clamp(0.5 * (8. - time), 0., 1.) + 150. * clamp(0.5 * (time - 6.), 0., 1.);
    vec2 bU = 2.1 + (u - iResolution.xy * 0.5) / iResolution.y;
    vec2 U = floor(bU * pix);
    bool dith = mod(U.x + U.y, 2.) < 1.;
    U /= pix;

    float fv = fbmVoronoi(U, SEED);
    fv *= fv;
    vec2 aU = fbmSwirls(U, SEED) * 10.;
    float g = max(fbmCircles(aU, SEED + 10u), fbmCircles(aU, SEED + 20u));
    g = smax(-1., g, 3.2) * fv;
    g *= (dith && time > 8. ? 1.5 - 0.15 * min(1., (time - 8.) * 0.5) : 1.5);

    vec3 b = bigstars(U, time > 13., true) * vec3(4., 1., 1.);

    g = floor(max(b.x, g) * COLS) / COLS;

    O = vec4((time < 10. ? vec3(g) : vec3(g) * clamp(0.5 * (12. - time), 0., 1.)
      + color(10. * g, COL_SEED, time > 15.) * clamp(0.5 * (time - 10.), 0., 1.)), 1.) * min(1., time - 4.);
  }
}
