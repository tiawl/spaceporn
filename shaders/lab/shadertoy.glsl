# define PIX 150.

float pixel_res;
uint seed;
uint col_seed;

# define MAX_BIGSTAR_SZ 8.
# define BIGSTARS_DENSITY 4.

# define DIAMOND 0u
# define NOVA    1u
# define POLAR   2u
# define STAR_TYPES 3.

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

float noise(vec2 coord, uint noise_seed)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);
  f = f * f * (3. - 2. * f);

  float a = hash(i, noise_seed);
  float b = hash(i + vec2(1., 0.), noise_seed);
  float c = hash(i + vec2(0., 1.), noise_seed);
  float d = hash(i + vec2(1., 1.), noise_seed);

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// https://iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm
float voronoi( in vec2 x, float w, uint seed)
{
    vec2 n = floor( x );
    vec2 f = fract( x );

	float m = 8.;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec2 o = vec2(hash( n + g , seed), hash( n + g , seed + 84u));

        // distance to cell		
		float d = length(g - f + o);
		
        // cell color
		vec3 col = 0.5 + 0.5*sin( hash(n+g, seed + 32u)*2.5 + 3.5 + vec3(2.));
        
        // do the smooth min for colors and distances		
		float h = smoothstep( 0.0, 1.0, 0.5 + 0.5*(m-d)/w );
	    m = mix( m,     d, h ) - h*(1.0-h)*w/(1.0+3.0*w); // distance
    }
	
	return 1. - m;
}

float fbmVoronoi( in vec2 U, uint seed)
{
  float r = (voronoi(6. * U, 0.3, seed)) * 0.625
    + (voronoi(12. * U, 0.3, seed + 314u)) * 0.25 +
    + (voronoi(24. * U, 0.3, seed + 92u)) * 0.125;
  return r;
}

// https://iquilezles.org/www/articles/smin/smin.htm
float smin(float a, float b, float k)
{
  float h = max(k - abs(a - b), 0.);
  return min(a, b) - h * h * 0.25 / k;
}

vec2 rotation(vec2 p, float a)
{
  return p * mat2(cos(a), -sin(a),
                  sin(a),  cos(a));
}

// https://www.shadertoy.com/view/NsfyDs
float circles( vec2 p, float r, uint s)
{
  vec2 i = floor(p), f = fract(p), h, a;

  float d = 1e9, c, rad;
  for(int k = 0; k < 9; k++)
  {
    p = vec2(k % 3, k / 3) - 1.;
    rad = 0.2 + hash(i + p, s + 2u) * r;
    h = vec2(hash(i + p, s + 89u), hash(i + p, s + 52u));

    p += h - f;

    c = length(p) - rad;
    d = smin(d, c, 0.3);
  }
  return d;
}

// https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
float fbmCircles(vec2 p, uint se)
{
  float s = 1., d = 1.;
  int o = 2;
  for(int i = 0; i < o; i++)
  {
    float n = s * circles(p, 0.5, se);

    d = smin(d, n, 0.3 * s);

    p *= 2.;
    s = 0.5 * s;
  }
  return d;
}

// original author warned against discontinuities that I did not fix:
// https://www.shadertoy.com/view/fsKSWD
vec2 swirls(vec2 p, uint se, float sz, float ro)
{
  float r;
  float s = 0.012 * sz;

  p = p * s * iResolution.y;
  vec2 F = abs(fract(p + 0.5) - 0.5);
  float y = min(F.x, F.y);
  vec2 I = floor(p);
  F = fract(p);

  float d = 3. * ro;
  y = d * cos(d * y);
  p -= p;
  vec2 D;
  int k;
  for (k = 0; k < 9; k++)
  {
    D = vec2(k % 3, k / 3) - 1.;
    D += hash(I + D, se + 222u);
    r = length(F - D) * (1. + hash(I + D, se + 72u));
    F = rotation(F - D, y * smoothstep(0.5, 0., r)) + D;
    p = F + I;
  }
  return p / (s * iResolution.y);
}

