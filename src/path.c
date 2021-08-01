#include "path.h"

bool initFragShaderPath(Shaders* shaders, size_t len[5], char* user,
  bool verbose, Roadmap* roadmap)
{
  VERB(verbose, printf("  Allocating memory for fragment shader path ...\n"));

  if (roadmap->id != FSHADERPATH_MALLOC_FAILED_RM)
  {
    shaders->fshaderpath =
      malloc(len[0] + len[1] + len[2] + len[3] + len[4] + 1);
  }

  if (!shaders->fshaderpath)
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "fshaderpath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for fragment shader \
path\n"));

  VERB(verbose, printf("  Building fragment shader path string ... 0/5\n"));
  memcpy(shaders->fshaderpath, HOME_DIR, len[0]);
  VERB(verbose, printf("  Building fragment shader path string ... 1/5\n"));
  memcpy(shaders->fshaderpath + len[0], user, len[1]);
  VERB(verbose, printf("  Building fragment shader path string ... 2/5\n"));
  memcpy(shaders->fshaderpath + len[0] + len[1], BIN_DIR, len[2]);
  VERB(verbose, printf("  Building fragment shader path string ... 3/5\n"));
  memcpy(shaders->fshaderpath + len[0] + len[1] + len[2], SHADERS_DIR,
    len[3]);
  VERB(verbose, printf("  Building fragment shader path string ... 4/5\n"));
  memcpy(shaders->fshaderpath + len[0] + len[1] + len[2] + len[3],
    FSHADER_FILE, len[4] + 1);
  VERB(verbose, printf("  Building fragment shader path string ... 5/5\n"));
  VERB(verbose, printf("  Fragment shader path string built: %s\n",
    shaders->fshaderpath));

  return true;
}

bool initVertShaderPath(Shaders* shaders, size_t len[5], char* user,
  bool verbose, Roadmap* roadmap)
{
  VERB(verbose, printf("  Allocating memory for vertex shader path ...\n"));

  if (roadmap->id != VSHADERPATH_MALLOC_FAILED_RM)
  {
    shaders->vshaderpath =
      malloc(len[0] + len[1] + len[2] + len[3] + len[4] + 1);
  }

  if (!shaders->vshaderpath)
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "vshaderpath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for vertex shader \
path\n"));

  VERB(verbose, printf("  Building vertex shader path string ... 0/5\n"));
  memcpy(shaders->vshaderpath, HOME_DIR, len[0]);
  VERB(verbose, printf("  Building vertex shader path string ... 1/5\n"));
  memcpy(shaders->vshaderpath + len[0], user, len[1]);
  VERB(verbose, printf("  Building vertex shader path string ... 2/5\n"));
  memcpy(shaders->vshaderpath + len[0] + len[1], BIN_DIR, len[2]);
  VERB(verbose, printf("  Building vertex shader path string ... 3/5\n"));
  memcpy(shaders->vshaderpath + len[0] + len[1] + len[2], SHADERS_DIR,
    len[3]);
  VERB(verbose, printf("  Building vertex shader path string ... 4/5\n"));
  memcpy(shaders->vshaderpath + len[0] + len[1] + len[2] + len[3],
    VSHADER_FILE, len[4] + 1);
  VERB(verbose, printf("  Building vertex shader path string ... 5/5\n"));
  VERB(verbose, printf("  Vertex shader path string built: %s\n",
    shaders->vshaderpath));

  return true;
}

bool initTexturePath(PNG* png, size_t len[5], char* user, bool verbose,
  Roadmap* roadmap)
{
  VERB(verbose, printf("  Allocating memory for texture path ...\n"));

  if (roadmap->id != TEXTUREPATH_MALLOC_FAILED_RM)
  {
    png->path =
      malloc(len[0] + len[1] + len[2] + len[3] + len[4] + 1);
  }

  if (!png->path)
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "texturepath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for texture path\n"));

  VERB(verbose, printf("  Building texture path string ... 0/5\n"));
  memcpy(png->path, HOME_DIR, len[0]);
  VERB(verbose, printf("  Building texture path string ... 1/5\n"));
  memcpy(png->path + len[0], user, len[1]);
  VERB(verbose, printf("  Building texture path string ... 2/5\n"));
  memcpy(png->path + len[0] + len[1], BIN_DIR, len[2]);
  VERB(verbose, printf("  Building texture path string ... 3/5\n"));
  memcpy(png->path + len[0] + len[1] + len[2], TEXTURES_DIR, len[3]);
  VERB(verbose, printf("  Building texture path string ... 4/5\n"));
  memcpy(png->path + len[0] + len[1] + len[2] + len[3], TEXTURE_FILE,
    len[4] + 1);
  VERB(verbose, printf("  Building texture path string ... 5/5\n"));
  VERB(verbose, printf("  Texture path string built: %s\n", png->path));

  return true;
}

bool initPaths(Shaders* shaders, PNG* png, bool verbose, Roadmap* roadmap)
{
  VERB(verbose, printf("  Computing length of home directory path ...\n"));
  const size_t len1 = strlen(HOME_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", HOME_DIR, len1));

  VERB(verbose, printf("  Querying username ...\n"));
  char* user = NULL;
  if (roadmap->id != GETENV_USERNAME_FAILED_RM)
  {
    user = getenv("USERNAME");
  }

  if (!user)
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "No username on this device\n");
    return false;
  }
  VERB(verbose, printf("  Username is \"%s\"\n", user));

  VERB(verbose, printf("  Computing username length ...\n"));
  const size_t len2 = strlen(user);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", user, len2));

  VERB(verbose, printf("  Computing length of binary directory path ...\n"));
  const size_t len3 = strlen(BIN_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", BIN_DIR, len3));

  VERB(verbose, printf("  Computing length of shaders directory path ...\n"));
  const size_t len4 = strlen(SHADERS_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", SHADERS_DIR, len4));

  VERB(verbose, printf("  Computing length of textures directory path \
...\n"));
  const size_t len5 = strlen(TEXTURES_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURES_DIR, len5));

  VERB(verbose, printf("  Computing length of fragment shader filename \
...\n"));
  const size_t len6 = strlen(FSHADER_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", FSHADER_FILE, len6));

  VERB(verbose, printf("  Computing length of vertex shader filename ...\n"));
  const size_t len7 = strlen(VSHADER_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", VSHADER_FILE, len7));

  VERB(verbose, printf("  Computing length of texture filename ...\n"));
  const size_t len8 = strlen(TEXTURE_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURE_FILE, len8));

  size_t f_length[5] =
  {
    len1, len2, len3, len4, len6
  };

  if (initFragShaderPath(shaders, f_length, user, verbose, roadmap))
  {
    size_t v_length[5] =
    {
      len1, len2, len3, len4, len7
    };

    if (initVertShaderPath(shaders, v_length, user,
      verbose, roadmap))
    {
      size_t t_length[5] =
      {
        len1, len2, len3, len5, len8
      };

      if (!initTexturePath(png, t_length,
        user, verbose, roadmap))
      {
        return false;
      }
    } else {
      return false;
    }
  } else {
    return false;
  }
  return true;
}
