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

float sdFbm( vec2 p, float d )
{
   float s = 1.;
   int o = 2;
   for( int i=0; i<o; i++ )
   {
       // evaluate new octave
       float n = s*(sdBase(p));
	
       // add
       d = smin(d, n, 0.3*s);
	
       p *= 2.;
       s = 0.5*s;
   }
   return d;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = 10.*fragCoord/iResolution.y;
        // uv = floor(uv*10.) / 10.;

    // Time varying pixel color
    
    vec3 col = vec3(smoothstep( 0.001,0., sdFbm(uv, 1.)));
    //vec3 col = vec3(smoothstep( 15./iResolution.y,0., sdBase(uv)));

    // Output to screen
    fragColor = vec4(col,1.0);
}