vec2 fbmSwirls(vec2 p, uint se)
{
  uint o = 3u;
  float sz = 2., ro = 0.5;
  for(uint i = 0u; i < o; i++)
  {
    p = swirls(p, se + i, sz, ro);
    sz *= 1.;
  }
  return p;
}

float floor2(float x, float base)
{
  return floor(x / base) * base;
}

vec2 rotate(vec2 coords, vec2 center, float angle)
{
  coords -= center;
  coords *= mat2(cos(angle), -sin(angle),
                 sin(angle),  cos(angle));
  coords += center;
  return coords;
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

float diamond(vec2 coords, Star star)
{
  star.brightness = 1. / star.brightness;
  vec2 A = vec2(-star.size,         0.);
  vec2 B = vec2( star.size,         0.);
  vec2 C = vec2(        0.,  star.size);
  vec2 D = vec2(        0., -star.size);

  float depth = 1. / 360.;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float m = min(s1, s2);

  float color = (sign(m) < 0.5 ? -1. : 0.);
  color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;

  float ring = opRing(coords, star.size * star.ring_size,
    depth * BIGSTARS_DENSITY * (100. / PIX) * 1.5);
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return color;
}

float novapattern(vec2 coords, Star star)
{
  float depth = 1. / iResolution.y;
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

  float depth = 1. / 360.;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(min(s1, s2), min(s3, s4)), novapattern(coords, star));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;

  size = (star.shape > 38u ? star.size * 0.35 + 70. / PIX : star.size);
  float ring = opRing(coords, size * star.ring_size,
    depth * BIGSTARS_DENSITY * (100. / PIX) * (star.size / pixel_res > 7. ? 1. : 1.5));
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

  float depth = 1. / 360.;
  float s1 = sdSegment(coords, A, B) - depth;
  float s2 = sdSegment(coords, C, D) - depth;
  float s3 = sdSegment(coords, E, F) - depth;
  float s4 = sdSegment(coords, G, H) - depth;
  float m = min(min(s1, s2), min(s3, s4));

  float color = (sign(m) < 0.5 ? -1. : 0.);
  color *= 1. - (abs(coords.x) + abs(coords.y)) * star.brightness;

  float ring = opRing(coords, star.size * star.ring_size,
    depth * BIGSTARS_DENSITY * (100. / PIX) * (star.size / pixel_res > 7. ? 1. : 1.5));
  ring = (sign(ring) < 0.5 ? -1. : 0.);
  color = min(color * 1.3, ring * 0.5 * star.power);

  return color;
}

float calc_star(vec2 coords, vec2 center)
{
  float type = hash(center, seed + 2u);
  uint rd_bigstar = (type < 0.15 ? NOVA : (type < 0.3 ? POLAR : DIAMOND));
  float size_hash = hash(center, seed + 3u) * 0.05;
  float min_size = (rd_bigstar == DIAMOND ? 3. : 7.);
  float max_size = MAX_BIGSTAR_SZ - min_size;
  float size =
    (min(floor(size_hash * (max_size + 1.)), max_size) + min_size) * pixel_res;
  float brightness = hash(center, seed + 4u) + 1.;
  float ring_size = hash(center, seed + 5u) * 0.8;
  ring_size = (ring_size * size < pixel_res * 4. ? 0. : ring_size);
  float power = round(sin(iTime * (3. + 4. * hash(center, seed + 6u)))) * 0.2 + 1.;

  float star = 0.;
  Star bigstar =
    Star(rd_bigstar, center, size, power, 1., 0u, 1., ring_size);
  if (bigstar.type == DIAMOND)
  {
    bool rotation = hash(bigstar.center, seed + 7u) > 0.5;
    bigstar.brightness *= bigstar.size;
    bigstar.brightness *= bigstar.power;
    coords = rotate(coords, vec2(0.), radians(rotation ? 45. : 0.));
    star = diamond(coords, bigstar);
  } else if (bigstar.type == NOVA) {
    bigstar.shape = uint(ceil(hash(bigstar.center, seed + 7u) * 38.));
    bigstar.diag = (bigstar.shape > 38u ? 0. :
      (bigstar.shape < 25u ?
        1. + hash(bigstar.center, seed + 8u) * 3.5 :
        hash(bigstar.center, seed + 8u) > 0.5 ? bigstar.size / pixel_res :
        2. + hash(bigstar.center, seed + 9u) * 3.));
    bigstar.brightness = (bigstar.shape > 38u ?
      100. / PIX : bigstar.size * bigstar.brightness);
    bigstar.brightness *= bigstar.power;
    star = nova(coords, bigstar);
  } else {
    bigstar.brightness *= bigstar.size;
    bigstar.brightness *= bigstar.power;
    bigstar.diag = 2.5 + hash(bigstar.center, seed + 7u) * 0.5;
    star = polar(coords, bigstar);
  }
  return star;
}

