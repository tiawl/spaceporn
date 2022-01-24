# include "hash.glsl"
# include "pixelspace.glsl"

vec4 polar(vec2 uv, Star star)
{
  star.brightness = 1. / star.brightness;
  vec2 A = star.center + vec2(-star.size, 0.);
  vec2 B = star.center + vec2( star.size, 0.);
  vec2 C = star.center + vec2( 0.,  star.size / (star.diag * 2. / 3.));
  vec2 D = star.center + vec2( 0., -star.size / (star.diag * 2. / 3.));
  vec2 E = star.center + vec2(-star.size / star.diag,  star.size / star.diag);
  vec2 F = star.center + vec2( star.size / star.diag, -star.size / star.diag);
  vec2 G = star.center + vec2( star.size / star.diag,  star.size / star.diag);
  vec2 H = star.center + vec2(-star.size / star.diag, -star.size / star.diag);

  float depth = 1. / shorter_res;
  float s1 = sdSegment(uv, A, B) - depth;
  float s2 = sdSegment(uv, C, D) - depth;
  float s3 = sdSegment(uv, E, F) - depth;
  float s4 = sdSegment(uv, G, H) - depth;
  float m = min(min(smin(s1 - depth * 10., s3, star.shape, star.sharpness),
    smin(s2, s3, star.shape, star.sharpness)),
      min(smin(s1 - depth * 10., s4, star.shape, star.sharpness),
        smin(s2, s4, star.shape, star.sharpness)));

  float color = (sign(m) < .5 ? 1. : 0.);
  vec2 mirror_uv =
    vec2(abs(uv.x - star.center.x), 2. * abs(uv.y - star.center.y));

  float ratio = 2. / (20. + star.brightness * star.brightness);
  color *= 1.0 - ((hash(uv, seed) * ratio - ratio / 2.)
    + (mirror_uv.x + mirror_uv.y) * (star.brightness / sqrt(star.size)));

  float ring = opRing(uv - star.center, star.size * 0.8,
    shorter_res / (2. * pixels));
  ring = (sign(ring) < .5 ? 1. : 0.);
  color = max(color * 1.3, ring * 0.6);

  return vec4(vec3(floor(color * PLANET_COLS) / PLANET_COLS), 1.);
}
