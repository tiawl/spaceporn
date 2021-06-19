#ifndef SPACEPORN_SHADER_H
#define SPACEPORN_SHADER_H

#include "parser.h"
#include "context.h"

typedef struct
{
  char* fshaderpath;
  char* vshaderpath;
  char* fshaderdir;
  char* vshaderdir;
  char* vertex_file;
  char* fragment_file;
  GLuint vertex_shader;
  GLuint fragment_shader;
  GLuint program;
} Shaders;

bool buildFile(char** filepath, char** buffer, char** dirpath, Log* log);
bool buildVertexShaderFile(Shaders* shaders, Log* log);
bool buildFragmentShaderFile(Shaders* shaders, Log* log);
bool checkLogShader(GLuint* shader, GLenum shaderType, char* buffer, Log* log);
bool loadShader(Shaders* shaders, GLenum shaderType, Log* log);
bool loadVertexShader(Shaders* shaders, Log* log);
bool loadFragmentShader(Shaders* shaders, Log* log);
bool checkLogProgram(Shaders* shaders, Log* log);
bool loadProgram(Context* context, Shaders* shaders, Log* log);
bool freeProgram(Shaders* shaders, Log* log);

#endif
