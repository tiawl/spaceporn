#include "path.h"

bool initFragShaderPath(Shaders* shaders, size_t len[6], char* user,
  bool verbose, Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("  Allocating memory for fragment shader path ...\n"));
    if (roadmap->id != FSHADERPATH_MALLOC_FAILED_RM)
    {
      shaders->fshaderpath =
        malloc(len[0] + len[1] + len[2] + len[3] + len[4] + len[5] + 1);
    }

    if (!shaders->fshaderpath)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "fshaderpath malloc() failed\n");

      status = false;
      break;
    }
  LOG(verbose, printf("  Successfull allocated memory for fragment shader \
path\n"));

    LOG(verbose, printf("  Building fragment shader path string ... 0/6\n"));
    memcpy(shaders->fshaderpath, HOME_DIR, len[0]);
    LOG(verbose, printf("  Building fragment shader path string ... 1/6\n"));
    memcpy(shaders->fshaderpath + len[0], user, len[1]);
    LOG(verbose, printf("  Building fragment shader path string ... 2/6\n"));
    memcpy(shaders->fshaderpath + len[0] + len[1], BIN_DIR, len[2]);
    LOG(verbose, printf("  Building fragment shader path string ... 3/6\n"));
    memcpy(shaders->fshaderpath + len[0] + len[1] + len[2], SHADERS_DIR,
      len[3]);
    LOG(verbose, printf("  Building fragment shader path string ... 4/6\n"));
    memcpy(shaders->fshaderpath + len[0] + len[1] + len[2] + len[3],
      FRAGMENT_DIR, len[4]);
    LOG(verbose, printf("  Building fragment shader path string ... 5/6\n"));
    memcpy(shaders->fshaderpath + len[0] + len[1] + len[2] + len[3] + len[4],
      MAIN_FILE, len[5] + 1);
    LOG(verbose, printf("  Building fragment shader path string ... 6/6\n"));
    LOG(verbose, printf("  Fragment shader path string built: %s\n",
      shaders->fshaderpath));
  } while (false);

  return status;
}

bool initVertShaderPath(Shaders* shaders, size_t len[6], char* user,
  bool verbose, Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("  Allocating memory for vertex shader path ...\n"));
    if (roadmap->id != VSHADERPATH_MALLOC_FAILED_RM)
    {
      shaders->vshaderpath =
        malloc(len[0] + len[1] + len[2] + len[3] + len[4] + len[5] + 1);
    }

    if (!shaders->vshaderpath)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "vshaderpath malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Successfull allocated memory for vertex shader \
path\n"));

    LOG(verbose, printf("  Building vertex shader path string ... 0/6\n"));
    memcpy(shaders->vshaderpath, HOME_DIR, len[0]);
    LOG(verbose, printf("  Building vertex shader path string ... 1/6\n"));
    memcpy(shaders->vshaderpath + len[0], user, len[1]);
    LOG(verbose, printf("  Building vertex shader path string ... 2/6\n"));
    memcpy(shaders->vshaderpath + len[0] + len[1], BIN_DIR, len[2]);
    LOG(verbose, printf("  Building vertex shader path string ... 3/6\n"));
    memcpy(shaders->vshaderpath + len[0] + len[1] + len[2], SHADERS_DIR,
      len[3]);
    LOG(verbose, printf("  Building vertex shader path string ... 4/6\n"));
    memcpy(shaders->vshaderpath + len[0] + len[1] + len[2] + len[3],
      VERTEX_DIR, len[4]);
    LOG(verbose, printf("  Building vertex shader path string ... 5/6\n"));
    memcpy(shaders->vshaderpath + len[0] + len[1] + len[2] + len[3] + len[4],
      MAIN_FILE, len[5] + 1);
    LOG(verbose, printf("  Building vertex shader path string ... 6/6\n"));
    LOG(verbose, printf("  Vertex shader path string built: %s\n",
      shaders->vshaderpath));
  } while (false);

  return status;
}

