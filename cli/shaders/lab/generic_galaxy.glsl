#define COLS 18.
#define COL_SEED 1u

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

vec3 hsv2rgb(vec3 c)
{
  vec3 rgb = clamp(abs(mod(c.x * 6.
    + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  return c.z * mix(vec3(1.), rgb, c.y);
}

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
    sa += 0.6 + 0.1 * (sm - 2.);
  } else {
    sa += 0.8 - 0.15 * (sm - 4.);
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

float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

vec2 rotation(vec2 p, float a)
{
  return p * mat2(cos(a), -sin(a),
                  sin(a),  cos(a));
}

void mainImage( out vec4 O, in vec2 u )
{
    float pix = 12.;
    vec2 U = 2.5*(u - iResolution.xy * 0.5)/iResolution.y;
    U = floor(U * pix) / pix;
    U *= vec2(0.6, 1.2);
    vec2 bU = U;
    U = rotation(U, 3.5 * (1. - smoothstep(0., 1.2, length(U))));
    float s1 = 0.4/*.5*/, s2 = 0.8/*1.*/;
    float l = length(U);
    float d = max(0., 1.2 - l);//max(0., 1.8 - (1. + sin(l*l*25.)) * 0.4)*max(0., 1.-l);

    //segment
    float c = max(1. - smoothstep(0., d, sdSegment(U, vec2(s1*2., 0.), vec2(-s1, 0.))),
      1. - smoothstep(0., d, sdSegment(U, vec2(0., s2), vec2(0., -s2))));
    c = max(c, 1. - smoothstep(0., d, sdSegment(U, vec2(-s1*2., s1), vec2(-s1, 0.))));
    c = max(c, 1. - smoothstep(0., d, sdSegment(U, vec2(-s1*2., -s1), vec2(-s1, 0.))));
    
    //light
    c *= (2. - l) * (l + 0.15);
    c += max(0., 0.3 - abs(U.x) - abs(0.6*bU.y)) * 3.;
    
    //color
    c = floor(c * COLS * 0.8) / COLS;
    O = vec4(color(10. * c, COL_SEED), 1.);
}
