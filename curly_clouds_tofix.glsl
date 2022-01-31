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

float voronoi( in vec2 x, float w, uint seed )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

  float m = 8.;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec2 o = vec2(hash( n + g , seed), hash( n + g , seed+10u));

    // animate
        o = 0.5 + 0.5*sin(6.2831*o );

        // distance to cell
    float d = length(g - f + o);

    float h = smoothstep( 0.0, 1.0, 0.5 + 0.5*(m-d)/w );
      m   = mix( m, d, h ) - h*(1.0-h)*w/(1.0+3.0*w); // distance
    }

  return m;
}

float fbm(vec2 coord, float w, uint noise_seed)
{
  float value = 0.0;
  float scale = 1.;
  uint octaves = 3u;

  for (uint i = 0u; i < octaves; i++)
  {
    value += voronoi(coord, w, noise_seed) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float clouds(vec2 p)
{
    float v = fbm( 6.0*p, 0.3, 0u );

    // gamma
    float t = sqrt(sqrt(sqrt(sqrt(sqrt(v)))));

  t *= 1.0 - 0.8*v*v*v;
    return t;
}


#define H(p)       fract(sin((p)*mat2(246.1, 113.5, 271.9, 124.6 ))*43758.5453123)
#define R(p,a)   (p)*mat2( cos(a),-sin(a),sin(a),cos(a) )
#define hue(v)   ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )

void mainImage( out vec4 O, vec2 u )
{
    vec2 R = iResolution.xy,
         U = u / R.y;

    O-=O;
    float r = length(U), y,w=0., l=9., s =8+H(U)*8.;      // s: swirls size
    int i,k;

    vec2 P = s*U, I,F, H,D;
         F = abs(fract(P+.5)-.5); y = min(F.x,F.y); O += smoothstep(12./R.y,0.,y);
         I = floor(P), F = fract(P);           // coords in 2D grid
    y = U.x;                                  // latitude ( to tune swirl direction & amplitude )
    y = 4.*cos(4.*y);
    P-=P;
#define dist2seed  \
        D = vec2( k%3, k/3 ) -1.;              /* cell offset         */    \
        D += H(I+D)-.5;                        /* random seed point   */    \
        r = length(F-D);                       /* distance to seed    */

    for ( k = 0; k < 9; k++) {                 // visit neighbor cells to find closest seed point
        dist2seed;
        F  =   R( F-D, y*smoothstep(0.5,0.,r) ) + D; P = F+I;
      //P  =   R( F-D, y*smoothstep(.5,0.,r) ) + D+I;  I = floor(P),F = fract(P);
        r < l ? l = r, i = k : i;              // keep closest dot
     }

    U = P/s;                                    // surface coordinates
    //O += (.5+.5*hue(abs(U.y*2./3.14)))*0.9;
    U = floor(U*100.) / 100.;
    O = vec4(vec3(clouds(U.yx)), 1.);

}
