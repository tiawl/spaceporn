#include "path.h"

bool initShaderPath(char** path, size_t len[4], char* home, char* dir,
  bool verbose, Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("    Allocating memory for shader path ...\n"));
    if (roadmap->id != SHADERPATH_MALLOC_FAILED_RM)
    {
      *path = malloc(len[0] + len[1] + len[2] + len[3] + 1);
    }

    if (!(*path))
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "shader path malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Successful allocated memory for shader path\n"));

    LOG(verbose, printf("    Building shader path string ... 0/4\n"));
    memcpy(*path, home, len[0]);
    LOG(verbose, printf("    Building shader path string ... 1/4\n"));
    memcpy(*path + len[0], SHADERS_DIR, len[1]);
    LOG(verbose, printf("    Building shader path string ... 2/4\n"));
    memcpy(*path + len[0] + len[1], dir, len[2]);
    LOG(verbose, printf("    Building shader path string ... 3/4\n"));
    memcpy(*path + len[0] + len[1] + len[2], MAIN_FILE, len[3] + 1);
    LOG(verbose, printf("    Building shader path string ... 4/4\n"));
    LOG(verbose, printf("    Shader path string built: %s\n", *path));
  } while (false);

  return status;
}

bool initTexturePath(PNG* png, size_t len[4], char* home, char* path,
  bool verbose, Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("    Allocating memory for texture path ...\n"));

    if (roadmap->id != TEXTUREPATH_MALLOC_FAILED_RM)
    {
      png->path = malloc(len[0] + len[1] + len[2] + 1);
    }

    if (!png->path)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "texturepath malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Successful allocated memory for texture path\n"));

    LOG(verbose, printf("    Building texture path string ... 0/3\n"));
    memcpy(png->path, home, len[0]);
    LOG(verbose, printf("    Building texture path string ... 1/3\n"));
    memcpy(png->path + len[0], TEXTURES_DIR, len[1]);
    LOG(verbose, printf("    Building texture path string ... 2/3\n"));
    memcpy(png->path + len[0] + len[1], path, len[2] + 1);
    LOG(verbose, printf("    Building texture path string ... 3/3\n"));
    LOG(verbose, printf("    Texture path string built: %s\n", png->path));
  } while (false);

  return status;
}

bool initPaths(Shaders* shaders, PNG* png, bool verbose, Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("  Querying HOME environment variable ...\n"));
    char* home = NULL;
    if (roadmap->id != GETENV_HOME_FAILED_RM)
    {
        home = getenv("HOME");
    }

    if (!home)
    {
        LOG(verbose, printf("  "));
        fprintf((verbose ? stdout : stderr), "Unfoundable HOME environment \
variable\n");

        status = false;
        break;
    }
    LOG(verbose, printf("  HOME is \"%s\"\n", home));

    LOG(verbose, printf("  Computing HOME length ...\n"));
    const size_t len1 = strlen(home);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", home, len1));

    LOG(verbose, printf("  Computing length of shaders directory path ...\n"));
    const size_t len2 = strlen(SHADERS_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", SHADERS_DIR, len2));

    LOG(verbose, printf("  Computing length of textures directory path \
...\n"));
    const size_t len3 = strlen(TEXTURES_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURES_DIR, len3));

    LOG(verbose, printf("  Computing length of fragment shader directory \
...\n"));
    const size_t len4 = strlen(FRAGMENT_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", FRAGMENT_DIR, len4));

    LOG(verbose, printf("  Computing length of vertex shader directory \
...\n"));
    const size_t len5 = strlen(VERTEX_DIR);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", VERTEX_DIR, len5));

    LOG(verbose, printf("  Computing length of shader main filename ...\n"));
    const size_t len6 = strlen(MAIN_FILE);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", MAIN_FILE, len6));

    LOG(verbose, printf("  Computing length of texture filename ...\n"));
    const size_t len7 = strlen(BIGSTARS_FILE);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", BIGSTARS_FILE, len7));

    size_t length[4] =
    {
      len1, len2, len4, len6
    };

    LOG(verbose, printf("  Initializing fragment shader path ...\n"));
    if (!initShaderPath(&(shaders->fshaderpath), length, home, FRAGMENT_DIR,
      verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Fragment shader path \
initialization failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Fragment shader path initialized\n"));

    length[2] = len5;

    if (roadmap->id == VSHADERPATH_MALLOC_FAILED_RM)
    {
      roadmap->id = SHADERPATH_MALLOC_FAILED_RM;
    }

    LOG(verbose, printf("  Initializing vertex shader path ...\n"));
    if (!initShaderPath(&(shaders->vshaderpath), length, home, VERTEX_DIR,
      verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Vertex shader path \
initialization failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Vertex shader path initialized\n"));

    length[1] = len3;
    length[2] = len7;
    length[3] = 0;

    LOG(verbose, printf("  Initializing texture path ...\n"));
    if (!initTexturePath(png, length, home, BIGSTARS_FILE, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Texture path initialization \
failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Texture path initialized\n"));
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
