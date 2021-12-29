#ifndef XTELESKOP_UNIFORM_H
#define XTELESKOP_UNIFORM_H

#include "util.h"

typedef struct
{
  GLfloat time;
  struct timeval start;
  GLint width;
  GLint height;
  GLint pixels;
  GLboolean animations;
  GLboolean motion;
  GLboolean palettes;
  GLfloat seed;
} UniformValues;

typedef struct
{
  char* name;
  void (*update)(GLint, UniformValues*, bool);
} Uniform;

#define UNIFORM_COUNT 2
#define UNIFORM_FLOATS 5
#define UNIFORM_BOOLEANS 3

/* custom functions used to set uniform values */
void updateFloatUniforms(GLint uniformId, UniformValues* values,
  bool verbose);
void updateBoolUniforms(GLint uniformId, UniformValues* values, bool verbose);

void getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, bool verbose);
void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, bool verbose);

#endif
