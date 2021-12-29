# include "pixelspace.glsl"

float calc_square(vec2 xy, vec2 offset)
{
  vec2 ixy = floor(xy) - offset;
  vec2 center = ixy + 0.5;

  center += 0.25 + 0.5 * hash(ixy, 0u);

  float angle = radians(hash(ixy, 1u) * 360.);
  center.x += 0.25 * sin(angle);
  center.y += 0.25 * cos(angle);

  vec2 uv_unit = (vec2(1.) / resolution) * bigstars_density;
  uv_unit.x *= resolution.x / resolution.y;

  float rd_bigstar = ceil(hash(ixy, 2u) * 6.);
  if (rd_bigstar < 1.)
  {
    rd_bigstar = 1.;
  }

  float size = (max(resolution.x, resolution.y) / pixels) *
    (0.5 + hash(ixy, 3u) * 0.4);

  vec2 dist_text_center = ceil(12.0 * size + 0.1) * uv_unit;
  float m = 2. * ((rd_bigstar - 1.) / rd_bigstar) - 1.;

  vec2 dist_center = vec2(xy.x - center.x, xy.y - center.y);

  if ((abs(dist_center.x) < dist_text_center.x) &&
    (abs(dist_center.y) < dist_text_center.y))
  {
    dist_center += floor(12.5 * size + 0.1) * uv_unit;
    dist_center.x += (25. * uv_unit.x * size) * (rd_bigstar - 1.);
    vec4 text = texture2D(big_stars_texture,
      dist_center / (size * uv_unit * TEXTURE_SIZE));
    if (text.a > 0.)
    {
      float rd_brightness = ceil(hash(ixy, 2u) * 2.);
      return text.x * (0.25 * rd_brightness *
        hash(ixy, uint(floor(MAX_RATE * 3. * time))) + 1.);
    } else {
      return 0.;
    }
  } else {
    return 0.;
  }
}

vec4 bigstars(vec2 uv)
{
  uv *= bigstars_density;
  float col_value = max(max(max(calc_square(uv, vec2(0.0, 0.0)),
    calc_square(uv, vec2(0.0, 1.0))), calc_square(uv, vec2(1.0, 0.0))),
    calc_square(uv, vec2(1.0, 1.0)));
  return vec4(floor(col_value * NB_COL) / NB_COL);
}
