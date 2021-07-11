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
                        -  2 -> fshaderpath malloc() Failure\n\
                        -  3 -> vshaderpath malloc() Failure\n\
                        -  4 -> texturepath malloc() Failure\n\
                        -  5 -> XOpenDisplay() Failure\n\
                        -  6 -> Invalid GLX version\n\
                        -  7 -> glXChooseFBConfig() Failure\n\
                        -  8 -> XCreateWindow() Failure\n\
                        -  9 -> Unfoundable glXCreateContextAttribsARB()\n\
                        - 10 -> Spaces in GLX extension name\n\
                        - 11 -> Unsupported GLX extension\n\
                        - 12 -> Unable to create context\n\
                        - 13 -> glewInit() Failure\n\
                        - 14 -> Vertex shader file fopen() Failure\n\
                        - 15 -> vertex_file malloc() Failure\n\
                        - 16 -> Fragment shader file fopen() Failure\n\
                        - 17 -> fragment_file malloc() Failure\n\
                        - 18 -> Unable to load vertex shader\n\
                        - 19 -> Unable to load fragment shader\n\
                        - 20 -> Unable to link program\n\
                        - 21 -> No PNG filename\n\
                        - 22 -> PNG file fopen() Failure\n\
                        - 23 -> png_create_read_struct() Failure\n\
                        - 24 -> png_create_info_struct() Failure\n\
                        - 25 -> png_jmpbuf() Failure\n\
                        - 26 -> Bad PNG dimensions\n\
                        - 27 -> PNG data malloc() Failure\n\
                        - 28 -> PNG row_pointers malloc() Failure\n\
                        - 29 -> (if DEBUG true) XCreateWindow() Failure\n\n");
}

bool parsing_options(bool* verbose, int* delay, UniformValues* uniform_values,
  enum Roadmap* roadmap, int* argc, char** argv)
{
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
        *roadmap = atoi(argv[i]);
        if ((*roadmap < EXIT_SUCCESS_RM) || (*roadmap >= RM_NB))
        {
          help();
          return false;
        }
      }
    } else {
      help();
      return false;
    }
  }

  return true;
}
