#ifndef SPACEPORN_ATLAS_H
#define SPACEPORN_ATLAS_H

#include <limits.h>
#include <png.h>

#include "precompute.h"
#include "texture.h"

typedef struct
{
  png_byte** texels;
  png_uint_32 width;
  png_uint_32 height;
  int depth;
  int pcg_depth;
  unsigned seed[2];
} Atlas;

bool writePng(Atlas* atlas, PNG* png, Log* log);
void generatePcgTexture(Atlas* atlas, int offset);
bool generateAtlas(Atlas* atlas, PNG* png, Log* log);
bool generateAtlas2(Atlas* atlas, PNG* png, Log* log);
bool readAtlas(Atlas* atlas, PNG* png, Log* log);
bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, Log* log);
void freeAtlas(Atlas* atlas, Log* log);

#endif
