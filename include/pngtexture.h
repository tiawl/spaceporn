#ifndef XTELESKTOP_PNGTEXTURE_H
#define XTELESKTOP_PNGTEXTURE_H

#include <png.h>

#include "util.h"

void cleanup(png_structp* parser, png_infop* info, png_bytep** row_pointers,
  uint8_t** data, FILE** file, char const * const filename, bool verbose);
bool loadPng(GLuint* texture, char const * const filename, bool verbose,
  enum Roadmap roadmap);

#endif
