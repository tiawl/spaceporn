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

bool loadPng(PNG* png, Shaders* shaders, bool verbose, Roadmap* roadmap);
bool freePng(PNG* png, bool verbose);

#endif
