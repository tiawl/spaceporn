#ifndef XTELESKOP_ATLAS_H
#define XTELESKOP_ATLAS_H

#include <math.h>
#include <limits.h>

#include "shader.h"
#include "uniform.h"

typedef struct
{
  unsigned x;
  unsigned y;
  unsigned z;
  unsigned w;
} uvec4;

typedef struct
{
  GLubyte* texels;
  int width;
  int height;
  int depth;
  GLuint texture;
  GLenum texture_unit;
} Atlas;

void pcg4d(uvec4* vector);
bool generatePcgTexture(Atlas* atlas, bool verbose, Roadmap* roadmap);
bool generateAtlas(Atlas* atlas, bool verbose, Roadmap* roadmap);
bool loadAtlas(Atlas* atlas, Shaders* shaders, bool verbose, Roadmap* roadmap);
void freeAtlas(Atlas* atlas, bool verbose);

#endif
