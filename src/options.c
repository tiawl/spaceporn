#include "options.h"

void help()
{
  fprintf(stderr, "\n%s %s\n", NAME, VERSION);
  fprintf(stderr,
    "\nUsage: %s [%s] [%s] [%s [WIDTHxHEIGHT]] [%s] [%s] [%s FPS] [%s MINS]\n\
    [%s] [%s PIXELS] [%s ZOOM] [%s] [%s ROADMAP] [%s] [%s] [%s]\n\n", NAME,
  ANIMATION_FLAG, ATLASFORCED_FLAG, PICGEN_FLAG, CAMERAMOTION_FLAG,
  PALETTES_FLAG, FPS_FLAG, STOP_FLAG, SLIDE_FLAG, PIXEL_FLAG, ZOOM_FLAG,
  VERBOSE_FLAG, ROADMAP_FLAG, MAXROADMAP_FLAG, VERTEXFILEROADMAPS_FLAG,
  FRAGMENTFILEROADMAPS_FLAG);
  fprintf(stderr, "User options:\n\n\
  %s  Enable shader animations. Enable Video mode.\n\n\
  %s  Force precomputed texture generation.\n\n\
  %s  Generate background in PNG format and exit. WIDTH and HEIGHT can be\n\
      specified in this format: WIDTHxHEIGHT. If WIDTH and HEIGHT are not\n\
      specified, screen dimensions are used. It disables %s, %s, %s and %s\n\
      flags.\n\n\
  %s  Enable camera motion. Enable Video mode.\n\n\
  %s  Enable usage of unique palette for each object.\n\n\
  %s  Frames per second between %d to %d. Enable Video mode.\n\
      [default: %d]\n\n\
  %s  Enable Slide mode: generate new static wallpaper every MINS\n\
      minutes. It disables %s, %s and %s flags.\n\n\
  %s  Generate precomputed texture and exit. It disables %s, %s, %s and \n\
      %s flags.\n\n\
  %s  Pixelization value between %d to %d.\n\
      [default: random]\n\n\
  %s  Zoom value between %d to %d.\n\
      [default: random]\n\n", ANIMATION_FLAG, ATLASFORCED_FLAG, PICGEN_FLAG,
      ANIMATION_FLAG, CAMERAMOTION_FLAG, FPS_FLAG, SLIDE_FLAG,
      CAMERAMOTION_FLAG, PALETTES_FLAG, FPS_FLAG, MIN_FPS, MAX_FPS,
      DEFAULT_FPS, SLIDE_FLAG, ANIMATION_FLAG, CAMERAMOTION_FLAG, FPS_FLAG,
      STOP_FLAG, ANIMATION_FLAG, CAMERAMOTION_FLAG, FPS_FLAG, SLIDE_FLAG,
      PIXEL_FLAG, MIN_PIXELS, MAX_PIXELS, ZOOM_FLAG, MIN_ZOOM, MAX_ZOOM);
  fprintf(stderr, "Debug options:\n\n\
  %s  Verbose mode.\n\n\
  %s  Run the corresponding execution roadmap.\n\
      [default: 0]\n\n\
  %s  Print last roadmap.\n\n\
  %s  Print first and last roadmaps which need a vertex shader\n\
      file as argument.\n\n\
  %s  Print first and last roadmaps which need a fragment shader\n\
      file as argument.\n\n", VERBOSE_FLAG, ROADMAP_FLAG, MAXROADMAP_FLAG,
      VERTEXFILEROADMAPS_FLAG, FRAGMENTFILEROADMAPS_FLAG);
}

