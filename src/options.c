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
    -R  Run the corresponding predefined execution roadmap (ex: -R 0)\n\
        [default: 0]\n\n\
        ROADMAP values: -  0 -> Exit Success\n\
                        -  1 -> Break loop Success\n\
                        -  2 -> No username Failure\n\
                        -  3 -> fshaderpath malloc() Failure\n\
                        -  4 -> vshaderpath malloc() Failure\n\
                        -  5 -> texturepath malloc() Failure\n\
                        -  6 -> XOpenDisplay() Failure\n\
                        -  7 -> Invalid GLX version\n\
                        -  8 -> glXChooseFBConfig() Failure\n\
                        -  9 -> XCreateWindow() Failure\n\
                        - 10 -> Unfoundable glXCreateContextAttribsARB()\n\
                        - 11 -> Spaces in GLX extension name\n\
                        - 12 -> Unsupported GLX extension\n\
                        - 13 -> Unable to create context\n\
                        - 14 -> glewInit() Failure\n\
                        - 15 -> Vertex shader file fopen() Failure\n\
                        - 16 -> vertex_file malloc() Failure\n\
                        - 17 -> Fragment shader file fopen() Failure\n\
                        - 18 -> fragment_file malloc() Failure\n\
                        - 19 -> Unable to compile vertex shader\n\
                        - 20 -> Unable to compile fragment shader\n\
                        - 21 -> Unable to link program\n\
                        - 22 -> No PNG filename\n\
                        - 23 -> PNG file fopen() Failure\n\
                        - 24 -> png_create_read_struct() Failure\n\
                        - 25 -> png_create_info_struct() Failure\n\
                        - 26 -> png_jmpbuf() Failure\n\
                        - 27 -> Bad PNG dimensions\n\
                        - 28 -> PNG data malloc() Failure\n\
                        - 29 -> PNG row_pointers malloc() Failure\n\
                        - 30 -> (if DEBUG true) XCreateWindow() Failure\n\n");
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
        } else if (roadmap->id) {
          if ((roadmap->id == FRAGMENT_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM)
            || (roadmap->id == FRAGMENT_FILE_SARH_HEADER_MALLOC_FAILED_RM)
            || (roadmap->id == VERTEX_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM)
            || (roadmap->id == VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM))
          {
            if (++i < *argc)
            {
              char* dir = NULL;
              if ((roadmap->id == VERTEX_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM)
                || (roadmap->id == VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM))
              {
                dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                  strlen(VERTEX_DIR) + strlen(argv[i]) + 1));
                strcpy(dir, SHADERS_DIR);
                strcat(dir, VERTEX_DIR);
              } else {
                dir = malloc(sizeof(char) * (strlen(SHADERS_DIR) +
                  strlen(FRAGMENT_DIR) + strlen(argv[i]) + 1));
                strcpy(dir, SHADERS_DIR);
                strcat(dir, FRAGMENT_DIR);
              }
              strcat(dir, argv[i]);
              if (access(dir, F_OK) == 0)
              {
                roadmap->glsl_file = argv[i];
              } else {
                fprintf(stderr, "%s does not exist\n", dir);
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
