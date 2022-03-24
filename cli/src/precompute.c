#include "precompute.h"

void pcg4d(uvec4* vector)
{
  vector->x = vector->x * 1664525u + 1013904223u;
  vector->y = vector->y * 1664525u + 1013904223u;
  vector->z = vector->z * 1664525u + 1013904223u;
  vector->w = vector->w * 1664525u + 1013904223u;

  vector->x += vector->y * vector->w;
  vector->y += vector->z * vector->x;
  vector->z += vector->x * vector->y;
  vector->w += vector->y * vector->z;

  vector->x ^= vector->x >> 16u;
  vector->y ^= vector->y >> 16u;
  vector->z ^= vector->z >> 16u;
  vector->w ^= vector->w >> 16u;

  vector->x += vector->y * vector->w;
  vector->y += vector->z * vector->x;
  vector->z += vector->x * vector->y;
  vector->w += vector->y * vector->z;
}
