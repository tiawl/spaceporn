/*
  - Mouse: move light,
  - Up: generate new "seed",
  - Down: use new color,
  - Right & Left: decrease/increase pixelization.
  Have fun.

  Part of: https://github.com/pabtomas/spaceporn
  UI inspired by: https://github.com/Deep-Fold/PixelPlanets

  I like learning. So if you have any advice to improve this, I will be happy to read you.
*/

// iChannel0 = BufferA

uint seed;
uint col_seed;
float pix;

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
  res = float(p) * (1.0 / float(0xffffffffu));
  return res;
}

float noise(vec2 coord, uint noise_seed)
{
  vec2 i = floor(coord);
  vec2 f = fract(coord);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash(i, noise_seed);
  float b = hash(i + vec2(1.0, 0.0), noise_seed);
  float c = hash(i + vec2(0.0, 1.0), noise_seed);
  float d = hash(i + vec2(1.0, 1.0), noise_seed);

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// https://iquilezles.org/www/articles/smin/smin.htm
float smin(float a, float b, float k)
{
  float h = max(k - abs(a - b), 0.0);
  return min(a, b) - h * h * 0.25 / k;
}

vec2 rotation(vec2 p, float a)
{
  return p * mat2(cos(a), -sin(a),
                  sin(a),  cos(a));
}

vec2 spherify(vec2 uv, vec2 center, float radius)
{
  vec2 centered = (uv - center) * 2.;
  float z = sqrt(radius * radius * 4. - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

// https://www.shadertoy.com/view/NsfyDs
float circles( vec2 p, float r, uint s)
{
  vec2 i = vec2(floor(p)), f = fract(p), h, a;

  float d = 1e9, c, rad;
  for(int k = 0; k < 9; k++)
  {
    p = vec2(k % 3, k / 3) - 1.;
    rad = hash(i + p, s + 2u) * r;
    h = vec2(hash(i + p, s + 89u), hash(i + p, s + 52u));

    // movement
    a = vec2(hash(i + p, s + 25u), hash(i + p, s + 215u));
    a = .3 * cos(5. * (a.x - .5) * iTime * 0.5 + 6.3 * a.y + vec2(0., 11.));
    p += .1 + .8 * h - f + a;

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
    float n = s*(circles(p, .5, se));

    d = smin(d, n, 0.3 * s);

    p *= 2.;
    s = 0.5 * s;
  }
  return d;
}

// original author warned against discontinuities that I did not fix:
// https://www.shadertoy.com/view/fsKSWD
vec2 swirls(vec2 p, out vec4 O, uint se, float sz, float ro)
{
  float r;
  float s = .012 * sz;

  p = p * s * R.y;
  vec2 F = abs(fract(p + .5) - .5);
  float y = min(F.x, F.y);
  O += smoothstep(12. / R.y, 0., y);
  vec2 I = floor(p);
  F = fract(p);

  float d = 3.*ro;
  y = d * cos(d * y);
  p -= p;
  vec2 D;
  int k;
  for (k = 0; k < 9; k++)
  {
    D = vec2(k % 3, k / 3) - 1.;
    D += hash(I + D, se + 222u);
    r = length(F - D) * (1. + hash(I + D, se + 72u));
    F = rotation(F - D, y * smoothstep(.5, 0., r)) + D;
    p = F + I;
  }
  return p / (s * R.y);
}

vec2 fbmSwirls(vec2 p, out vec4 O, uint se)
{
  uint o = 3u;
  O -= O;
  p += vec2(iTime * 0.02, 0.);
  float sz = 1., ro = 1.;
  for(uint i = 0u; i < o; i++)
  {
    p = swirls(p, O, se + i, sz, ro);
    sz *= 2.;
  }
  return p;
}

vec3 hsv2rgb(in vec3 c)
{
  vec3 rgb = clamp(abs(mod(c.x * 6.0
    + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0 );
  return c.z * mix( vec3(1.0), rgb, c.y);
}

// https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes
vec3 planet_color(float sm)
{
  float hu, sa, br;
  if (col_seed < 1u)
  {
    hu = radians(3.1415926 *2. *(5.5 + sm * 0.5));
  } else {
    hu = radians(3.1415926 * 2. * (9. * hash(vec2(1.), col_seed)
      + sm * (hash(vec2(10.), col_seed + 5u) * 2. - 1.)));
  }
  if (sm < 2.5)
  {
    sa = 0.2 + 0.075 * sm;
  } else if (sm < 3.5) {
    sa = 0.35;
  } else if (sm < 4.5) {
    sa = 0.4;
  } else {
    sa = 0.425 - 0.07 * (sm - 4.);
  }
  if (sm < 3.5)
  {
    br = 0.15 + 0.15 * sm;
  } else if (sm < 6.5) {
    br = 0.6 + 0.1 * (sm - 3.);
  } else {
    br = .9 + 0.05 * (sm - 6.);
  }
  return hsv2rgb(vec3(hu, sa, br));
}

// https://www.shadertoy.com/view/MslGWN
vec3 nrand3(vec2 co)
{
  float a = hash(co, 98u);
  float b = hash(co, 99u);
  float c = mix(a, b, 0.5);
  return vec3(c);
}

// https://www.shadertoy.com/view/MslGWN
vec4 stars(vec2 uv)
{
  vec3 rnd = nrand3(uv);
  float r = rnd.y;
  vec4 starcolor = vec4(r * r * r * r * r);

  if (starcolor.x > 0.3)
  {
    float brighness_variance = max(0.15, hash(uv, 94u) / 2.0f);
    return starcolor + vec4(abs(sin((iTime*10. + hash(uv, 94u)) *
      (hash(uv, 95u) + 1.))) * brighness_variance
      - (brighness_variance / 2.));
  } else {
    return vec4(0.);
  }
}

void mainImage(out vec4 O, vec2 u)
{
  seed = uint(round(abs(texelFetch(iChannel0, ivec2(u), 0).x)));
  col_seed = uint(round(abs(texelFetch(iChannel0, ivec2(u), 0).y)));
  pix = round(texelFetch(iChannel0, ivec2(u), 0).z);

  vec2 bU = u / R.y;
  vec2 U = floor(bU * pix) / pix;

  if (distance(U, R / (2. * R.y)) > 0.425)
  {
    U *= R.y;
    float sta = stars(U).x*noise(U * 0.1, 182u);
    O = vec4(2. * sta * noise(U * 0.025, 47u),
      sta * 1.5 * noise(U * 0.025, 52u),
      sta * 3., 1.);
    return;
  }
  bool dith = mod(bU.x + U.y, 2. / pix) < 1. / pix;

  U = spherify(U, R / (2. * R.y), 0.425);
  vec2 aU = fbmSwirls(U, O, seed + 151u);
  float g = fbmCircles(aU * 10. + vec2(iTime * 0.2, 0.), seed + 151u);
  g = -smin(1., g, 3.2);

  float sm = sqrt(sqrt(max(g, 0.025))) * 12.;

  // light and dithering
  float d_light = distance(U, iMouse.xy / R);
  float light_b =
    max(0.8 - d_light + (noise(U * 15., seed + 15u) - 0.5) * 0.2, 0.05);
  light_b = sqrt(light_b);
  sm = dith ? 0.95 * sm * light_b : sm * light_b;

  sm = sm - mod(sm, sqrt(sqrt(light_b))) + 1.;

  O = vec4(planet_color(sm), 1.);
}
