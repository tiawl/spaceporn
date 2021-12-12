#ifndef XTELESKOP_PATH_H
#define XTELESKOP_PATH_H

#include <string.h>

#include "util.h"

#define HOME_DIR "/home/"
#define BIN_DIR "/Workspace/Perso/xteleskop/" //  "/.local/bin/"
#define SHADERS_DIR "shaders/"
#define TEXTURES_DIR "textures/"
#define FRAGMENT_DIR "fragment/"
#define VERTEX_DIR "vertex/"
#define MAIN_FILE "main.glsl"
#define TEXTURE_FILE "big_stars.png"

bool initFragShaderPath(Shaders* shaders, size_t len[6], char* user,
  bool verbose, Roadmap* roadmap);
bool initVertShaderPath(Shaders* shaders, size_t len[6], char* user,
  bool verbose, Roadmap* roadmap);
bool initTexturePath(PNG* png, size_t len[5], char* user, bool verbose,
  Roadmap* roadmap);
bool initPaths(Shaders* shaders, PNG* png, bool verbose, Roadmap* roadmap);

#endif
