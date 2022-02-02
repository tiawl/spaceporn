
#define H(p)       fract(sin((p)*mat2(246.1, 113.5, 271.9, 124.6 ))*43758.5453123)
#define R(p,a)   (p)*mat2( cos(a),-sin(a),sin(a),cos(a) )
#define hue(v)   ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )

float lines(in vec2 pos, float b){
    float scale = 10.0;
    pos *= scale;
    return smoothstep(0.0,
                    .5+b*.5,
                    abs((sin(pos.x*3.1415)+b*2.0))*.5);
}

void mainImage( out vec4 O, vec2 u )
{
    vec2 R = iResolution.xy,
         U = ( 2.*u - R ) / R.y;

    O-=O;
    float r = length(U), y,w=0., l=9., s = 4.;      // s: swirls size
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
    O = vec4(lines(P.yx, 0.5));
    
}
