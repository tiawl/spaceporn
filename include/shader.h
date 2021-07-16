#ifndef XTELESKTOP_SHADER_H
#define XTELESKTOP_SHADER_H

#include <errno.h>
#include <string.h>

#include "util.h"

bool readFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap);
bool readVertexShaderFile(Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool readFragmentShaderFile(Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool checkingLogShader(GLuint* shader, GLenum shaderType, bool verbose,
  enum Roadmap roadmap);
bool loadShader(Shaders* shaders, GLenum shaderType, bool verbose,
  enum Roadmap roadmap);
bool loadVertexShader(Shaders* shaders, bool verbose, enum Roadmap roadmap);
bool loadFragmentShader(Shaders* shaders, bool verbose, enum Roadmap roadmap);
bool checkingLogProgram(Shaders* shaders, bool verbose, enum Roadmap roadmap);
bool loadProgram(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);

#endif
