# include "hash.glsl"
# include "pixelspace.glsl"

vec4 diamond(vec2 uv, Star star)
{
  star.brightness = 1. / star.brightness;

  float depth = 1. / shorter_res;
  float s1 = sdBox(uv - star.center, vec2(star.size, depth));
  float s2 = sdBox(uv - star.center, vec2(depth, star.size));
  float m = smin(s1, s2, star.shape, star.sharpness);

  float color = (sign(m) < .5 ? 1. : 0.);
  float ratio = 2. / (20. + star.brightness * star.brightness);
  vec2 mirror_uv = vec2(abs(uv.x - star.center.x), abs(uv.y - star.center.y));
  color *= 1.0 - ((hash(uv, seed) * ratio - ratio / 2.)
    + (mirror_uv.x + mirror_uv.y) * (star.brightness / sqrt(star.size)));

  float ring = opRing(uv - star.center, star.size * 0.8, 500. / pixels);
  ring = (sign(ring) < .5 ? 1. : 0.);
  color = max(color * 1.3, ring * 0.6);

  return vec4(vec3(floor(color * PLANET_COLS) / PLANET_COLS), 1.);
}
