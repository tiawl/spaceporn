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
void freeShaders(Shaders* shaders, bool verbose);
void freeProgram(Shaders* shaders, char* spaces, bool verbose);
void checkingLogShader(GLuint* shader, GLenum shaderType, bool verbose);
GLuint loadShader(const char* shaderSource, GLenum shaderType, bool verbose);
bool loadVertexShader(Shaders* shaders, bool verbose, enum Roadmap roadmap);
bool loadFragmentShader(Shaders* shaders, bool verbose, enum Roadmap roadmap);
bool checkingLogProgram(Shaders* shaders, bool verbose, enum Roadmap roadmap);
bool loadProgram(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap);

#endif
