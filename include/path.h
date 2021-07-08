#ifndef XTELESKTOP_PATH_H
#define XTELESKTOP_PATH_H

#include <string.h>

#include "util.h"

#define HOME_DIR "/home/"
#define BIN_DIR "/Workspace/Perso/xtelesktop" //  "/.local/bin"
#define SHADERS_DIR "/shaders"
#define TEXTURES_DIR "/textures"
#define FSHADER_FILE "/fragment.glsl"
#define VSHADER_FILE "/vertex.glsl"
#define TEXTURE_FILE "/big_stars.png"

bool initFragShaderPath(char** fshaderpath, bool verbose);
bool initVertShaderPath(char** vshaderpath, bool verbose);
bool initTexturePath(char** texturepath, bool verbose);
bool initPaths(char** fshaderpath, char** vshaderpath, char** texturepath,
  bool verbose);
void freePaths(char** fshaderpath, char** vshaderpath, char** texturepath,
  bool verbose);

#endif
