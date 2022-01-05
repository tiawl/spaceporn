#ifndef XTELESKOP_SHADER_H
#define XTELESKOP_SHADER_H

#include "parser.h"
#include "context.h"

typedef struct
{
  char* fshaderpath;
  char* vshaderpath;
  char* vertex_file;
  char* fragment_file;
  GLuint vertex_shader;
  GLuint fragment_shader;
  GLuint program;
} Shaders;

bool buildFile(char** filepath, char** buffer, bool verbose,
  Roadmap* roadmap);
bool buildVertexShaderFile(Shaders* shaders, bool verbose, Roadmap* roadmap);
bool buildFragmentShaderFile(Shaders* shaders, bool verbose,
  Roadmap* roadmap);
bool checkLogShader(GLuint* shader, GLenum shaderType, char* buffer,
  bool verbose, Roadmap* roadmap);
bool loadShader(Shaders* shaders, GLenum shaderType, bool verbose,
  Roadmap* roadmap);
bool loadVertexShader(Shaders* shaders, bool verbose, Roadmap* roadmap);
bool loadFragmentShader(Shaders* shaders, bool verbose, Roadmap* roadmap);
bool checkLogProgram(Shaders* shaders, bool verbose, Roadmap* roadmap);
bool loadProgram(Context* context, Shaders* shaders, bool verbose,
  Roadmap* roadmap);
bool freeProgram(Shaders* shaders, bool verbose, Roadmap* roadmap);

#endif
