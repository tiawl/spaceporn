#ifndef XTELESKOP_ATLAS_H
#define XTELESKOP_ATLAS_H

#include <limits.h>
#include <math.h>
#include <png.h>

#include "texture.h"

typedef struct
{
  unsigned x;
  unsigned y;
  unsigned z;
  unsigned w;
} uvec4;

typedef struct
{
  png_byte** texels;
  int width;
  int height;
  int depth;
} Atlas;

bool writePng(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
void pcg4d(uvec4* vector);
bool generatePcgTexture(Atlas* atlas, bool verbose, Roadmap* roadmap);
bool generateAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool readAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, bool verbose,
  Roadmap* roadmap);
void freeAtlas(Atlas* atlas, bool verbose);

#endif
