#ifndef SPACEPORN_PRECOMPUTE_H
#define SPACEPORN_PRECOMPUTE_H

#include <math.h>

typedef struct
{
  unsigned x;
  unsigned y;
  unsigned z;
  unsigned w;
} uvec4;

void pcg4d(uvec4* vector);

#endif
