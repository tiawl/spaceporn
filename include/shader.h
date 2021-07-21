#ifndef XTELESKTOP_SHADER_H
#define XTELESKTOP_SHADER_H

#include <errno.h>
#include <string.h>
#include <regex.h>

#define ERRONEOUS_VERTEX_SHADER "# version 330 core\n\
\n\
layout(location = 0)\n\
in vec2 vertexPosition;\n\
\n\
void main()\n\
{"

#define MISSINGMAIN_VERTEX_SHADER "# version 330 core\n\
\n\
layout(location = 0) in vec2 vertexPosition;"

#define ERRONEOUS_FRAGMENT_SHADER "# version 330 core\n\
\n\
uniform float fflags[6];\n\
uniform bvec3 bflags;\n\
uniform sampler2D big_stars_texture;\n\
\n\
out vec4 fragColor;\n\
\n\
void main()\n\
{"

#include "util.h"

bool regex_replace(char** str, const char* pattern, const char* replace);
bool readFile(char** filepath, char** buffer, char* spaces, bool verbose,
  enum Roadmap roadmap);
bool buildFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap);
bool buildVertexShaderFile(Shaders* shaders, bool verbose,
  enum Roadmap roadmap);
bool buildFragmentShaderFile(Shaders* shaders, bool verbose,
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
