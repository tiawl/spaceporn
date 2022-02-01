float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}


float sph( ivec2 i, vec2 f, ivec2 c)
{
   // random radius at grid vertex i+c
   float rad = 0.5*rand(vec2(i+c));
   // distance to sphere at grid vertex i+c
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

float sdFbm( vec2 p, float d )
{
   float s = 1.0;
   int o = 2;
   for( int i=0; i<o; i++ )
   {
       // evaluate new octave
       float n = s*(sdBase(p));
	
       // add
       //n = smax(n,d,0.3*s);
       d = smin(d, n, 0.3*s);
	
       // prepare next octave
       p = mat2( -1., 1.,
                -1., -1. )*p;
       //s = 0.1*s;
   }
   return d > 0. ? 1.:0.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 10.*fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = vec3(sdFbm(uv, 1.));

    // Output to screen
    fragColor = vec4(col,1.0);
}
