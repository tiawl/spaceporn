# include "pixelspace.glsl"

vec3 nrand3(vec2 co)
{
  float a = hash(co, seed + 1u);
  float b = hash(co, seed + 2u);
  float c = mix(a, b, 0.5);
  return vec3(c);
}

vec4 stars(vec2 uv)
{
  vec2 stars_seed = uv * 2.0;
  stars_seed = floor(stars_seed);
  vec3 rnd = nrand3(stars_seed);
  vec4 starcolor = vec4(pow(rnd.y, stars_density));

  if (starcolor.x > 0.3)
  {
    float brighness_variance = max(0.15, hash(uv, seed) / 2.0f);
    return starcolor + vec4(hash(uv, seed + uint(floor(MAX_RATE * time)))
      * brighness_variance - (brighness_variance / 2.));
  } else {
    return vec4(0.);
  }
}
