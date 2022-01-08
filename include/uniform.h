#ifndef SPACEPORN_UNIFORM_H
#define SPACEPORN_UNIFORM_H

#include "util.h"

typedef struct
{
  GLfloat time;
  GLint slide;
  struct timeval start;
  GLint width;
  GLint height;
  GLint pixels;
  GLboolean animations;
  GLboolean motion;
  GLboolean palettes;
  GLboolean precomputed;
  GLfloat zoom;
  GLfloat seed;
} UniformValues;

typedef struct
{
  char* name;
  bool (*update)(GLint, UniformValues*, bool);
} Uniform;

#define UNIFORM_COUNT 2
#define UNIFORM_FLOATS 6
#define UNIFORM_BOOLEANS 4

// custom functions used to set uniform values
bool updateFloatUniforms(GLint uniformId, UniformValues* values,
  bool verbose);
bool updateBoolUniforms(GLint uniformId, UniformValues* values, bool verbose);

bool getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, bool verbose);
void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, bool verbose);

#endif
