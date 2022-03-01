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
  return r * r;
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

    // movement
    a = vec2(hash(i + p, s + 25u), hash(i + p, s + 215u));
    a = 0.3 * cos(5. * (a.x - 0.5) * iTime * 0.5 + 6.3 * a.y + vec2(0., 11.));
    p += 0.1 + 0.8 * h - f + a;

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

vec2 fbmSwirls(vec2 p, out vec4 O, uint se)
{
  uint o = 3u;
  O -= O;
  p += vec2(iTime * 0.02, 0.);
  float sz = 2., ro = 0.5;
  for(uint i = 0u; i < o; i++)
  {
    p = swirls(p, se + i, sz, ro);
    sz *= 1.;
  }
  return p;
}

void mainImage(out vec4 O, vec2 u)
{
  float pix = 500.;
  float cols = 18.;
  uint seed = 1u;
  vec2 bU = u / iResolution.y;
  vec2 U = floor(bU * pix) / pix;
  bool dith = mod(bU.x + U.y, 2. / pix) < 1. / pix;
  vec2 aU = fbmSwirls(U, O, seed);
  float g = min(fbmCircles(aU * 10. + vec2(iTime * 0.2, 0.), seed + 10u),
    fbmCircles(aU * 10. + vec2(iTime * 0.2, 0.), seed + 20u));
  g = -smin(1., g, 3.3) * fbmVoronoi(0.25*U, seed);
  g = floor(g * cols) / cols;
  O = vec4(vec3(1.5 * g), 1.);
}
