#ifndef XSHADER
#define XSHADER

#include <errno.h>
#include <string.h>
#include <png.h>

#include "config.h"

#define HOME_DIR "/home/"
#define BIN_DIR "/Workspace/Perso/xtelesktop" //  "/.local/bin"
#define SHADERS_DIR "/shaders"
#define TEXTURES_DIR "/textures"
#define FSHADER_FILE "/fragment.glsl"
#define VSHADER_FILE "/vertex.glsl"
#define TEXTURE_FILE "/big_stars.png"

void initPaths(char** fshaderpath, char** vshaderpath, char** texturepath);
const char* readFile(char** filepath);
GLuint loadShader(const char* shaderSource, GLenum shaderType);
bool loadProgram(GLuint* program, GLuint* vertex_shader,
  char** vshaderpath, GLuint* fragment_shader, char** fshaderpath);
void getUniforms(GLuint uniformIds[UNIFORM_COUNT], GLuint* program);
void setUniforms(GLuint uniformIds[UNIFORM_COUNT], UniformValues* values);
void initVertices();
void drawScreen();

void cleanup(png_structp* parser, png_infop* info, png_bytep** row_pointers,
  uint8_t** data, FILE** file, bool error, char const * const filename);
void loadPng(Texture* tex, char const * const filename);

#endif
