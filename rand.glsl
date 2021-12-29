float rd(vec2 coord)
{
  return fract(43757.5453 * sin(dot(coord, vec2(12.9898, 78.233))));
}

uint pcg(uint v)
{
  uint state = v * 747796405u + 2891336453u;
  uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
  return (word >> 22u) ^ word;
}

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

vec3 hash(vec2 s)
{
  uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
  //uvec3 p = uvec3(pcg(pcg(u.x) + u.y));
  //uvec3 p = pcg3d(u.xyz);
  uvec3 p = pcg3d(uvec3(u.xy, 0.));
  return vec3(float(p) * (1.0/float(0xffffffffu)));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  // Normalized pixel coordinates (from 0 to 1)
  vec2 uv = fragCoord/iResolution.xy;

  // Time varying pixel color
  //vec3 col = vec3(rd(uv*10000.));
  vec3 col = hash(fragCoord);

  // Output to screen
  fragColor = vec4(col,1.0);
}