bool parsing_options(long* fps, bool* generation, unsigned* width,
  unsigned* height, UniformValues* uniform_values, Log* log, int* argc,
  char** argv)
{
  int status = true;
  char* dir = NULL;

  do
  {
    errno = 0;
    char* end;
    log->roadmap.glsl_file = "";

    if (*argc <= 1)
    {
      help();
      status = false;
      break;
    }

    for (int i = 1; i < *argc; i++)
    {
      if ((strcmp(argv[i], ANIMATION_FLAG) == 0) &&
        (uniform_values->slide == 0))
      {
        uniform_values->animations = true;
      } else if (strcmp(argv[i], ATLASFORCED_FLAG) == 0) {
        generation = true;
      } else if (strcmp(argv[i], PICGEN_FLAG) == 0) {
      } else if ((strcmp(argv[i], CAMERAMOTION_FLAG) == 0) &&
        (uniform_values->slide == 0)) {
          uniform_values->motion = true;
      } else if (strcmp(argv[i], PALETTES_FLAG) == 0) {
        uniform_values->palettes = true;
      } else if ((strcmp(argv[i], FPS_FLAG) == 0) &&
        (uniform_values->slide == 0)) {
          if (++i < *argc)
          {
            *fps = strtol(argv[i], &end, 10);
            if (argv[i] == end)
            {
              fprintf(stderr,
                "Unrecognized character in %s option parameter.\n",
                FPS_FLAG);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr,
                "Range error occurred during %s option parsing.\n",
                FPS_FLAG);
              status = false;
              break;
            }
            if ((*fps < MIN_FPS) || (*fps > MAX_FPS))
            {
              help();
              status = false;
              break;
            }
          }
      } else if (strcmp(argv[i], SLIDE_FLAG) == 0) {
        if (++i < *argc)
        {
          uniform_values->slide = strtol(argv[i], &end, 10);
          if (argv[i] == end)
          {
            fprintf(stderr,
              "Unrecognized character in %s option parameter.\n",
              SLIDE_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n",
              SLIDE_FLAG);
            status = false;
            break;
          }
          if (uniform_values->slide <= 0)
          {
            help();
            status = false;
            break;
          }
          uniform_values->animations = false;
          uniform_values->motion = false;
          *fps = 0;
        }
      } else if (strcmp(argv[i], STOP_FLAG) == 0) {
      } else if (strcmp(argv[i], PIXEL_FLAG) == 0) {
        if (++i < *argc)
        {
          uniform_values->pixels = strtol(argv[i], &end, 10);
          if (argv[i] == end)
          {
            fprintf(stderr,
              "Unrecognized character in %s option parameter.\n",
              PIXEL_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n",
              PIXEL_FLAG);
            status = false;
            break;
          }
          if ((uniform_values->pixels > MAX_PIXELS) ||
            (uniform_values->pixels < MIN_PIXELS))
          {
            help();
            status = false;
            break;
          }
        }
      } else if (strcmp(argv[i], ZOOM_FLAG) == 0) {
        if (++i < *argc)
        {
          uniform_values->zoom = strtol(argv[i], &end, 10);
          if (argv[i] == end)
          {
            fprintf(stderr,
              "Unrecognized character in %s option parameter.\n",
              ZOOM_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n",
              ZOOM_FLAG);
            status = false;
            break;
          }
          if ((uniform_values->zoom < MIN_ZOOM) ||
            (uniform_values->zoom > MAX_ZOOM))
          {
            help();
            status = false;
            break;
          }
        }
      } else if (strcmp(argv[i], VERBOSE_FLAG) == 0) {
        log->verbose = true;
      } else if (strcmp(argv[i], ROADMAP_FLAG) == 0) {
        if (++i < *argc)
        {
          log->roadmap.id = strtol(argv[i], &end, 10);
          if (argv[i] == end)
          {
            fprintf(stderr,
              "Unrecognized character in %s option parameter.\n",
              ROADMAP_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n",
              ROADMAP_FLAG);
            status = false;
            break;
          }
          if ((log->roadmap.id < EXIT_SUCCESS_RM) || (log->roadmap.id >= RM_NB))
          {
            help();
            status = false;
            break;
          } else {
            if ((log->roadmap.id >= VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM) &&
              (log->roadmap.id <= FRAGMENT_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM))
            {
              if (++i < *argc)
              {
                if (log->roadmap.id < FRAGMENT_FILE_SARH_HEADER_MALLOC_FAILED_RM)
                {
                  dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                    strlen(VERTEX_DIR) + strlen(argv[i]) + 1));
                  if (!dir)
                  {
                    fprintf(stderr, "malloc() failed when parsing options.\n");
                    status = false;
                    break;
                  }
                  strcpy(dir, SHADERS_DIR);
                  strcat(dir, VERTEX_DIR);
                } else {
                  dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                    strlen(FRAGMENT_DIR) + strlen(argv[i]) + 1));
                  if (!dir)
                  {
                    fprintf(stderr, "malloc() failed when parsing options.\n");
                    status = false;
                    break;
                  }
                  strcpy(dir, SHADERS_DIR);
                  strcat(dir, FRAGMENT_DIR);
                }
                strcat(dir, argv[i]);
                if (access(dir, F_OK) == 0)
                {
                  log->roadmap.glsl_file = argv[i];
                } else {
                  fprintf(stderr, "%s does not exist\n", dir);
                  status = false;
                  break;
                }
              } else {
                fprintf(stderr, "This roadmap needs a file\n");
                status = false;
                break;
              }
            }
          }
        }
      } else if (strcmp(argv[i], MAXROADMAP_FLAG) == 0) {
#if DEV
        printf("%d\n", RM_NB - 2);
#else
        printf("%d\n", RM_NB - 1);
#endif
        status = false;
        break;
      } else if (strcmp(argv[i], VERTEXFILEROADMAPS_FLAG) == 0) {
        printf("%d %d\n", VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM,
          VERTEX_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM);
        status = false;
        break;
      } else if (strcmp(argv[i], FRAGMENTFILEROADMAPS_FLAG) == 0) {
        printf("%d %d\n", FRAGMENT_FILE_SARH_HEADER_MALLOC_FAILED_RM,
          FRAGMENT_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM);
        status = false;
        break;
      } else {
        help();
        status = false;
        break;
      }
    }
  } while (false);

  if (dir != NULL)
  {
    free(dir);
  }

//   if (log->roadmap.id == SLIDEMODE_SUCCESS_RM)
//   {
//     uniform_values->slide = 1;
//     uniform_values->animations = false;
//     uniform_values->motion = false;
//     *fps = 0;
//     *generation = false;
//   } else if ((log->roadmap.id >= ATLASTEXTUREPATH_MALLOC_FAILED_RM) &&
//     (log->roadmap.id <= BAD_ATLASPNG_DIMENSIONS_RM)) {
//       *generation = 0;
//       uniform_values->slide = 0;
//       *width = UNDEFINED_SIZE;
//       *height = UNDEFINED_SIZE;
//   } else if (log->roadmap.id == PRECOMPUTE_AND_STOP_RM) {
//     *generation = 1;
//     uniform_values->slide = 0;
//     *width = UNDEFINED_SIZE;
//     *height = UNDEFINED_SIZE;
//   } else if (log->roadmap.id == PRECOMPUTE_AND_CONTINUE_RM) {
//     *generation = 0;
//     uniform_values->slide = 0;
//     *width = UNDEFINED_SIZE;
//     *height = UNDEFINED_SIZE;
//     log->roadmap.id = BREAK_SUCCESS_RM;
//   }

  uniform_values->zoom /= 100.;

  return status;
}
