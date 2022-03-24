#include "path.h"

bool initPath(char** path, size_t len[2], char* root, char* dir, Log* log)
{
  int status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "", "    Allocating memory for path ...\n");

    if (log->roadmap.id != PATH_MALLOC_FAILED_RM)
    {
      *path = malloc(len[0] + len[1] + 1);
    }

    if (!(*path))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "path malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "",
      "    Successful allocated memory for path\n");

    writeLog(log, stdout, DEBUG, "", "    Building path string ... 0/2\n");
    memcpy(*path, root, len[0]);
    writeLog(log, stdout, DEBUG, "", "    Building path string ... 1/2\n");
    memcpy(*path + len[0], dir, len[1] + 1);
    writeLog(log, stdout, DEBUG, "", "    Building path string ... 2/2\n");
    writeLog(log, stdout, INFO, "", "    Path string built: %s\n", *path);
  } while (false);

  return status;
}

bool initPaths(Shaders* shaders, PNG* atlas, Log* log)
{
  int status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "",
      "  Computing length of shaders directory path ...\n");
    const size_t len1 = strlen(SHADERS_DIR);
    writeLog(log, stdout, DEBUG, "", "  Length of \"%s\" is %lu\n",
      SHADERS_DIR, len1);

    writeLog(log, stdout, DEBUG, "",
      "  Computing length of textures directory path ...\n");
    const size_t len2 = strlen(TEXTURES_DIR);
    writeLog(log, stdout, DEBUG, "", "  Length of \"%s\" is %lu\n",
      TEXTURES_DIR, len2);

    writeLog(log, stdout, DEBUG, "",
      "  Computing length of fragment shader directory ...\n");
    const size_t len3 = strlen(FRAGMENT_DIR);
    writeLog(log, stdout, DEBUG, "", "  Length of \"%s\" is %lu\n",
      FRAGMENT_DIR, len3);

    writeLog(log, stdout, DEBUG, "",
      "  Computing length of vertex shader directory ...\n");
    const size_t len4 = strlen(VERTEX_DIR);
    writeLog(log, stdout, DEBUG, "", "  Length of \"%s\" is %lu\n",
      VERTEX_DIR, len4);

    writeLog(log, stdout, DEBUG, "",
      "  Computing length of shader main filename ...\n");
    const size_t len5 = strlen(MAIN_FILE);
    writeLog(log, stdout, DEBUG, "", "  Length of \"%s\" is %lu\n", MAIN_FILE,
      len5);

    writeLog(log, stdout, DEBUG, "",
      "  Computing length of atlas filename ...\n");
    const size_t len6 = strlen(ATLAS_FILE);
    writeLog(log, stdout, DEBUG, "", "  Length of \"%s\" is %lu\n",
      ATLAS_FILE, len6);

    size_t length[2] =
    {
      len1, len3
    };

    writeLog(log, stdout, DEBUG, "",
      "  Initializing fragment shader directory path ...\n");
    if (!initPath(&(shaders->fshaderdir), length, SHADERS_DIR, FRAGMENT_DIR,
      log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Fragment shader directory path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "",
      "  Fragment shader directory path initialized\n");

    length[0] = len1 + len3;
    length[1] = len5;

    if (log->roadmap.id == FSHADERPATH_MALLOC_FAILED_RM)
    {
      log->roadmap.id = PATH_MALLOC_FAILED_RM;
    }

    writeLog(log, stdout, DEBUG, "",
      "  Initializing fragment shader path ...\n");
    if (!initPath(&(shaders->fshaderpath), length, shaders->fshaderdir,
      MAIN_FILE, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Fragment shader path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Fragment shader path initialized\n");

    length[0] = len1;
    length[1] = len4;

    if (log->roadmap.id == VSHADERDIR_MALLOC_FAILED_RM)
    {
      log->roadmap.id = PATH_MALLOC_FAILED_RM;
    }

    writeLog(log, stdout, DEBUG, "",
      "  Initializing vertex shader directory path ...\n");
    if (!initPath(&(shaders->vshaderdir), length, SHADERS_DIR, VERTEX_DIR,
      log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Vertex shader directory path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "",
      "  Vertex shader directory path initialized\n");

    length[0] = len1 + len4;
    length[1] = len5;

    if (log->roadmap.id == VSHADERPATH_MALLOC_FAILED_RM)
    {
      log->roadmap.id = PATH_MALLOC_FAILED_RM;
    }

    writeLog(log, stdout, DEBUG, "", "  Initializing vertex shader path ...\n");
    if (!initPath(&(shaders->vshaderpath), length, shaders->vshaderdir,
      MAIN_FILE, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Vertex shader path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Vertex shader path initialized\n");

    length[0] = len2;
    length[1] = len6;

    if (log->roadmap.id == ATLASTEXTUREPATH_MALLOC_FAILED_RM)
    {
      log->roadmap.id = PATH_MALLOC_FAILED_RM;
    }

    writeLog(log, stdout, DEBUG, "", "  Initializing atlas texture path ...\n");
    if (!initPath(&(atlas->path), length, TEXTURES_DIR, ATLAS_FILE, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Atlas texture path initialization failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Atlas texture path initialized\n");
  } while (false);

  return status;
}
