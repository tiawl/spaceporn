// iChannel0 = BufferA

uint seed;
uint col_seed;

uvec3 pcg3d(uvec3 v)
{
  v = v * 1664525u + 1013904223u;

  v.x += v.y*v.z;
  v.y += v.z*v.x;
  v.z += v.x*v.y;

  v ^= v >> 16u;

  v.x += v.y*v.z;
  v.y += v.z*v.x;
  v.z += v.x*v.y;

  return v;
}

float hash(vec2 s, uint hash_seed)
{
  float res;

    uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
    uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
    res = float(p) * (1.0 / float(0xffffffffu));

  return res;
}

float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

vec2 spherify(vec2 uv, vec2 center, float radius)
{
  vec2 centered = (uv - center) * 2.;
  float z = sqrt(radius * radius * 4. - dot(centered.xy, centered.xy));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

float circles( vec2 i, vec2 f, vec2 p, float r, uint s)
{
   float rad = hash(i+p, s + 2u) * r;
   vec2 h = vec2(hash(i+p, s + 89u), hash(i+p, s + 52u));
   vec2 a = vec2(hash(i+p, s + 25u), hash(i+p+.5, s + 215u));
   a = .3*cos(5.*(a.x-.5)*iTime*0.5 +6.3*a.y +vec2(0,11));
   p += .1+.8*h -f + a;
   return length(p) - rad; 
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

float sdBase( vec2 p, float r, uint s)
{
   vec2 i = vec2(floor(p));
   vec2 f =      fract(p);

   float d = 1e9;
   for( int k=0; k<9; k++) {   
      p = vec2(k%3,k/3)-1.;
      d = smin(d, circles(i, f, p, r, s), 0.3);
   }
   return d;
}

float sdFbm( vec2 p, float d, uint se)
{
   float s = 1.;
   int o = 2;
   for( int i=0; i<o; i++ )
   {
       // evaluate new octave
       float n = s*(sdBase(p, .5, se));
	
       // add
       d = smin(d, n, 0.3*s);
	
       p *= 2.;
       s = 0.5*s;
   }
   return d;
}

float swirl( vec2 p, uint s)
{
   float n = sdFbm(p + vec2(iTime *0.2, 0.), 1., s);
	
   float d = smin(1., n, 3.2);

   return d;
}

#define R(p,a)   (p)*mat2( cos(a),-sin(a),sin(a),cos(a) )

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
	return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 nrand3(vec2 co)
{
  float a = hash(co, 98u);
  float b = hash(co, 99u);
  float c = mix(a, b, 0.5);
  return vec3(c);
}

vec4 stars(vec2 uv)
{
  vec3 rnd = nrand3(uv);
  float r = rnd.y;
  vec4 starcolor = vec4(r*r*r*r*r);

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

void mainImage( out vec4 O, vec2 u )
{
    seed = uint(round(max(0., texelFetch( iChannel0, ivec2(u), 0 ).x)));
    col_seed = uint(round(max(0., texelFetch( iChannel0, ivec2(u), 0 ).z)));

    float pix = 100.;
    vec2 R = iResolution.xy,
         U = u / R.y;

    U = floor(U*pix) / pix;
    if (distance(U, R / (2. * R.y)) > 0.425)
    {
        vec2 coord = pix *u/R.y;
        float sta = stars(coord).x*noise(coord * 0.1, 182u);
        O = vec4(2. * sta * noise(coord * 0.025, 47u),
            sta * 1.5 * noise(coord * 0.025, 52u),
            sta*3., 1.); return;
    }
    bool dith = mod(U.x + U.y, 2.0 / pix) <= .5 / pix;
    vec2 mo = iMouse.xy / R;
    float lratio = 1.;
            
    U = spherify(U, R / (2. * R.y), 0.425);

    O-=O;
    U += vec2(iTime *0.02, 0.);
    float r = length(U), y, s =.02;      // s: swirls size
    int k;

    vec2 P = U * s * R.y, I,F, H,D,A;
         F = abs(fract(P+.5)-.5); y = min(F.x,F.y); O += smoothstep(12./R.y,0.,y);
         I = floor(P), F = fract(P); 
    float d = 4.;
    y = d*cos(d*y);
    P-=P;
    for ( k = 0; k < 9; k++)
    {
        D = vec2( k%3, k/3 ) -1.;
        D += hash(I+D, seed+222u);
        r = length(F-D); 
        F  =   R( F-D, y*smoothstep(.5,0.,r) ) + D; P = F+I;
     }
    U = P/(s * R.y);
    float g = -swirl(U*10., seed + 151u);
    U -= vec2(iTime *0.02, 0.);
  
    float sm = sqrt(sqrt(max(g, 0.025))) * 12.;
    
    float d_light = distance(U, vec2(mo)) * lratio;
    float light_b = 0.8 - (d_light + (noise(U*15., seed + 15u) - 0.5) * 0.2);
    bool roc = light_b < 0.;
    light_b = roc ? max(0.8 - abs(light_b), 0.) : sqrt(light_b);
    sm = dith ? sqrt(sqrt(sqrt(light_b))) * sm * light_b : sm * light_b;
    
    sm = roc ? max(0., sm - mod(sm, 0.5) - 5.5): sm - mod(sm, sqrt(sqrt(light_b)))+1.;
    float hu, sa, br;
    if (col_seed < 1u)
    {
        hu = radians(3.1415926*2.*(5.5+sm*0.5));
    } else {
        hu = radians(3.1415926*2.*(9.*hash(vec2(1.), col_seed)
          + sm * (hash(vec2(10.), col_seed+5u) * 3. - 1.5)));
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
        br = 0.9 + 0.05 * (sm - 6.);
    }
    O = vec4(hsv2rgb(vec3(hu, sa, br)), 1.);
}
