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
                        -  2 -> No username fshaderpath Failure\n\
                        -  3 -> fshaderpath malloc() Failure\n\
                        -  4 -> No username vshaderpath Failure\n\
                        -  5 -> vshaderpath malloc() Failure\n\
                        -  6 -> No username texturepath Failure\n\
                        -  7 -> texturepath malloc() Failure\n\
                        -  8 -> XOpenDisplay() Failure\n\
                        -  9 -> Invalid GLX version\n\
                        - 10 -> glXChooseFBConfig() Failure\n\
                        - 11 -> XCreateWindow() Failure\n\
                        - 12 -> Unfoundable glXCreateContextAttribsARB()\n\
                        - 13 -> Spaces in GLX extension name\n\
                        - 14 -> Unsupported GLX extension\n\
                        - 15 -> Unable to create context\n\
                        - 16 -> glewInit() Failure\n\
                        - 17 -> Vertex shader file fopen() Failure\n\
                        - 18 -> vertex_file malloc() Failure\n\
                        - 19 -> Fragment shader file fopen() Failure\n\
                        - 20 -> fragment_file malloc() Failure\n\
                        - 21 -> Unable to load vertex shader\n\
                        - 22 -> Unable to load fragment shader\n\
                        - 23 -> Unable to link program\n\
                        - 24 -> No PNG filename\n\
                        - 25 -> PNG file fopen() Failure\n\
                        - 26 -> png_create_read_struct() Failure\n\
                        - 27 -> png_create_info_struct() Failure\n\
                        - 28 -> png_jmpbuf() Failure\n\
                        - 29 -> Bad PNG dimensions\n\
                        - 30 -> PNG data malloc() Failure\n\
                        - 31 -> PNG row_pointers malloc() Failure\n\
                        - 32 -> (if DEBUG true) XCreateWindow() Failure\n\n");
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