float bigstars(vec2 coords)
{
  coords *= BIGSTARS_DENSITY;
  float d = 1e9,
        c;
  vec2 o, p;

  pixel_res = BIGSTARS_DENSITY / PIX;

  vec2 i = floor(coords);
  vec2 f = fract(coords);
  vec2 h;
  vec2 center, tmp;

  for (int k = 0; k < 9; k++)
  {
    o = vec2(k % 3, k / 3) - 1.;

    center = i + o;
    h = vec2(hash(center, seed), hash(center, seed + 1u));
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
  float fv = fbmVoronoi(0.25 * U, seed);
  
  vec2 aU = fbmSwirls(U, seed) * 10.;
  float g = min(fbmCircles(aU, seed + 10u), fbmCircles(aU, seed + 20u));
  g = -smin(1., g, 3.3) * fv * fv;
  
  return -d * g;
}

vec3 hsv2rgb(in vec3 c)
{
  vec3 rgb = clamp(abs(mod(c.x * 6.
    + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  return c.z * mix( vec3(1.), rgb, c.y);
}

// https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes
vec3 color(float sm)
{
  float hu, sa, br;
  hu = radians(3.1415926 * 2. * (9. * hash(vec2(1.), col_seed)
    + sm * (hash(vec2(10.), col_seed) * 0.5)));
  if (sm < 2.5)
  {
    sa = 0.2 + 0.15 * sm;
  } else if (sm < 3.5) {
    sa = 0.4;
  } else if (sm < 4.5) {
    sa = 0.5;
  } else {
    sa = 0.55 - 0.07 * (sm - 4.);
  }
  if (sm < 3.5)
  {
    br = 0.15 + 0.1 * sm;
  } else if (sm < 6.5) {
    br = 0.5 + 0.075 * (sm - 3.);
  } else {
    br = 0.7 + 0.1 * (sm - 6.);
  }
  return hsv2rgb(vec3(hu, sa, br));
}

void mainImage(out vec4 O, vec2 u)
{
  O -= O;
  float cols = 18.;
  seed = 1u + uint(floor(iTime * 0.5));
  col_seed = uint(floor(iTime * 0.5));
  vec2 bU = 2. + (u / iResolution.y);
  vec2 U = floor(bU * PIX) / PIX;
  
  bool dith = mod(bU.x + U.y, 2. / PIX) < 1. / PIX;
  float fv = fbmVoronoi(0.25 * U, seed);
  vec2 aU = fbmSwirls(U, seed) * 10.;
  float g = min(fbmCircles(aU, seed + 10u), fbmCircles(aU, seed + 20u));
  g = -smin(1., g, 3.3) * fv * fv;
  g *= (dith ? 0.85 : 1.);
  g = floor(g * cols) / cols;

  O = vec4(vec3(color(10. * max(bigstars(U) * 4., 1.5 * g))), 1.);
}
