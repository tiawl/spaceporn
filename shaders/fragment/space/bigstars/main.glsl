# include "hash.glsl"
# include "space/bigstars/diamond.glsl"
# include "space/bigstars/nova.glsl"
# include "space/bigstars/polar.glsl"

# define DIAMOND 0.
# define NOVA    1.
# define POLAR   2.
# define STAR_TYPES 3.

float calc_star(vec2 coords, vec2 center, float pixel_res)
{
  float rd_bigstar =
    NOVA; //min(floor(hash(center, seed + 2u) * STAR_TYPES), STAR_TYPES - 1.);
  float size_hash = hash(center, seed + 3u);
  size_hash *= size_hash;
  size_hash *= size_hash;
  size_hash *= size_hash;
  float size = (min(floor(size_hash * 10.), 9.) + 7.) * pixel_res;
  float brightness = hash(center, seed + 4u) + 1.;
  float ring_size = hash(center, seed + 5u) * 2.;

  float star = 0.;
  Star bigstar = Star(rd_bigstar, center, size, 120., 1., 1., 0u, ring_size);
  if (bigstar.type < (DIAMOND + NOVA) / 2.)
  {
    bool rotation = hash(bigstar.center, seed + 6u) > 0.5;
    bigstar.brightness *= bigstar.size;
    coords = rotate(coords, vec2(0.), radians(rotation ? 45. : 0.));
    bigstar.ring_size = (bigstar.ring_size * bigstar.size < pixel_res * 5. ?
      0. : bigstar.ring_size);
    star = diamond(coords, bigstar);
  } else if (bigstar.type < (NOVA + POLAR) / 2.) {
    bigstar.shape = uint(ceil(hash(bigstar.center, seed + 6u) * 20.));
    bigstar.diag = (bigstar.shape >= 17u ? 0. :
      (bigstar.shape < 8u || bigstar.shape > 16u ?
        1. + hash(bigstar.center, seed + 7u) * 3.5 :
        hash(bigstar.center, seed + 7u) > 0.5 ? bigstar.size / pixel_res :
        2. + hash(bigstar.center, seed + 8u) * 3. ));
    bigstar.brightness = (bigstar.shape == 17u ?
      80. / pixels : (bigstar.shape == 18u ?
        50. / pixels : (bigstar.shape >= 19u ?
          100. / pixels : bigstar.size * bigstar.brightness)));
    bigstar.ring_size = (bigstar.ring_size * bigstar.size < pixel_res * 7. ?
      0. : bigstar.ring_size);
    star = nova(coords, bigstar);
  } else {
    bigstar.brightness *= bigstar.size;
    bigstar.diag = 2.5 + hash(bigstar.center, seed + 6u) * 0.5;
    bigstar.ring_size = (bigstar.ring_size * bigstar.size < pixel_res * 7. ?
      0. : bigstar.ring_size);
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
    h = vec2(floor_multiple(hash(center, seed), pixel_res),
      floor_multiple(hash(center, seed + 1u), pixel_res));
    coords = o + h - f;

    c = calc_star(coords, center, pixel_res);
    d = min(d, c);
  }
  return vec4(vec3(-d), 1.);
}
