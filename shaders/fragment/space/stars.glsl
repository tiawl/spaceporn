# include "hash.glsl"
# include "space/common.glsl"

vec3 nrand3(vec2 coords)
{
  float a = hash(coords, seed + 1u);
  float b = hash(coords, seed + 2u);
  float c = mix(a, b, 0.5);
  return vec3(c);
}

vec4 stars(vec2 coords)
{
  vec3 rnd = nrand3(coords);
  vec4 starcolor = vec4(pow(rnd.y, STARS_DENSITY));

  if (starcolor.x > 0.3)
  {
    float brighness_variance = max(0.15, hash(coords, seed) / 2.);
    return starcolor + vec4(abs(sin((time + hash(coords, seed)) *
      (hash(coords, seed + 1u) + 1.) * MAX_RATE)) * brighness_variance
      - (brighness_variance / 2.));
  } else {
    return vec4(0.);
  }
}
