#ifndef XTELESKOP_PNG_H
#define XTELESKOP_PNG_H

#include <png.h>

#include "util.h"

typedef struct
{
  png_structp ptr;
  png_infop info;
  png_bytep* row_pointers;
  uint8_t* data;
  FILE* file;
  char* path;
  GLuint texture;
} PNG;

bool loadPng(PNG* png, bool verbose, Roadmap* roadmap);
bool freePng(PNG* png, bool verbose);

#endif
