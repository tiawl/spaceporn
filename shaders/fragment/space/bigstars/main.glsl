# include "hash.glsl"
# include "space/bigstars/diamond.glsl"
# include "space/bigstars/nova.glsl"
# include "space/bigstars/polar.glsl"

# define MAX_BIGSTAR_SZ 16.

# define DIAMOND 0u
# define NOVA    1u
# define POLAR   2u
# define STAR_TYPES 3.

float calc_star(vec2 coords, vec2 center, float pixel_res)
{
  float type = hash(center, seed + 2u);
  uint rd_bigstar = (type < 0.15 ? NOVA : (type < 0.3 ? POLAR : DIAMOND));
  float size_hash = hash(center, seed + 3u) * 0.5 + 0.5;
  size_hash *= size_hash;
  size_hash *= size_hash;
  size_hash *= size_hash;
  size_hash *= size_hash;
  float min_size = (rd_bigstar == DIAMOND ? 3. : 7.);
  float max_size = MAX_BIGSTAR_SZ - min_size;
  float size =
    (min(floor(size_hash * (max_size + 1.)), max_size) + min_size) * pixel_res;
  float brightness = hash(center, seed + 4u) + 1.;
  float ring_size = hash(center, seed + 5u) * 0.8;
  ring_size = (ring_size * size < pixel_res * 4. ? 0. : ring_size);
  float power =
    round(sin(time * (100. + 40. * hash(center, seed + 6u)))) * 0.2 + 1.;

  float star = 0.;
  Star bigstar =
    Star(rd_bigstar, center, size, power, 1., 0u, 1., ring_size);
  if (bigstar.type == DIAMOND)
  {
    bool rotation = hash(bigstar.center, seed + 7u) > 0.5;
    bigstar.brightness *= bigstar.size;
    bigstar.brightness *= bigstar.power;
    coords = rotate(coords, vec2(0.), radians(rotation ? 45. : 0.));
    star = diamond(coords, bigstar);
  } else if (bigstar.type == NOVA) {
    bigstar.shape = uint(ceil(hash(bigstar.center, seed + 7u) * 40.));
    bigstar.diag = (bigstar.shape > 38u ? 0. :
      (bigstar.shape < 25u ?
        1. + hash(bigstar.center, seed + 8u) * 3.5 :
        hash(bigstar.center, seed + 8u) > 0.5 ? bigstar.size / pixel_res :
        2. + hash(bigstar.center, seed + 9u) * 3.));
    bigstar.brightness = (bigstar.shape > 38u ?
      100. / pixels : bigstar.size * bigstar.brightness);
    bigstar.brightness *= bigstar.power;
    star = nova(coords, bigstar);
  } else {
    bigstar.brightness *= bigstar.size;
    bigstar.brightness *= bigstar.power;
    bigstar.diag = 2.5 + hash(bigstar.center, seed + 7u) * 0.5;
    star = polar(coords, bigstar);
  }
  return star;
}

vec4 bigstars(vec2 coords)
{
  coords *= BIGSTARS_DENSITY;
  float d = 1e9,
        c;
  vec2 o;

  float pixel_res = BIGSTARS_DENSITY / pixels;

  vec2 i = floor(coords);
  vec2 f = fract(coords);
  vec2 h;
  vec2 center;

  for (int k = 0; k < 9; k++)
  {
    o = vec2(k % 3, k / 3) - 1.;

    center = i + o;
    h = vec2(hash(center, seed), hash(center, seed + 1u));
    coords = vec2(floor2(o.x + h.x - f.x, pixel_res),
      floor2(o.y + h.y - f.y, pixel_res));

    c = calc_star(coords, center, pixel_res);
    d = min(d, c);
  }
  return vec4(vec3(-d), 1.);
}
