#ifndef XTELESKOP_PATH_H
#define XTELESKOP_PATH_H

#include <string.h>

#include "shader.h"
#include "texture.h"

#define HOME_DIR "/home/"
#define BIN_DIR "/Workspace/Perso/xteleskop/" //  "/.local/bin/"
#define SHADERS_DIR "shaders/"
#define TEXTURES_DIR "textures/"
#define FRAGMENT_DIR "fragment/"
#define VERTEX_DIR "vertex/"
#define MAIN_FILE "main.glsl"
#define BIGSTARS_FILE "big_stars.png"
#define ATLAS_FILE "atlas.png"

bool initFragShaderPath(Shaders* shaders, size_t len[6], char* user,
  bool verbose, Roadmap* roadmap);
bool initVertShaderPath(Shaders* shaders, size_t len[6], char* user,
  bool verbose, Roadmap* roadmap);
bool initTexturePath(PNG* png, size_t len[6], char* user, char* path,
  bool verbose, Roadmap* roadmap);
bool initPaths(Shaders* shaders, Textures* textures, bool verbose,
  Roadmap* roadmap);
void freePaths(Shaders* shaders, Textures* textures, bool verbose);

#endif
