#ifndef XTELESKOP_PNGTEXTURE_H
#define XTELESKOP_PNGTEXTURE_H

#include <math.h>

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
  png_structp ptr;
  png_infop info;
  png_bytep* read_row_pointers;
  png_byte** write_row_pointers;
  uint8_t* data;
  FILE* file;
  char* path;
  GLuint texture;
} PNG;

typedef struct
{
  PNG bigstars;
  PNG atlas;
} Textures;

bool loadPng(PNG* png, bool verbose, Roadmap* roadmap);
void pcg4d(uvec4* vector);
bool generatePcgTexture(PNG* png, UniformValues* values, int* width,
  int* height, bool verbose);
bool writePng(PNG* png, UniformValues* values, int* width, int* height,
  bool verbose);
bool generateAtlas(PNG* png, UniformValues* values, bool verbose);
void freeTextures(Textures* textures, bool verbose);
bool freePng(PNG* png, bool verbose);

#endif
