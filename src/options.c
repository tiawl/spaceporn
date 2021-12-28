#include "options.h"

void help()
{
  fprintf(stderr, "\n%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-m] [-p] [-x PIXELS] [-d MICROS] \
[-V] [-R ROADMAP]\n\n", NAME);
  fprintf(stderr, "User options:\n\n\
    -a  Enable shader animations\n\n\
    -f  Frame per second between 1 to 60 (ex: -f 10) [default: 30]\n\n\
    -m  Enable camera motion\n\n\
    -p  Enable usage of multiple palettes\n\n\
    -x  Pixelization value between 100 to 600 (ex: -x 300) [default: 500]\n\n");
  fprintf(stderr, "Dev options:\n\n\
    -V  Verbose mode\n\n\
    -R  Run the corresponding predefined execution roadmap. Dev flag \n\
        purposes (ex: -R 0)\n\
        [default: 0]\n\n");
}

bool parsing_options(bool* verbose, int* fps, UniformValues* uniform_values,
  Roadmap* roadmap, int* argc, char** argv)
{
  roadmap->glsl_file = "";

  for (int i = 1; i < *argc; i++)
  {
    if (strcmp(argv[i], PIXEL_FLAG) == 0)
    {
      if (++i < *argc)
      {
        uniform_values->pixels = atof(argv[i]);
        if ((uniform_values->pixels > MAX_PIXELS) ||
          (uniform_values->pixels < MIN_PIXELS))
        {
          help();
          return false;
        }
      }
    } else if (strcmp(argv[i], FPS_FLAG) == 0) {
      if (++i < *argc)
      {
        *fps = atoi(argv[i]);
        if ((*fps < MIN_FPS) || (*fps > MAX_FPS))
        {
          help();
          return false;
        }
      }
    } else if (strcmp(argv[i], ANIMATION_FLAG) == 0) {
      uniform_values->animations = true;
    } else if (strcmp(argv[i], CAMERAMOTION_FLAG) == 0) {
      uniform_values->motion = true;
    } else if (strcmp(argv[i], PALETTES_FLAG) == 0) {
      uniform_values->palettes = true;
    } else if (strcmp(argv[i], VERBOSE_FLAG) == 0) {
      *verbose = true;
    } else if (strcmp(argv[i], ROADMAP_FLAG) == 0) {
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
                  return false;
                }
                strcpy(dir, SHADERS_DIR);
                strcat(dir, VERTEX_DIR);
              } else {
                dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                  strlen(FRAGMENT_DIR) + strlen(argv[i]) + 1));
                if (!dir)
                {
                  fprintf(stderr, "malloc() failed when parsing options.\n");
                  return false;
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
