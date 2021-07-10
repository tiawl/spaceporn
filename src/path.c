#include "path.h"

bool initFragShaderPath(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Computing length of home directory path ...\n"));
  const size_t len1 = strlen(HOME_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", HOME_DIR, len1));

  VERB(verbose, printf("  Computing username length ...\n"));
  const size_t len2 = strlen(getenv("USERNAME"));
  VERB(verbose, printf("  Length of \"%s\" is %lu\n",
    getenv("USERNAME"), len2));

  VERB(verbose, printf("  Computing length of binary directory path ...\n"));
  const size_t len3 = strlen(BIN_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", BIN_DIR, len3));

  VERB(verbose, printf("  Computing length of shaders directory path ...\n"));
  const size_t len4 = strlen(SHADERS_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", SHADERS_DIR, len4));

  VERB(verbose, printf("  Computing length of fragment shader filename \
...\n"));
  const size_t len6 = strlen(FSHADER_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", FSHADER_FILE, len6));

  VERB(verbose, printf("  Allocating memory for fragment shader path ...\n"));

  if (roadmap != FSHADERPATH_MALLOC_FAILED_RM)
  {
    shaders->fshaderpath = malloc(len1 + len2 + len3 + len4 + len6 + 1);
  }

  if (!shaders->fshaderpath)
  {
    fprintf(stderr, "  fshaderpath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for fragment shader \
path ...\n"));

  VERB(verbose, printf("  Building fragment shader path string ... 0/5\n"));
  memcpy(shaders->fshaderpath, HOME_DIR, len1);
  VERB(verbose, printf("  Building fragment shader path string ... 1/5\n"));
  memcpy(shaders->fshaderpath + len1, getenv("USERNAME"), len2);
  VERB(verbose, printf("  Building fragment shader path string ... 2/5\n"));
  memcpy(shaders->fshaderpath + len1 + len2, BIN_DIR, len3);
  VERB(verbose, printf("  Building fragment shader path string ... 3/5\n"));
  memcpy(shaders->fshaderpath + len1 + len2 + len3, SHADERS_DIR, len4);
  VERB(verbose, printf("  Building fragment shader path string ... 4/5\n"));
  memcpy(shaders->fshaderpath + len1 + len2 + len3 + len4, FSHADER_FILE,
    len6 + 1);
  VERB(verbose, printf("  Building fragment shader path string ... 5/5\n"));
  VERB(verbose, printf("  Fragment shader path string built: %s\n",
    shaders->fshaderpath));

  return true;
}

bool initVertShaderPath(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Computing length of home directory path ...\n"));
  const size_t len1 = strlen(HOME_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", HOME_DIR, len1));

  VERB(verbose, printf("  Computing username length ...\n"));
  const size_t len2 = strlen(getenv("USERNAME"));
  VERB(verbose, printf("  Length of \"%s\" is %lu\n",
    getenv("USERNAME"), len2));

  VERB(verbose, printf("  Computing length of binary directory path ...\n"));
  const size_t len3 = strlen(BIN_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", BIN_DIR, len3));

  VERB(verbose, printf("  Computing length of shaders directory path ...\n"));
  const size_t len4 = strlen(SHADERS_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", SHADERS_DIR, len4));

  VERB(verbose, printf("  Computing length of vertex shader filename ...\n"));
  const size_t len7 = strlen(VSHADER_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", VSHADER_FILE, len7));

  VERB(verbose, printf("  Allocating memory for vertex shader path ...\n"));

  if (roadmap != VSHADERPATH_MALLOC_FAILED_RM)
  {
    shaders->vshaderpath = malloc(len1 + len2 + len3 + len4 + len7 + 1);
  }

  if (!shaders->vshaderpath)
  {
    fprintf(stderr, "  vshaderpath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for vertex shader \
path\n"));

  VERB(verbose, printf("  Building vertex shader path string ... 0/5\n"));
  memcpy(shaders->vshaderpath, HOME_DIR, len1);
  VERB(verbose, printf("  Building vertex shader path string ... 1/5\n"));
  memcpy(shaders->vshaderpath + len1, getenv("USERNAME"), len2);
  VERB(verbose, printf("  Building vertex shader path string ... 2/5\n"));
  memcpy(shaders->vshaderpath + len1 + len2, BIN_DIR, len3);
  VERB(verbose, printf("  Building vertex shader path string ... 3/5\n"));
  memcpy(shaders->vshaderpath + len1 + len2 + len3, SHADERS_DIR, len4);
  VERB(verbose, printf("  Building vertex shader path string ... 4/5\n"));
  memcpy(shaders->vshaderpath + len1 + len2 + len3 + len4, VSHADER_FILE,
    len7 + 1);
  VERB(verbose, printf("  Building vertex shader path string ... 5/5\n"));
  VERB(verbose, printf("  Vertex shader path string built: %s\n",
    shaders->vshaderpath));

  return true;
}

bool initTexturePath(char** texturepath, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Computing length of home directory path ...\n"));
  const size_t len1 = strlen(HOME_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", HOME_DIR, len1));

  VERB(verbose, printf("  Computing username length ...\n"));
  const size_t len2 = strlen(getenv("USERNAME"));
  VERB(verbose, printf("  Length of \"%s\" is %lu\n",
    getenv("USERNAME"), len2));

  VERB(verbose, printf("  Computing length of binary directory path ...\n"));
  const size_t len3 = strlen(BIN_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", BIN_DIR, len3));

  VERB(verbose, printf("  Computing length of textures directory path \
...\n"));
  const size_t len5 = strlen(TEXTURES_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURES_DIR, len5));

  VERB(verbose, printf("  Computing length of texture filename ...\n"));
  const size_t len8 = strlen(TEXTURE_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURE_FILE, len8));

  VERB(verbose, printf("  Allocating memory for texture path ...\n"));

  if (roadmap != TEXTUREPATH_MALLOC_FAILED_RM)
  {
    *texturepath = malloc(len1 + len2 + len3 + len5 + len8 + 1);
  }

  if (!*texturepath)
  {
    fprintf(stderr, "  texturepath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for texture path\n"));

  VERB(verbose, printf("  Building texture path string ... 0/5\n"));
  memcpy(*texturepath, HOME_DIR, len1);
  VERB(verbose, printf("  Building texture path string ... 1/5\n"));
  memcpy(*texturepath + len1, getenv("USERNAME"), len2);
  VERB(verbose, printf("  Building texture path string ... 2/5\n"));
  memcpy(*texturepath + len1 + len2, BIN_DIR, len3);
  VERB(verbose, printf("  Building texture path string ... 3/5\n"));
  memcpy(*texturepath + len1 + len2 + len3, TEXTURES_DIR, len5);
  VERB(verbose, printf("  Building texture path string ... 4/5\n"));
  memcpy(*texturepath + len1 + len2 + len3 + len5, TEXTURE_FILE, len8 + 1);
  VERB(verbose, printf("  Building texture path string ... 5/5\n"));
  VERB(verbose, printf("  Texture path string built: %s\n", *texturepath));

  return true;
}

bool initPaths(Shaders* shaders, char** texturepath, bool verbose,
  enum Roadmap roadmap)
{
  if (initFragShaderPath(shaders, verbose, roadmap))
  {
    if (initVertShaderPath(shaders, verbose, roadmap))
    {
      if (!initTexturePath(texturepath, verbose, roadmap))
      {
        freePaths(shaders, texturepath, verbose);
        return false;
      }
    } else {
      freePaths(shaders, texturepath, verbose);
      return false;
    }
  } else {
    return false;
  }
  return true;
}

void freePaths(Shaders* shaders, char** texturepath, bool verbose)
{
  if (shaders->fshaderpath)
  {
    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(shaders->fshaderpath);
    VERB(verbose, printf("fshaderpath freed\n"));
  }

  if (shaders->vshaderpath)
  {
    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(shaders->vshaderpath);
    VERB(verbose, printf("vshaderpath freed\n"));
  }

  if (*texturepath)
  {
    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(*texturepath);
    VERB(verbose, printf("texturepath freed\n"));
  }
}
