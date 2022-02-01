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

float sph( ivec2 i, vec2 f, ivec2 c)
{
   // random radius at grid vertex i+c
   float rad = hash(vec2(i+c), 2u);
   // distance to sphere at grid vertex i+c
   rad = (rad < 0.2 ? -0.5 : rad/4.);
   f += vec2(hash(vec2(i+c), 89u), hash(vec2(i+c), 52u))*0.7 - 0.35;
   return length(f-vec2(c)) - rad; 
}

float sdBase( vec2 p)
{
   ivec2 i = ivec2(floor(p));
    vec2 f =       fract(p);
   // distance to the 8 corners spheres
   return min(min(sph(i,f,ivec2(0,0)),
                  sph(i,f,ivec2(0,1))),
              min(sph(i,f,ivec2(1,0)),
                  sph(i,f,ivec2(1,1))));
}

float lightning( vec2 p)
{
   float n = sdBase(p);
	
   float d = smin(1., n, 2.7);

   return d > 0. ? 1.:0.;
}


#define H(p)       fract(sin((p)*mat2(246.1, 113.5, 271.9, 124.6 ))*43758.5453123)
#define R(p,a)   (p)*mat2( cos(a),-sin(a),sin(a),cos(a) )
#define hue(v)   ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )

void mainImage( out vec4 O, vec2 u )
{
    vec2 R = iResolution.xy,
         U = (.5*u + iTime * 15.) / R.y;
        U = floor(U*150.) / 150.;

    O-=O;
    float r = length(U), y,l=9., s =8.;      // s: swirls size
    int i,k;

    vec2 P = s*U, I,F, H,D;
         F = abs(fract(P+.5)-.5); y = min(F.x,F.y); O += smoothstep(12./R.y,0.,y);
         I = floor(P), F = fract(P);           // coords in 2D grid
    y = U.y * U.y;                                  // latitude ( to tune swirl direction & amplitude )
    float d = 3.;
    y = d*cos(d*y);
    P-=P;
#define dist2seed  \
        D = vec2( k%3, k/3 ) -1.;              /* cell offset         */    \
        D += H(I+D)-.5;                        /* random seed point   */    \
        r = length(F-D);                       /* distance to seed    */

    for ( k = 0; k < 9; k++) {                 // visit neighbor cells to find closest seed point
        dist2seed;
        F  =   R( F-D, y*smoothstep(0.5,0.,r) ) + D; P = F+I;
        r < l ? l = r, i = k : i;              // keep closest dot
     }

    U = P/s;                                    // surface coordinates
    float g = lightning(U*20.);

    O = vec4(vec3(g), 1.);

}
