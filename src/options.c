#include "options.h"

void help()
{
  fprintf(stderr, "\n%s %s %s\n", NAME, VERSION, BRANCH);
  fprintf(stderr,
    "\nUsage: %s %s ANIM|%s [WIDTHxHEIGHT]|%s [MINS] [%s COLOR] [%s] \n\
    [%s FPS] [%s] [%s PIXELS] [%s ZOOM] [%s] [%s] [%s ROADMAP] [%s] [%s]\n\n",
    BIN_NAME, ANIMATION_FLAG, BGGEN_FLAG, SLIDE_FLAG, COLOR_FLAG,
    ATLASFORCED_FLAG, FPS_FLAG, STOP_FLAG, PIXEL_FLAG, ZOOM_FLAG,
    FRAGMENTFILEROADMAPS_FLAG, MAXROADMAP_FLAG, ROADMAP_FLAG,
    VERTEXFILEROADMAPS_FLAG, VERBOSE_FLAG);
  fprintf(stderr, "User options:\n\
  %s  Enable Animation mode: display animated wallpaper. Exit in error if\n\
      called with %s or %s flags. ANIM must be specified. Possible values:\n\
      - 1: camera motion and animations enabled,\n\
      - 2: camera motion disabled and animations enabled,\n\
      - 3: camera motion enables and animations disabled.\n\
  %s  Enable Generation mode: generate background in PNG format and exit.\n\
      WIDTH and HEIGHT can be specified in this format: WIDTHxHEIGHT. If\n\
      WIDTH and HEIGHT are not specified, screen dimensions are used. Exit\n\
      in error if called with %s or %s flags.\n\
  %s  Enable Slide mode: display new static wallpaper every MINS minutes.\n\
      If MINS is not specied, MINS is 1. Exit in error if called with %s or\n\
      %s flags.\n\
  %s  Color setting. COLOR must be specified. Possible values:\n\
      - 0: black and white,\n\
      - 1: static random monochromatic,\n\
      - 2: dynamic random monochromatic,\n\
      - 3: colorful.\n\
  %s  Force new seed generation. Only available for Animation and\n\
      Generation Mode.\n\
  %s  Frames per second between %d to %d. Animation mode option.\n\
      [default: %d]\n\
  %s  Run without using a mode and exit. Useful with %s flag.\n\
  %s  Pixelization value between %d to %d.\n\
      [default: random]\n\
  %s  Zoom value between %d to %d.\n\
      [default: random]\n\n", ANIMATION_FLAG, BGGEN_FLAG, SLIDE_FLAG,
      BGGEN_FLAG, ANIMATION_FLAG, SLIDE_FLAG, SLIDE_FLAG, ANIMATION_FLAG,
      BGGEN_FLAG, COLOR_FLAG, ATLASFORCED_FLAG, FPS_FLAG, MIN_FPS, MAX_FPS,
      DEFAULT_FPS, STOP_FLAG, ATLASFORCED_FLAG, PIXEL_FLAG, MIN_PIXELS,
      MAX_PIXELS, ZOOM_FLAG, MIN_ZOOM, MAX_ZOOM);
  fprintf(stderr, "Debug options:\n\
  %s  Verbose mode.\n\
  %s  Run the corresponding execution roadmap.\n\
      [default: 0]\n\
  %s  Print last roadmap.\n\
  %s  Print first and last roadmaps which need a vertex shader\n\
      file as argument.\n\
  %s  Print first and last roadmaps which need a fragment shader\n\
      file as argument.\n", VERBOSE_FLAG, ROADMAP_FLAG, MAXROADMAP_FLAG,
      VERTEXFILEROADMAPS_FLAG, FRAGMENTFILEROADMAPS_FLAG);
}

