#include "path.h"

bool initShaderPath(char** path, size_t len[3], char* dir, Log* log)
{
  int status = true;

  do
  {
    writeLog(log, stdout, "", "    Allocating memory for shader path ...\n");
    if (log->roadmap.id != SHADERPATH_MALLOC_FAILED_RM)
    {
      *path = malloc(len[0] + len[1] + len[2] + 1);
    }

    if (!(*path))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "shader path malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "",
      "    Successful allocated memory for shader path\n");

    writeLog(log, stdout, "", "    Building shader path string ... 0/3\n");
    memcpy(*path, SHADERS_DIR, len[0]);
    writeLog(log, stdout, "", "    Building shader path string ... 1/3\n");
    memcpy(*path + len[0], dir, len[1]);
    writeLog(log, stdout, "", "    Building shader path string ... 2/3\n");
    memcpy(*path + len[0] + len[1], MAIN_FILE, len[2] + 1);
    writeLog(log, stdout, "", "    Building shader path string ... 3/3\n");
    writeLog(log, stdout, "", "    Shader path string built: %s\n", *path);
  } while (false);

  return status;
}

bool initTexturePath(PNG* png, size_t len[3], char* path, Log* log)
{
  int status = true;

  do
  {
    writeLog(log, stdout, "", "    Allocating memory for texture path ...\n");

    if (log->roadmap.id != TEXTUREPATH_MALLOC_FAILED_RM)
    {
      png->path = malloc(len[0] + len[1] + 1);
    }

    if (!png->path)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "texture path malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "",
      "    Successful allocated memory for texture path\n");

    writeLog(log, stdout, "", "    Building texture path string ... 0/2\n");
    memcpy(png->path, TEXTURES_DIR, len[0]);
    writeLog(log, stdout, "", "    Building texture path string ... 1/2\n");
    memcpy(png->path + len[0], path, len[1] + 1);
    writeLog(log, stdout, "", "    Building texture path string ... 2/2\n");
    writeLog(log, stdout, "", "    Texture path string built: %s\n", png->path);
  } while (false);

  return status;
}

bool initLogPath(Log* log)
{
  int status = true;

  writeLog(log, stdout, "", "  Computing length of log directory path ...\n");
  const size_t len1 = strlen(LOG_DIR);
  writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", LOG_DIR, len1);

  writeLog(log, stdout, "", "  Computing length of log filename ...\n");
  const size_t len2 = strlen(NAME);
  writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", NAME, len2);

  do
  {
    writeLog(log, stdout, "", "  Allocating memory for log path ...\n");

    if (log->roadmap.id != LOGPATH_MALLOC_FAILED_RM)
    {
      log->path = malloc(len1 + len2 + 1);
    }

    if (!log->path)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "log path malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Successful allocated memory for log path\n");

    writeLog(log, stdout, "", "  Building log path string ... 0/2\n");
    memcpy(log->path, LOG_DIR, len1);
    writeLog(log, stdout, "", "  Building log path string ... 1/2\n");
    memcpy(log->path + len1, NAME, len2 + 1);
    writeLog(log, stdout, "", "  Building log path string ... 2/2\n");
    writeLog(log, stdout, "", "  Log path string built: %s\n", log->path);
  } while (false);

  return status;
}

bool initPaths(Shaders* shaders, PNG* png, PNG* atlas, Log* log)
{
  int status = true;

  do
  {
    writeLog(log, stdout, "",
      "  Computing length of shaders directory path ...\n");
    const size_t len1 = strlen(SHADERS_DIR);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", SHADERS_DIR, len1);

    writeLog(log, stdout, "",
      "  Computing length of textures directory path ...\n");
    const size_t len2 = strlen(TEXTURES_DIR);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", TEXTURES_DIR,
      len2);

    writeLog(log, stdout, "",
      "  Computing length of fragment shader directory ...\n");
    const size_t len3 = strlen(FRAGMENT_DIR);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", FRAGMENT_DIR,
      len3);

    writeLog(log, stdout, "",
      "  Computing length of vertex shader directory ...\n");
    const size_t len4 = strlen(VERTEX_DIR);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", VERTEX_DIR, len4);

    writeLog(log, stdout, "",
      "  Computing length of shader main filename ...\n");
    const size_t len5 = strlen(MAIN_FILE);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", MAIN_FILE, len5);

    writeLog(log, stdout, "", "  Computing length of texture filename ...\n");
    const size_t len6 = strlen(BIGSTARS_FILE);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", BIGSTARS_FILE,
      len6);

    writeLog(log, stdout, "", "  Computing length of atlas filename ...\n");
    const size_t len7 = strlen(ATLAS_FILE);
    writeLog(log, stdout, "", "  Length of \"%s\" is %lu\n", ATLAS_FILE, len7);

    size_t length[3] =
    {
      len1, len3, len5,
    };

    writeLog(log, stdout, "", "  Initializing fragment shader path ...\n");
    if (!initShaderPath(&(shaders->fshaderpath), length, FRAGMENT_DIR, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Fragment shader path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Fragment shader path initialized\n");

    length[1] = len4;

    if (log->roadmap.id == VSHADERPATH_MALLOC_FAILED_RM)
    {
      log->roadmap.id = SHADERPATH_MALLOC_FAILED_RM;
    }

    writeLog(log, stdout, "", "  Initializing vertex shader path ...\n");
    if (!initShaderPath(&(shaders->vshaderpath), length, VERTEX_DIR, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Vertex shader path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Vertex shader path initialized\n");

    length[0] = len2;
    length[1] = len6;
    length[2] = 0;

    writeLog(log, stdout, "", "  Initializing texture path ...\n");
    if (!initTexturePath(png, length, BIGSTARS_FILE, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Texture path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Texture path initialized\n");

    length[1] = len7;

    if (log->roadmap.id == ATLASTEXTUREPATH_MALLOC_FAILED_RM)
    {
      log->roadmap.id = TEXTUREPATH_MALLOC_FAILED_RM;
    }

    writeLog(log, stdout, "", "  Initializing atlas texture path ...\n");
    if (!initTexturePath(atlas, length, ATLAS_FILE, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Atlas texture path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Atlas texture path initialized\n");
  } while (false);

  return status;
}
