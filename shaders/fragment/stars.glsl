# include "pixelspace.glsl"

vec3 nrand3(vec2 co)
{
  vec3 a = fract(cos(co.x * 8.3e-3 + co.y) * vec3(1.3e5, 4.7e5, 2.9e5));
  vec3 b = fract(sin(co.x * 0.3e-3 + co.y) * vec3(8.1e5, 1.0e5, 0.1e5));
  vec3 c = mix(a, b, 0.5);
  return c;
}

vec4 stars(vec2 uv)
{
  const float stars_density = 20.;

  vec2 stars_seed = uv.xy * 2.0;
  stars_seed = floor(stars_seed * resolution.x);
  vec3 rnd = nrand3(stars_seed);
  vec4 starcolor = vec4(pow(rnd.y, stars_density));

  if (starcolor.x > 0.3)
  {
    float brighness_variance = max(0.15, psrand(uv) / 2.0f);
    return starcolor + (vec4(psrand((1. + fract(time)) * uv)
      * brighness_variance) - (brighness_variance / 2.));
  } else {
    return vec4(0.);
  }
}
