#include "options.h"

void help()
{
  fprintf(stderr, "\n%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-m] [-p] [-x PIXELS] [-d MICROS] \
[-V] [-R ROADMAP]\n\n", NAME);
  fprintf(stderr, "User options:\n\n\
    -a  Enable shader animations\n\n\
    -m  Enable camera motion\n\n\
    -p  Enable multiple colorschemes\n\n\
    -x  Pixels value between 100 to 600 (ex: -x 300) [default: 500]\n\n\
    -d  Delay value between each frame in microseconds (ex: -d 0)\n\
        [default: 30000]\n\n");
  fprintf(stderr, "Dev options:\n\n\
    -V  Verbose mode\n\n\
    -R  Run the corresponding predefined execution roadmap. Dev flag \n\
        purposes (ex: -R 0)\n\
        [default: 0]\n\n");
}

bool parsing_options(bool* verbose, int* delay, UniformValues* uniform_values,
  Roadmap* roadmap, int* argc, char** argv)
{
  roadmap->glsl_file = "";

  for (int i = 1; i < *argc; i++)
  {
    if (strcmp(argv[i], "-x") == 0)
    {
      if (++i < *argc)
      {
        uniform_values->pixels = atof(argv[i]);
        if ((uniform_values->pixels > 600.) ||
          (uniform_values->pixels < 100.))
        {
          help();
          return false;
        }
      }
    } else if (strcmp(argv[i], "-d") == 0) {
      if (++i < *argc)
      {
        *delay = atoi(argv[i]);
        if (*delay < 0)
        {
          help();
          return false;
        }
      }
    } else if (strcmp(argv[i], "-a") == 0) {
      uniform_values->animations = true;
    } else if (strcmp(argv[i], "-m") == 0) {
      uniform_values->motion = true;
    } else if (strcmp(argv[i], "-p") == 0) {
      uniform_values->palettes = true;
    } else if (strcmp(argv[i], "-V") == 0) {
      *verbose = true;
    } else if (strcmp(argv[i], "-R") == 0) {
      if (++i < *argc)
      {
        roadmap->id = atoi(argv[i]);
        if ((roadmap->id < EXIT_SUCCESS_RM) || (roadmap->id >= RM_NB))
        {
          help();
          return false;
        } else {
          if ((roadmap->id >= 35) && (roadmap->id <= 60))
          {
            if (++i < *argc)
            {
              char* dir = NULL;
              if (roadmap->id < 48)
              {
                dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                  strlen(VERTEX_DIR) + strlen(argv[i]) + 1));
                if (!dir)
                {
                  fprintf(stderr, "malloc() failed when parsing options.\n");
                }
                strcpy(dir, SHADERS_DIR);
                strcat(dir, VERTEX_DIR);
              } else {
                dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                  strlen(FRAGMENT_DIR) + strlen(argv[i]) + 1));
                if (!dir)
                {
                  fprintf(stderr, "malloc() failed when parsing options.\n");
                }
                strcpy(dir, SHADERS_DIR);
                strcat(dir, FRAGMENT_DIR);
              }
              strcat(dir, argv[i]);
              if (access(dir, F_OK) == 0)
              {
                free(dir);
                roadmap->glsl_file = argv[i];
              } else {
                fprintf(stderr, "%s does not exist\n", dir);
                free(dir);
                return false;
              }
            } else {
              fprintf(stderr, "This roadmap needs a file\n");
              return false;
            }
          }
        }
      }
    } else {
      help();
      return false;
    }
  }

  return true;
}
