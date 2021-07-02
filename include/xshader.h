#ifndef XTELESKTOP_XSHADER_H
#define XTELESKTOP_XSHADER_H

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <png.h>
#include <time.h>
#include <string.h>
#include <GL/glew.h>

#include "util.h"

#define HOME_DIR "/home/"
#define BIN_DIR "/Workspace/Perso/xtelesktop" //  "/.local/bin"
#define SHADERS_DIR "/shaders"
#define TEXTURES_DIR "/textures"
#define FSHADER_FILE "/fragment.glsl"
#define VSHADER_FILE "/vertex.glsl"
#define TEXTURE_FILE "/big_stars.png"

#define UNIFORM_COUNT 2
#define UNIFORM_FLOATS 8
#define UNIFORM_BOOLEANS 4

typedef struct
{
  GLfloat time;
  clock_t clock;
  GLint width;
  GLint height;
  GLfloat pixels;
  GLboolean animations;
  GLboolean motion;
  GLboolean rocket;
  GLboolean palettes;
  GLfloat xseed;
  GLfloat yseed;
  GLint xcursor;
  GLint ycursor;
} UniformValues;

typedef struct
{
  char* name;
  void (*update)(GLint, UniformValues*);
} Uniform;

void CheckOpenGLError(const char* stmt, const char* fname, int line);

#define GL_CHECK(stmt) do { \
  stmt; \
  CheckOpenGLError(#stmt, __FILE__, __LINE__); \
} while (0)

/* custom functions used to set uniform values */
void updateFloatUniforms(GLint uniformId, UniformValues* values);
void updateBoolUniforms(GLint uniformId, UniformValues* values);
void updateTexture(GLint uniformId, UniformValues* values);

bool initPaths(char** fshaderpath, char** vshaderpath, char** texturepath,
  bool verbose);
bool readFile(char** filepath, char** buffer);
GLuint loadShader(const char* shaderSource, GLenum shaderType);
bool loadProgram(GLuint* program, GLuint* vertex_shader,
  char** vshaderpath, GLuint* fragment_shader, char** fshaderpath);
void getUniforms(const Uniform uniforms[UNIFORM_COUNT] ,
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program);
void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values);
void initVertices(GLuint* vertexbuffer, GLuint* vertexarray);
void drawScreen();

void cleanup(png_structp* parser, png_infop* info, png_bytep** row_pointers,
  uint8_t** data, FILE** file, char const * const filename);
bool loadPng(GLuint* texture, char const * const filename);

#endif
