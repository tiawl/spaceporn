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

bool initFragShaderPath(Shaders* shaders, bool verbose);
bool initVertShaderPath(Shaders* shaders, bool verbose);
bool initTexturePath(char** texturepath, bool verbose);
bool initPaths(Shaders* shaders, char** texturepath, bool verbose);
void freePaths(Shaders* shaders, char** texturepath, bool verbose);

#endif