bool parsing_options(long* fps, bool* new_atlas, long* png_width,
  long* png_height, long* slide_delay, UniformValues* uniform_values,
  Log* log, int* argc, char** argv)
{
  int status = true;
  char* dir = NULL;

  do
  {
    errno = 0;
    char* end = NULL;
    char* new_start = NULL;
    log->roadmap.glsl_file = "";

    if (*argc <= 1)
    {
      status = false;
      break;
    }

    for (int i = 1; i < *argc; i++)
    {
      if (strcmp(argv[i], ANIMATION_FLAG) == 0)
      {
        if (uniform_values->mode < ANIM_MOTION_MODE)
        {
          if (++i < *argc)
          {
            uniform_values->mode = strtol(argv[i], &end, DECIMAL);
            if (argv[i] == end)
            {
              fprintf(stderr, "Unrecognized character in %s option"
                " parameter: %s\n", ANIMATION_FLAG, argv[i]);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr, "Range error occurred during %s option"
                " parameter parsing for: %s\n", ANIMATION_FLAG, argv[i]);
              status = false;
              break;
            }
            if ((uniform_values->mode < ANIM_MOTION_MODE) ||
              (uniform_values->mode > MOTION_MODE))
            {
              fprintf(stderr, "%s parameter should be 1, 2 or 3\n",
                ANIMATION_FLAG);
              status = false;
              break;
            }
          } else {
            fprintf(stderr, "%s option needs parameter\n", ANIMATION_FLAG);
            status = false;
            break;
          }
        } else if (uniform_values->mode != LOCKED) {
          fprintf(stderr, "%s mode already set. You can not use several"
            " modes.", (uniform_values->mode < SLIDE_MODE ?
              (uniform_values->mode < BGGEN_MODE ? "Animation" : "Generation")
                : "Slide"));
          status = false;
          break;
        }
      } else if (strcmp(argv[i], BGGEN_FLAG) == 0) {
        if (uniform_values->mode < ANIM_MOTION_MODE)
        {
          if (++i < *argc)
          {
            *png_width = strtol(argv[i], &end, DECIMAL);
            if (argv[i] == end)
            {
              fprintf(stderr, "Unrecognized character in %s option"
                " parameter: %s\n", BGGEN_FLAG, argv[i]);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr, "Range error occurred during %s option"
                " parameter parsing: %s\n", BGGEN_FLAG, argv[i]);
              status = false;
              break;
            }
            if (end[0] != 'x')
            {
              fprintf(stderr, "Unrecognized separator character in %s option"
                " parameter: %s\n", BGGEN_FLAG, argv[i]);
              status = false;
              break;
            }
            new_start = end + 1;
            *png_height = strtol(new_start, &end, DECIMAL);
            if (argv[i] == end)
            {
              fprintf(stderr, "Unrecognized character in %s option"
                " parameter: %s\n", BGGEN_FLAG, argv[i]);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr, "Range error occurred during %s option"
                " parameter parsing: %s\n", BGGEN_FLAG, argv[i]);
              status = false;
              break;
            }
            if ((*png_width < 1) || (*png_height < 1))
            {
              fprintf(stderr, "Generated PNG file must have"
                " greater than 0 size\n");
              status = false;
              break;
            }
          }
          uniform_values->mode = BGGEN_MODE;
        } else if (uniform_values->mode != LOCKED) {
          fprintf(stderr, "%s mode already set. You can not use several"
            " modes.", (uniform_values->mode < SLIDE_MODE ?
              (uniform_values->mode < BGGEN_MODE ? "Animation" : "Generation")
                : "Slide"));
          status = false;
          break;
        }
      } else if (strcmp(argv[i], ATLASFORCED_FLAG) == 0) {
        *new_atlas = true;
      } else if (strcmp(argv[i], COLOR_FLAG) == 0) {
        if (++i < *argc)
        {
          uniform_values->color = strtol(argv[i], &end, DECIMAL);
          if (argv[i] == end)
          {
            fprintf(stderr, "Unrecognized character in %s option"
              " parameter: %s\n", COLOR_FLAG, argv[i]);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr, "Range error occurred during %s option"
              " parameter parsing for: %s\n", COLOR_FLAG, argv[i]);
            status = false;
            break;
          }
          if ((uniform_values->color < BLACK_WHITE) ||
            (uniform_values->color > COLORFUL))
          {
            fprintf(stderr, "%s parameter should be 0, 1, 2 or 3\n",
              COLOR_FLAG);
            status = false;
            break;
          }
        } else {
          fprintf(stderr, "%s option needs parameter\n", ANIMATION_FLAG);
          status = false;
          break;
        }
      } else if (strcmp(argv[i], FPS_FLAG) == 0) {
        if (++i < *argc)
        {
          *fps = strtol(argv[i], &end, DECIMAL);
          if (argv[i] == end)
          {
            fprintf(stderr, "Unrecognized character in %s option"
              " parameter: %s\n", FPS_FLAG, argv[i]);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr, "Range error occurred during %s option"
              " parameter parsing: %s\n", FPS_FLAG, argv[i]);
            status = false;
            break;
          }
          if ((*fps < MIN_FPS) || (*fps > MAX_FPS))
          {
            fprintf(stderr, "Frame rate must be greater or equal than %d and"
              " less or equal than %d.\n", MIN_FPS, MAX_FPS);
            status = false;
            break;
          }
        }
      } else if (strcmp(argv[i], SLIDE_FLAG) == 0) {
        if (uniform_values->mode < ANIM_MOTION_MODE)
        {
          if (++i < *argc)
          {
            *slide_delay = strtol(argv[i], &end, DECIMAL);
            if (argv[i] == end)
            {
              fprintf(stderr, "Unrecognized character in %s option"
                " parameter: %s\n", SLIDE_FLAG, argv[i]);
              status = false;
              break;
            }
            if (errno == ERANGE)
            {
              fprintf(stderr, "Range error occurred during %s option"
                " parsing: %s\n", SLIDE_FLAG, argv[i]);
              status = false;
              break;
            }
            if (*slide_delay <= 0)
            {
              fprintf(stderr, "%s option parameter should be grater than 0\n",
                SLIDE_FLAG);
              status = false;
              break;
            }
          }
          uniform_values->mode = SLIDE_MODE;
        } else if (uniform_values->mode != LOCKED) {
          fprintf(stderr, "%s mode already set. You can not use several"
            " modes.", (uniform_values->mode < SLIDE_MODE ?
              (uniform_values->mode < BGGEN_MODE ? "Animation" : "Generation")
                : "Slide"));
          status = false;
          break;
        }
      } else if (strcmp(argv[i], STOP_FLAG) == 0) {
        uniform_values->mode = LOCKED;
      } else if (strcmp(argv[i], PIXEL_FLAG) == 0) {
        if (++i < *argc)
        {
          uniform_values->pixels = strtol(argv[i], &end, DECIMAL);
          if (argv[i] == end)
          {
            fprintf(stderr, "Unrecognized character in %s option"
              " parameter: %s\n", PIXEL_FLAG, argv[i]);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr, "Range error occurred during %s option"
              " parameter parsing: %s\n", PIXEL_FLAG, argv[i]);
            status = false;
            break;
          }
          if ((uniform_values->pixels > MAX_PIXELS) ||
            (uniform_values->pixels < MIN_PIXELS))
          {
            fprintf(stderr, "Pixelization must be greater or equal than %d"
              " and less or equal than %d.\n", MIN_PIXELS, MAX_PIXELS);
            status = false;
            break;
          }
        }
      } else if (strcmp(argv[i], ZOOM_FLAG) == 0) {
        if (++i < *argc)
        {
          uniform_values->zoom = strtol(argv[i], &end, DECIMAL);
          if (argv[i] == end)
          {
            fprintf(stderr, "Unrecognized character in %s option"
              " parameter: %s\n", ZOOM_FLAG, argv[i]);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr, "Range error occurred during %s option"
              " parameter parsing: %s\n", ZOOM_FLAG, argv[i]);
            status = false;
            break;
          }
          if ((uniform_values->zoom < MIN_ZOOM) ||
            (uniform_values->zoom > MAX_ZOOM))
          {
            fprintf(stderr, "Pixelization must be greater or equal than %d"
              " and less or equal than %d.\n", MIN_ZOOM, MAX_ZOOM);
            status = false;
            break;
          }
        }
      } else if (strcmp(argv[i], VERBOSE_FLAG) == 0) {
        log->verbose = true;
      } else if (strcmp(argv[i], ROADMAP_FLAG) == 0) {
        if (++i < *argc)
        {
          log->roadmap.id = strtol(argv[i], &end, DECIMAL);
          if (argv[i] == end)
          {
            fprintf(stderr, "Unrecognized character in %s option"
              " parameter: %s\n", ROADMAP_FLAG, argv[i]);
            status = false;
            break;
          }
          if (errno == ERANGE)
          {
            fprintf(stderr, "Range error occurred during %s option"
              " parameter parsing: %s\n", ROADMAP_FLAG, argv[i]);
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

  uniform_values->zoom = (51. - uniform_values->zoom) / 100.;

  return status;
}
