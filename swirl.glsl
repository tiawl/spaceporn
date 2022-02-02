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

float sph( vec2 i, vec2 f, vec2 p)
{
   float rad = hash(i+p, 2u) *0.5;
   vec2 h = vec2(hash(i+p, 89u), hash(i+p, 52u));
   p += h - f;
   return length(p) - rad; 
}

float sdBase( vec2 p)
{
   vec2 i = vec2(floor(p));
   vec2 f =      fract(p);

   float d = 1e9;
   for( int k=0; k<9; k++) {   
      p = vec2(k%3,k/3)-1.;
      d = smin(d,sph(i, f, p), 0.3);
   }
   return d;
}

float swirl( vec2 p)
{
   float n = sdBase(p);
	
   float d = smin(1., n, 2.2);

   return sqrt(sqrt(sqrt(sqrt(d))));
}


#define H(p)       fract(sin((p)*mat2(246.1, 113.5, 271.9, 124.6 ))*43758.5453123)
#define R(p,a)   (p)*mat2( cos(a),-sin(a),sin(a),cos(a) )
#define hue(v)   ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )

void mainImage( out vec4 O, vec2 u )
{
    vec2 R = iResolution.xy,
         U = (1.*u) / R.y;
        //U = floor(U*100.) / 100.;

    O-=O;
    float r = length(U), y,l=9., s =8.;      // s: swirls size
    int i,k;

    vec2 P = s*U, I,F, H,D;
         F = abs(fract(P+.5)-.5); y = min(F.x,F.y); O += smoothstep(12./R.y,0.,y);
         I = floor(P), F = fract(P);           // coords in 2D grid
    float d = 4.;
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
    float g = swirl(U*20.);

    O = vec4(vec3(g), 1.);

}
