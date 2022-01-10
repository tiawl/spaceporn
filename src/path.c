#include "path.h"

bool initShaderPath(char** path, size_t len[4], char* dir, bool verbose,
  Roadmap* roadmap)
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
    memcpy(*path, ROOT, len[0]);
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

bool initTexturePath(PNG* png, size_t len[4], char* path, bool verbose,
  Roadmap* roadmap)
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
    memcpy(png->path, ROOT, len[0]);
    LOG(verbose, printf("    Building texture path string ... 1/3\n"));
    memcpy(png->path + len[0], TEXTURES_DIR, len[1]);
    LOG(verbose, printf("    Building texture path string ... 2/3\n"));
    memcpy(png->path + len[0] + len[1], path, len[2] + 1);
    LOG(verbose, printf("    Building texture path string ... 3/3\n"));
    LOG(verbose, printf("    Texture path string built: %s\n", png->path));
  } while (false);

  return status;
}

bool initPaths(Shaders* shaders, PNG* png, PNG* atlas, bool verbose,
  Roadmap* roadmap)
{
  int status = true;

  do
  {
    LOG(verbose, printf("  Computing ROOT length ...\n"));
    const size_t len1 = strlen(ROOT);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", ROOT, len1));

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

    LOG(verbose, printf("  Computing length of atlas filename ...\n"));
    const size_t len8 = strlen(ATLAS_FILE);
    LOG(verbose, printf("  Length of \"%s\" is %lu\n", ATLAS_FILE, len8));

    size_t length[4] =
    {
      len1, len2, len4, len6
    };

    LOG(verbose, printf("  Initializing fragment shader path ...\n"));
    if (!initShaderPath(&(shaders->fshaderpath), length, FRAGMENT_DIR,
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
    if (!initShaderPath(&(shaders->vshaderpath), length, VERTEX_DIR,
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
    if (!initTexturePath(png, length, BIGSTARS_FILE, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Texture path initialization \
failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Texture path initialized\n"));

    length[2] = len8;

    if (roadmap->id == ATLASTEXTUREPATH_MALLOC_FAILED_RM)
    {
      roadmap->id = TEXTUREPATH_MALLOC_FAILED_RM;
    }

    LOG(verbose, printf("  Initializing atlas texture path ...\n"));
    if (!initTexturePath(atlas, length, ATLAS_FILE, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Atlas texture path \
initialization failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Atlas texture path initialized\n"));
  } while (false);

  return status;
}

void freePaths(Shaders* shaders, PNG* png, PNG* atlas, bool verbose)
{
  if (shaders->fshaderpath)
  {
    LOG(verbose, printf("Freeing fragment shader path ...\n"));
    free(shaders->fshaderpath);
    shaders->fshaderpath = NULL;
    LOG(verbose, printf("fragment shader path freed\n"));
  }

  if (shaders->vshaderpath)
  {
    LOG(verbose, printf("Freeing vertex shader path ...\n"));
    free(shaders->vshaderpath);
    shaders->vshaderpath = NULL;
    LOG(verbose, printf("Vertex shader path freed\n"));
  }

  if (png->path)
  {
    LOG(verbose, printf("Freeing texture path ...\n"));
    free(png->path);
    png->path = NULL;
    LOG(verbose, printf("Texture path freed\n"));
  }

  if (atlas->path)
  {
    LOG(verbose, printf("Freeing atlas texture path ...\n"));
    free(atlas->path);
    atlas->path = NULL;
    LOG(verbose, printf("Atlas texture path freed\n"));
  }
}
