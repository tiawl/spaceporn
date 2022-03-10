uvec3 pcg3d(uvec3 v)
{
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return v;
}

float precomputed_hash(vec2 coords, uint hash_seed)
{
  float res;
  hash_seed -= seed;
  if (hash_seed == 0u)
  {
    res = texture(atlas, vec3(coords, 0.)).x;
  } else if (hash_seed == 1u) {
    res = texture(atlas, vec3(coords, 0.)).y;
  } else if (hash_seed == 2u) {
    res = texture(atlas, vec3(coords, 0.)).z;
  } else if (hash_seed == 3u) {
    res = texture(atlas, vec3(coords, 0.)).w;
  } else if (hash_seed == 4u) {
    res = texture(atlas, vec3(coords, 1.)).x;
  } else if (hash_seed == 5u) {
    res = texture(atlas, vec3(coords, 1.)).y;
  } else if (hash_seed == 6u) {
    res = texture(atlas, vec3(coords, 1.)).z;
  } else if (hash_seed == 7u) {
    res = texture(atlas, vec3(coords, 1.)).w;
  } else if (hash_seed == 8u) {
    res = texture(atlas, vec3(coords, 2.)).x;
  } else if (hash_seed == 9u) {
    res = texture(atlas, vec3(coords, 2.)).y;
  } else if (hash_seed == 10u) {
    res = texture(atlas, vec3(coords, 2.)).z;
  } else if (hash_seed == 11u) {
    res = texture(atlas, vec3(coords, 2.)).w;
  } else if (hash_seed == 12u) {
    res = texture(atlas, vec3(coords, 3.)).x;
  } else if (hash_seed == 13u) {
    res = texture(atlas, vec3(coords, 3.)).y;
  } else if (hash_seed == 14u) {
    res = texture(atlas, vec3(coords, 3.)).z;
  } else if (hash_seed == 15u) {
    res = texture(atlas, vec3(coords, 3.)).w;
  }
  return res;
}

float hash(vec2 coords, uint hash_seed)
{
  float res;
  if (mode < (SLIDE_MODE + BGGEN_MODE) / 2.)
  {
    res = precomputed_hash(coords * (stars_done ? pixels : 1.)
      / textureSize(atlas, 0).xy, hash_seed);
  } else {
    uvec4 u = uvec4(coords, uint(coords.x) ^ uint(coords.y),
      uint(coords.x) + uint(coords.y));
    uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
    res = float(p) * (1. / float(0xffffffffu));
  }
  return res;
}
