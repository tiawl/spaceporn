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


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 p = fragCoord/iResolution.y;

    fragColor = vec4(vec3(clouds(p)),1.0);
}
