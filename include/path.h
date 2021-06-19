#ifndef SPACEPORN_PATH_H
#define SPACEPORN_PATH_H

#include <string.h>

#include "texture.h"

#define SHADERS_DIR GCC_SPREFIX
#define TEXTURES_DIR GCC_TPREFIX
#define FRAGMENT_DIR "fragment/"
#define VERTEX_DIR "vertex/"
#define MAIN_FILE "main.glsl"
#define ATLAS_FILE "atlas.png"

bool initPath(char** path, size_t len[2], char* root, char* dir, Log* log);
bool initPaths(Shaders* shaders, PNG* atlas, Log* log);

#endif