bool initTexturePath(PNG* png, size_t len[5], char* user, bool verbose,
  Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("  Allocating memory for texture path ...\n"));

    if (roadmap->id != TEXTUREPATH_MALLOC_FAILED_RM)
    {
      png->path =
        malloc(len[0] + len[1] + len[2] + len[3] + len[4] + 1);
    }

    if (!png->path)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "texturepath malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Successfull allocated memory for texture path\n"));

    LOG(verbose, printf("  Building texture path string ... 0/5\n"));
    memcpy(png->path, HOME_DIR, len[0]);
    LOG(verbose, printf("  Building texture path string ... 1/5\n"));
    memcpy(png->path + len[0], user, len[1]);
    LOG(verbose, printf("  Building texture path string ... 2/5\n"));
    memcpy(png->path + len[0] + len[1], BIN_DIR, len[2]);
    LOG(verbose, printf("  Building texture path string ... 3/5\n"));
    memcpy(png->path + len[0] + len[1] + len[2], TEXTURES_DIR, len[3]);
    LOG(verbose, printf("  Building texture path string ... 4/5\n"));
    memcpy(png->path + len[0] + len[1] + len[2] + len[3], TEXTURE_FILE,
      len[4] + 1);
    LOG(verbose, printf("  Building texture path string ... 5/5\n"));
    LOG(verbose, printf("  Texture path string built: %s\n", png->path));
  } while (false);

  return status;
}

bool initPaths(Shaders* shaders, PNG* png, bool verbose, Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("  Computing length of home directory path ...\n"));
    const size_t len1 = strlen(HOME_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", HOME_DIR, len1));

    LOG(verbose, printf("  Querying username ...\n"));
    char* user = NULL;
    if (roadmap->id != GETENV_USERNAME_FAILED_RM)
    {
      user = getenv("USERNAME");
    }

    if (!user)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "No username on this device\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Username is \"%s\"\n", user));

    LOG(verbose, printf("  Computing username length ...\n"));
    const size_t len2 = strlen(user);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", user, len2));

    LOG(verbose, printf("  Computing length of binary directory path ...\n"));
    const size_t len3 = strlen(BIN_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", BIN_DIR, len3));

    LOG(verbose, printf("  Computing length of shaders directory path ...\n"));
    const size_t len4 = strlen(SHADERS_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", SHADERS_DIR, len4));

    LOG(verbose, printf("  Computing length of textures directory path \
...\n"));
    const size_t len5 = strlen(TEXTURES_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURES_DIR, len5));

    LOG(verbose, printf("  Computing length of fragment shader directory \
...\n"));
    const size_t len6 = strlen(FRAGMENT_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", FRAGMENT_DIR, len6));

    LOG(verbose, printf("  Computing length of vertex shader directory \
...\n"));
    const size_t len7 = strlen(VERTEX_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", VERTEX_DIR, len7));

    LOG(verbose, printf("  Computing length of shader main filename ...\n"));
    const size_t len8 = strlen(MAIN_FILE);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", MAIN_FILE, len8));

    LOG(verbose, printf("  Computing length of texture filename ...\n"));
    const size_t len9 = strlen(TEXTURE_FILE);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURE_FILE, len9));

    size_t f_length[6] =
    {
      len1, len2, len3, len4, len6, len8
    };

    if (initFragShaderPath(shaders, f_length, user, verbose, roadmap))
    {
      size_t v_length[6] =
      {
        len1, len2, len3, len4, len7, len8
      };

      if (initVertShaderPath(shaders, v_length, user,
        verbose, roadmap))
      {
        size_t t_length[5] =
        {
          len1, len2, len3, len5, len9
        };

        if (!initTexturePath(png, t_length,
          user, verbose, roadmap))
        {
          status = false;
          break;
        }
      } else {
        status = false;
        break;
      }
    } else {
      status = false;
      break;
    }
  } while (false);

  return status;
}

void freePaths(Shaders* shaders, PNG* png, bool verbose)
{
  if (shaders->fshaderpath)
  {
    LOG(verbose, printf("Freeing fshaderpath ...\n"));
    free(shaders->fshaderpath);
    shaders->fshaderpath = NULL;
    LOG(verbose, printf("fshaderpath freed\n"));
  }

  if (shaders->vshaderpath)
  {
    LOG(verbose, printf("Freeing vshaderpath ...\n"));
    free(shaders->vshaderpath);
    shaders->vshaderpath = NULL;
    LOG(verbose, printf("vshaderpath freed\n"));
  }

  if (png->path)
  {
    LOG(verbose, printf("Freeing texturepath ...\n"));
    free(png->path);
    png->path = NULL;
    LOG(verbose, printf("texturepath freed\n"));
  }
}
