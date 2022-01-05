# include "pixelplanets.glsl"

vec4 dry(vec2 uv, Planet planet, bool dith) {
  const float size = 8.0;
  const uint octaves = 3u;
  const vec2 sizeModifier = vec2(2., 1.);

  const vec3 color1 = vec3(1.000, 0.537, 0.200);
  const vec3 color2 = vec3(0.898, 0.266, 0.219);
  const vec3 color3 = vec3(0.674, 0.184, 0.266);
  const vec3 color4 = vec3(0.317, 0.196, 0.243);
  const vec3 color5 = vec3(0.239, 0.156, 0.211);

  float lratio = 1. / sqrt(planet.radius);
  float d_light = distance(uv, planet.light_origin) * lratio;

  uv = spherify(uv, planet.center, planet.radius);
  uv = rotate(uv, planet.center, planet.rotation);

  float f = ppfbm(size, sizeModifier,
    uv * size + vec2(time * planet.time_speed, 0.0), octaves, seed,
    planet.center);

  d_light = smoothstep(-0.3, 1.2, d_light);

  if (d_light < 0.362)
  {
    d_light *= 0.9;
  }
  if (d_light < 0.525)
  {
    d_light *= 0.9;
  }

  float c = d_light * pow(f, 0.8) * 3.5;

  if (dith)
  {
    c += 0.02;
    c *= 1.05;
  }

  float posterize = floor(c * 4.0) / 4.0;
  vec3 col = color5;

  if (posterize < 0.25)
  {
    col = color1;
  } else if (posterize < 0.40) {
    col = color2;
  } else if (posterize < 0.65) {
    col = color3;
  } else if (posterize < 0.80) {
    col = color4;
  }

  return vec4(col, 1.);
}
