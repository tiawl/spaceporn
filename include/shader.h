#ifndef XTELESKTOP_SHADER_H
#define XTELESKTOP_SHADER_H

#include <errno.h>
#include <string.h>

#include "util.h"

bool readFile(char** filepath, char** buffer, bool verbose);
bool readVertexShaderFile(Context* context, Shaders* shaders, bool verbose);
bool readFragmentShaderFile(Context* context, Shaders* shaders, bool verbose);
void freeShaders(Shaders* shaders, bool verbose);
void checkingLogShader(GLuint* shader, GLenum shaderType, bool verbose);
GLuint loadShader(const char* shaderSource, GLenum shaderType, bool verbose);
bool loadVertexShader(Context* context, Shaders* shaders, bool verbose);
bool loadFragmentShader(Context* context, Shaders* shaders, bool verbose);
bool checkingLogProgram(Context* context, Shaders* shaders, bool verbose);
bool loadProgram(Context* context, Shaders* shaders, bool verbose);

#endif
