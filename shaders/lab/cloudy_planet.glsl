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

float circles( vec2 i, vec2 f, vec2 p, float r)
{
   float rad = hash(i+p, 2u) * r;
   vec2 h = vec2(hash(i+p, 89u), hash(i+p, 52u));
   vec2 a = vec2(hash(i+p, 25u), hash(i+p+.5, 215u));
   a = .3*cos(5.*(a.x-.5)*iTime*0.2 +6.3*a.y +vec2(0,11));
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

float sdBase( vec2 p, float r)
{
   vec2 i = vec2(floor(p));
   vec2 f =      fract(p);

   float d = 1e9;
   for( int k=0; k<9; k++) {   
      p = vec2(k%3,k/3)-1.;
      d = smin(d, circles(i, f, p, r), 0.3);
   }
   return d;
}

float sdFbm( vec2 p, float d )
{
   float s = 1.;
   int o = 2;
   for( int i=0; i<o; i++ )
   {
       // evaluate new octave
       float n = s*(sdBase(p, .5));
	
       // add
       d = smin(d, n, 0.3*s);
	
       p *= 2.;
       s = 0.5*s;
   }
   return d;
}

float swirl( vec2 p)
{
   float n = sdFbm(p + vec2(iTime *0.2, 0.), 1.);
	
   float d = smin(1., n, 3.2);

   return d;
}

#define H(p)       fract(sin((p)*mat2(246.1, 113.5, 271.9, 124.6 ))*43758.5453123)
#define R(p,a)   (p)*mat2( cos(a),-sin(a),sin(a),cos(a) )

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
	return c.z * mix( vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 O, vec2 u )
{
     float sc = 1.; float pix = 100.;
    vec2 R = iResolution.xy,
         U = sc*u / R.y;

        U = floor(U*pix) / pix;
            bool dith = mod(U.x + U.y, 2.0 / pix) <= .5 / pix;
            vec2 mo = iMouse.xy / R;
            float lratio = 1. / sqrt(1.);
            
            U = spherify(U, sc * R / (2. * R.y), 0.425);

    O-=O;
    float r = length(U), y, s =8.*sc;      // s: swirls size
    int k;

    vec2 P = s*U, I,F, H,D,A;
         F = abs(fract(P+.5)-.5); y = min(F.x,F.y); O += smoothstep(12./R.y,0.,y);
         I = floor(P), F = fract(P);           // coords in 2D grid
    float d = 4.;
    y = d*cos(d*y);
    P-=P;
#define dist2seed  \
        D = vec2( k%3, k/3 ) -1.;              /* cell offset         */    \
        D += H(I+D);                        /* random seed point   */    \
        r = length(F-D);                       /* distance to seed    */

    for ( k = 0; k < 9; k++) {                 // visit neighbor cells to find closest seed point
        dist2seed;
        F  =   R( F-D, y*smoothstep(.5,0.,r) ) + D; P = F+I;
     }
    U = P/s;                                    // surface coordinates
    float g = -swirl(U*10.*sc);
    //O = vec4(vec3(1.-g), 1.);return;
    //float sm = floor( noise(U*(1./sc), 15u)*sqrt(sqrt(max(g, 0.05))) * 16.)/16. *1.5;
    //O = vec4(vec3(sm), 1.);return;
    
  
    float sm = sqrt(sqrt(max(g, 0.025))) * 12.;
    
    float d_light = distance(U, vec2(mo)) * lratio;
    float light_b = sqrt(0.8 - (d_light + (noise(U*15., 15u) - 0.5) * 0.2));
    sm = max(dith ? 0.95 * sm * light_b : sm * light_b, dith ? 0.75*(sm-8.5) : sm-8.5);

    sm = floor(sm)+1.;
    float hu = radians(3.1415926*2.*(5.5+sm*0.5)), sa, br;
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
