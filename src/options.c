#include "options.h"

void help()
{
  fprintf(stderr, "\n%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-f FPS] [-m] [-p] [-x PIXELS] [-z ZOOM]\n\
  [-V] [-R ROADMAP]\n\n", NAME);
  fprintf(stderr, "User options:\n\n\
    -a  Enable shader animations\n\n\
    -f  Frame per second between %d to %d (ex: -f 10)\n\
        [default: %d]\n\n\
    -m  Enable camera motion\n\n\
    -p  Enable usage of multiple palettes\n\n\
    -x  Pixelization value between %d to %d (ex: -x 300)\n\
        [default: %d]\n\n\
    -z  Zoom value between %d to %d (ex: -z 25)\n\
        [default: %d]\n\n", MIN_FPS, MAX_FPS, DEFAULT_FPS, MIN_PIXELS,
        MAX_PIXELS, DEFAULT_PIXELS, MIN_ZOOM, MAX_ZOOM, DEFAULT_ZOOM);
  fprintf(stderr, "Dev options:\n\n\
    -V  Verbose mode\n\n\
    -R  Run the corresponding predefined execution roadmap (ex: -R 0)\n\
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
    } else if (strcmp(argv[i], ZOOM_FLAG) == 0) {
      if (++i < *argc)
      {
        uniform_values->zoom = atoi(argv[i]);
        if ((uniform_values->zoom < MIN_ZOOM) ||
          (uniform_values->zoom > MAX_ZOOM))
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
