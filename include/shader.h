#ifndef XTELESKTOP_SHADER_H
#define XTELESKTOP_SHADER_H

#include <errno.h>
#include <string.h>

#include "util.h"

bool readFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap);
bool readVertexShaderFile(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool readFragmentShaderFile(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
void freeShaders(Shaders* shaders, bool verbose);
void checkingLogShader(GLuint* shader, GLenum shaderType, bool verbose);
GLuint loadShader(const char* shaderSource, GLenum shaderType, bool verbose);
bool loadVertexShader(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool loadFragmentShader(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool checkingLogProgram(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool loadProgram(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);

#endif
