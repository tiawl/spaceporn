#ifndef SPACEPORN_VERTEX_H
#define SPACEPORN_VERTEX_H

#include "util.h"

typedef struct
{
  GLuint array;
  GLuint buffer;
} Vertices;

bool initVertices(Vertices* vertices, Log* log);
bool draw(Log* log);
bool freeVertices(Vertices* vertices, Log* log);

#endif
