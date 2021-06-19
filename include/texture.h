#ifndef SPACEPORN_PNG_H
#define SPACEPORN_PNG_H

#include <png.h>

#include "shader.h"

typedef struct
{
  png_structp ptr;
  png_infop info;
  png_bytep* row_pointers;
  uint8_t* data;
  FILE* file;
  char* path;
  GLuint texture;
  GLenum texture_unit;
} PNG;

bool freePng(PNG* png, Log* log);

#endif
