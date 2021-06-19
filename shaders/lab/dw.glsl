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

float fbm(vec2 coord, uint octaves, uint noise_seed)
{
  float value = 0.0;
  float scale = 0.5;

  for (uint i = 0u; i < octaves; i++)
  {
    value += noise(coord, noise_seed) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float pattern( in vec2 p, out vec2 q, out vec2 r)
{
    uint o = 8u;
    uint s = 0u;
    q.x = fbm( p + vec2(0.0,0.0), o, s );
    q.y = fbm( p + vec2(5.2,1.3), o, s + 10u );

    r.x = fbm( p + 4.0*q + vec2(1.7,9.2), o, s + 20u );
    r.y = fbm( p + 4.0*q + vec2(8.3,2.8), o, s + 30u );

    return fbm( p + 4.0*r, o, s + 40u);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
     vec2 q, r;
    vec2 p =  0.01*fragCoord;
    float pat = pattern(p, q, r);
    
    vec3 col = vec3(0.2,0.1,0.4);
        col = mix( col, vec3(0.3,0.05,0.05), pat );
        col = mix( col, vec3(0.9,0.9,0.9), dot(r,r) );
        col = mix( col, vec3(0.5,0.2,0.2), 0.5*q.y*q.y );
        col = mix( col, vec3(0.0,0.2,0.4), 0.5*smoothstep(1.2,1.3,abs(r.y)+abs(r.x)) );
        col *= pat*2.0;

    // Output to screen
    fragColor = vec4(col,1.0);
}
