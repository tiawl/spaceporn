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
} UniformValues;

typedef struct
{
  char* name;
  void (*setValue)(GLint, UniformValues*);
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

/* measured in microseconds */
#define DELAY 30000

/* shader uniforms */
#define UNIFORM_COUNT 3

/* custom functions used to set uniform values */
void incr_time(GLint uniformId, UniformValues* values);
void get_resolution(GLint uniformId, UniformValues* values);
void get_texture(GLint uniformId, UniformValues* values);

/* array of all uniforms to pass to the shader */
static const Uniform uniforms[] =
{
  {"time", &incr_time},
  {"resolution", &get_resolution},
  {"big_stars_texture", &get_texture},
};

#endif
