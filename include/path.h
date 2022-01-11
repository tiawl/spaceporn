#ifndef SPACEPORN_PATH_H
#define SPACEPORN_PATH_H

#include <string.h>

#include "texture.h"

#define NAME "spaceporn"
#define ROOT PREFIX
#define SHADERS_DIR "shaders/"
#define TEXTURES_DIR "textures/"
#define LOG_DIR "log/"
#define FRAGMENT_DIR "fragment/"
#define VERTEX_DIR "vertex/"
#define MAIN_FILE "main.glsl"
#define BIGSTARS_FILE "big_stars.png"
#define ATLAS_FILE "atlas.png"

bool initShaderPath(char** path, size_t len[4], char* dir, Log* log);
bool initTexturePath(PNG* png, size_t len[4], char* path, Log* log);
bool initLogPath(Log* log);
bool initPaths(Shaders* shaders, PNG* png, PNG* atlas, Log* log);

#endif
