# include "hash.glsl"
# include "pixelspace.glsl"

vec4 diamond(vec2 uv, Star star)
{
  star.brightness = 1. / star.brightness;
  vec2 A = star.center + vec2(-star.size,  0.);
  vec2 B = star.center + vec2( star.size,  0.);
  vec2 C = star.center + vec2( 0.,         star.size);
  vec2 D = star.center + vec2( 0.,        -star.size);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(uv, A, B) - depth;
  float s2 = sdSegment(uv, C, D) - depth;
  float m = smin(s1, s2, star.shape, star.sharpness);

  float color = (sign(m) < .5 ? 1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  vec2 mirror_uv = vec2(abs(uv.x - star.center.x), abs(uv.y - star.center.y));
  color *= 1.0 - ((hash(uv, seed) * ratio - ratio / 2.)
    + (mirror_uv.x + mirror_uv.y) * (star.brightness / sqrt(star.size)));

  float ring = opRing(uv - star.center, star.size * star.ring_size,
    shorter_res / (2. * pixels));
  ring = (sign(ring) < .5 ? 1. : 0.);
  color = max(color * 1.3, ring * 0.3);

  return vec4(vec3(floor(color * PLANET_COLS) / PLANET_COLS), 1.);
}
