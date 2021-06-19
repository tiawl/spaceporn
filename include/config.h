#ifndef XSHADER_CONFIG
#define XSHADER_CONFIG

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <GL/glew.h>

typedef struct
{
  GLuint id;
  GLenum format;
  GLenum min_filter;
  GLenum mag_filter;
  GLenum wrap_s;
  GLenum wrap_t;
  uint16_t w;
  uint16_t h;
} Texture;

typedef struct
{
  GLfloat time;
  clock_t clock;
  GLint width;
  GLint height;
  Texture tex;
  GLfloat pixels;
  GLboolean animations;
  GLboolean motion;
  GLboolean palettes;
  GLfloat xseed;
  GLfloat yseed;
} UniformValues;

typedef struct
{
  char* name;
  void (*update)(GLint, UniformValues*);
} Uniform;

#define _DEBUG

void CheckOpenGLError(const char* stmt, const char* fname, int line);

#ifdef _DEBUG
  #define GL_CHECK(stmt) do { \
    stmt; \
    CheckOpenGLError(#stmt, __FILE__, __LINE__); \
  } while (0)
#else
  #define GL_CHECK(stmt) stmt
#endif

/* shader uniforms */
#define UNIFORM_COUNT 2

/* custom functions used to set uniform values */
void updateFloatUniforms(GLint uniformId, UniformValues* values);
void updateBoolUniforms(GLint uniformId, UniformValues* values);
void updateTexture(GLint uniformId, UniformValues* values);

/* array of all uniforms to pass to the shader */
static const Uniform uniforms[] =
{
  {"fflags", &updateFloatUniforms},
  {"bflags", &updateBoolUniforms},
};

#endif
