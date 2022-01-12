#ifndef SPACEPORN_PATH_H
#define SPACEPORN_PATH_H

#include <string.h>

#include "texture.h"

#define SHADERS_DIR GCC_SPREFIX
#define TEXTURES_DIR GCC_TPREFIX
#define FRAGMENT_DIR "fragment/"
#define VERTEX_DIR "vertex/"
#define MAIN_FILE "main.glsl"
#define BIGSTARS_FILE "big_stars.png"
#define ATLAS_FILE "atlas.png"

bool initShaderPath(char** path, size_t len[3], char* dir, Log* log);
bool initTexturePath(PNG* png, size_t len[3], char* path, Log* log);
bool initPaths(Shaders* shaders, PNG* png, PNG* atlas, Log* log);

#endif
