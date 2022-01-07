#ifndef XTELESKOP_ATLAS_H
#define XTELESKOP_ATLAS_H

#include <limits.h>
#include <png.h>

#include "precompute.h"
#include "texture.h"

typedef struct
{
  png_byte** texels;
  int width;
  int height;
  int depth;
} Atlas;

bool writePng(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool generatePcgTexture(Atlas* atlas, bool verbose, Roadmap* roadmap);
bool generateAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool readAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, bool verbose,
  Roadmap* roadmap);
void freeAtlas(Atlas* atlas, bool verbose);

#endif
