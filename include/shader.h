#ifndef XTELESKTOP_SHADER_H
#define XTELESKTOP_SHADER_H

#include <errno.h>
#include <string.h>

#include "util.h"

bool readFile(char** filepath, char** buffer, bool verbose);
GLuint loadShader(const char* shaderSource, GLenum shaderType, bool verbose);
bool loadProgram(GLuint* program, GLuint* vertex_shader,
  char** vshaderpath, GLuint* fragment_shader, char** fshaderpath,
  bool verbose);
void initVertices(GLuint* vertexbuffer, GLuint* vertexarray, bool verbose);
void draw(bool verbose);

#endif
