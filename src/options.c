#include "options.h"

void help()
{
  fprintf(stderr, "\n%s %s\n", NAME, VERSION);
  fprintf(stderr,
    "\nUsage: %s %s LEVEL|%s [WIDTHxHEIGHT]|%s MINS [%s] [%s] [%s FPS] \n\
    [%s] [%s PIXELS] [%s ZOOM] [%s] [%s] [%s ROADMAP] [%s] [%s]\n\n", NAME,
  ANIMATION_FLAG, BGGEN_FLAG, SLIDE_FLAG, ATLASFORCED_FLAG, PALETTES_FLAG,
  FPS_FLAG, STOP_FLAG, PIXEL_FLAG, ZOOM_FLAG, FRAGMENTFILEROADMAPS_FLAG,
  MAXROADMAP_FLAG, ROADMAP_FLAG, VERTEXFILEROADMAPS_FLAG, VERBOSE_FLAG);
  fprintf(stderr, "User options:\n\n\
  %s  Enable Animation mode: display animated wallpaper. If LEVEL is 0,\n\
      camera motion and animations are enabled, 1 disables camera motion, 2\n\
      disables animations. Exit in error if called with %s or %s flags.\n\n\
  %s  Enable Generation mode: generate background in PNG format and exit.\n\
      WIDTH and HEIGHT can be specified in this format: WIDTHxHEIGHT. If\n\
      WIDTH and HEIGHT are not specified, screen dimensions are used. Exit\n\
      in error if called with %s or %s flags.\n\n\
  %s  Enable Slide mode: display new static wallpaper every MINS minutes.\n\
      Exit in error if called with %s or %s flags.\n\n\
  %s  Force new seed generation.\n\n\
  %s  Enable usage of unique palette for each object.\n\n\
  %s  Frames per second between %d to %d. Animation mode option.\n\
      [default: %d]\n\n\
  %s  Run without using a mode and exit. Useful with %s flag.\n\n\
  %s  Pixelization value between %d to %d.\n\
      [default: random]\n\n\
  %s  Zoom value between %d to %d.\n\
      [default: random]\n\n", ANIMATION_FLAG, BGGEN_FLAG, SLIDE_FLAG,
      BGGEN_FLAG, ANIMATION_FLAG, SLIDE_FLAG, SLIDE_FLAG, ANIMATION_FLAG,
      BGGEN_FLAG, ATLASFORCED_FLAG, PALETTES_FLAG, FPS_FLAG, MIN_FPS, MAX_FPS,
      DEFAULT_FPS, STOP_FLAG, ATLASFORCED_FLAG, PIXEL_FLAG, MIN_PIXELS,
      MAX_PIXELS, ZOOM_FLAG, MIN_ZOOM, MAX_ZOOM);
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
      status = false;
      break;
    }

    for (int i = 1; i < *argc; i++)
    {
      if (strcmp(argv[i], ANIMATION_FLAG) == 0)
        if (uniform_values->mode < ANIM_MOTION_MODE)
        {
          if (++i < *argc)
          {
            uniform_values->mode = strtol(argv[i], &end, 10);
            if (argv[i] == end)
            {
              fprintf(stderr, "Unrecognized character in %s option"
                " parameter.\n", ANIMATION_FLAG);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr, "Range error occurred during %s option"
                " parsing.\n", ANIMATION_FLAG);
              status = false;
              break;
            }
            if ((uniform_values->mode < ANIM_MOTION_MODE) ||
              (uniform_values->mode > MOTION_MODE))
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
      {
      } else if (strcmp(argv[i], BGGEN_FLAG) == 0) {
      } else if (strcmp(argv[i], ATLASFORCED_FLAG) == 0) {
        *generation = true;
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
                "Unrecognized character in %s option parameter.\n", FPS_FLAG);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr,
                "Range error occurred during %s option parsing.\n", FPS_FLAG);
              status = false;
              break;
            }
            if ((*fps < MIN_FPS) || (*fps > MAX_FPS))
            {
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
              "Unrecognized character in %s option parameter.\n", SLIDE_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n", SLIDE_FLAG);
            status = false;
            break;
          }
          if (uniform_values->slide <= 0)
          {
            status = false;
            break;
          }
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
              "Unrecognized character in %s option parameter.\n", PIXEL_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n", PIXEL_FLAG);
            status = false;
            break;
          }
          if ((uniform_values->pixels > MAX_PIXELS) ||
            (uniform_values->pixels < MIN_PIXELS))
          {
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
              "Unrecognized character in %s option parameter.\n", ZOOM_FLAG);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr,
              "Range error occurred during %s option parsing.\n", ZOOM_FLAG);
            status = false;
            break;
          }
          if ((uniform_values->zoom < MIN_ZOOM) ||
            (uniform_values->zoom > MAX_ZOOM))
          {
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
        status = false;
        break;
      }
    }
  } while (false);

  if (!status)
  {
    help();
  }

  if (dir != NULL)
  {
    free(dir);
  }

//   if (log->roadmap.id == SLIDEMODE_SUCCESS_RM)
//   {
//     uniform_values->slide = 1;
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
