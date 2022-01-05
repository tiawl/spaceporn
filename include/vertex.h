#ifndef XTELESKOP_VERTEX_H
#define XTELESKOP_VERTEX_H

#include "util.h"

typedef struct
{
  GLuint array;
  GLuint buffer;
} Vertices;

bool initVertices(Vertices* vertices, bool verbose);
bool draw(bool verbose);
bool freeVertices(Vertices* vertices, bool verbose);

#endif
