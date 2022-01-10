#ifndef SPACEPORN_PATH_H
#define SPACEPORN_PATH_H

#include <string.h>

#include "texture.h"

#define ROOT PREFIX
#define SHADERS_DIR "shaders/"
#define TEXTURES_DIR "textures/"
#define FRAGMENT_DIR "fragment/"
#define VERTEX_DIR "vertex/"
#define MAIN_FILE "main.glsl"
#define BIGSTARS_FILE "big_stars.png"
#define ATLAS_FILE "atlas.png"

bool initShaderPath(char** path, size_t len[4], char* dir, bool verbose,
  Roadmap* roadmap);
bool initTexturePath(PNG* png, size_t len[4], char* path, bool verbose,
  Roadmap* roadmap);
bool initPaths(Shaders* shaders, PNG* png, PNG* atlas, bool verbose,
  Roadmap* roadmap);
void freePaths(Shaders* shaders, PNG* png, PNG* atlas, bool verbose);

#endif
