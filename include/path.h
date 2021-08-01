#ifndef XTELESKTOP_PATH_H
#define XTELESKTOP_PATH_H

#include <string.h>

#include "util.h"

#define HOME_DIR "/home/"
#define BIN_DIR "/Workspace/Perso/xtelesktop" //  "/.local/bin"
#define SHADERS_DIR "/shaders"
#define TEXTURES_DIR "/textures"
#define FSHADER_FILE "/fragment/main.glsl"
#define VSHADER_FILE "/vertex/main.glsl"
#define TEXTURE_FILE "/big_stars.png"

bool initFragShaderPath(Shaders* shaders, size_t len[5], char* user,
  bool verbose, Roadmap* roadmap);
bool initVertShaderPath(Shaders* shaders, size_t len[5], char* user,
  bool verbose, Roadmap* roadmap);
bool initTexturePath(PNG* png, size_t len[5], char* user, bool verbose,
  Roadmap* roadmap);
bool initPaths(Shaders* shaders, PNG* png, bool verbose, Roadmap* roadmap);

#endif
