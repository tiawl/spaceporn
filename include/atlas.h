#ifndef SPACEPORN_ATLAS_H
#define SPACEPORN_ATLAS_H

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
  int pcg_depth;
  unsigned seed[2];
} Atlas;

bool writePng(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
void generatePcgTexture(Atlas* atlas, int offset, bool verbose,
  Roadmap* roadmap);
bool generateAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool readAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap);
bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, bool verbose,
  Roadmap* roadmap);
void freeAtlas(Atlas* atlas, bool verbose);

#endif
