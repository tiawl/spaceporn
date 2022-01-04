#include "options.h"

void help()
{
  fprintf(stderr, "\n%s v%s\n", NAME, VERSION);
  fprintf(stderr,
    "\nUsage: %s [%s] [%s FPS] [%s] [%s MINS] [%s] [%s PIXELS] [%s ZOOM]\n\
  [%s] [%s ROADMAP]\n\n", NAME, ANIMATION_FLAG, FPS_FLAG, CAMERAMOTION_FLAG,
  SLIDE_FLAG, PALETTES_FLAG, PIXEL_FLAG, ZOOM_FLAG, VERBOSE_FLAG, ROADMAP_FLAG);
  fprintf(stderr, "User options:\n\n\
    %s  Enable shader animations.\n\n\
    %s  Frames per second between %d to %d.\n\
        [default: %d]\n\n\
    %s  Enable camera motion.\n\n\
    %s  Enable usage of unique palette for each object.\n\n\
    %s  Enable slide mode: disable %s flag, disable %s flag, disable %s\n\
        flag and generate a new background every MINS minutes. Reduce\n\
        CPU and GPU usages.\n\n\
    %s  Pixelization value between %d to %d.\n\
        [default: %d]\n\n\
    %s  Zoom value between %d to %d.\n\
        [default: %d]\n\n", ANIMATION_FLAG, FPS_FLAG, MIN_FPS, MAX_FPS,
        DEFAULT_FPS, CAMERAMOTION_FLAG, PALETTES_FLAG, SLIDE_FLAG,
        ANIMATION_FLAG, FPS_FLAG, CAMERAMOTION_FLAG, PIXEL_FLAG, MIN_PIXELS,
        MAX_PIXELS, DEFAULT_PIXELS, ZOOM_FLAG, MIN_ZOOM, MAX_ZOOM,
        DEFAULT_ZOOM);
  fprintf(stderr, "Debug options:\n\n\
    %s  Verbose mode.\n\n\
    %s  Run the corresponding predefined execution roadmap.\n\
        [default: 0]\n\n", VERBOSE_FLAG, ROADMAP_FLAG);
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
    } else if ((strcmp(argv[i], FPS_FLAG) == 0) &&
      (uniform_values->slide == 0)) {
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
    } else if (strcmp(argv[i], SLIDE_FLAG) == 0) {
      if (++i < *argc)
      {
        uniform_values->slide = atoi(argv[i]);
        if (uniform_values->slide <= 0)
        {
          help();
          return false;
        }
        uniform_values->animations = false;
        uniform_values->motion = false;
        *fps = 0;
      }
    } else if ((strcmp(argv[i], ANIMATION_FLAG) == 0) &&
      (uniform_values->slide == 0)) {
        uniform_values->animations = true;
    } else if ((strcmp(argv[i], CAMERAMOTION_FLAG) == 0) &&
      (uniform_values->slide == 0)) {
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
