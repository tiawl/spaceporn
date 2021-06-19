#ifndef SPACEPORN_UNIFORM_H
#define SPACEPORN_UNIFORM_H

#include "util.h"

typedef struct
{
  GLfloat time;
  struct timeval start;
  GLint width;
  GLint height;
  GLint pixels;
  GLint mode;
  GLint color;
  GLfloat zoom;
  GLfloat seed;
} UniformValues;

typedef struct
{
  char* name;
  bool (*update)(GLint, UniformValues*, Log*);
} Uniform;

#define UNIFORM_COUNT 1
#define UNIFORM_FLOATS 8

// custom functions used to set uniform values
bool updateFloatUniforms(GLint uniformId, UniformValues* values, Log* log);

bool getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, Log* log);
void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, Log* log);

#endif
