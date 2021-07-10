#include "options.h"

void help()
{
  fprintf(stderr, "\n%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-m] [-p] [-x PIXELS] [-d MICROS] \
[-R ROADMAP]\n\n", NAME);
  fprintf(stderr, "User options:\n\n\
    -a  Enable shader animations\n\n\
    -m  Enable camera motion\n\n\
    -p  Enable multiple colorschemes\n\n\
    -x  Pixels value between 100 to 600 (ex: -x 300) [default: 500]\n\n\
    -d  Delay value between each frame in microseconds (ex: -d 0)\n\
        [default: 30000]\n\n\
    -v  Verbose\n\n");
  fprintf(stderr, "Dev Options:\n\n\
    -R  Run the corresponding predefined execution roadmap (ex: -R 0)\n\
        [default: 0]\n\n\
        ROADMAP values: - 0 -> Exit Success\n\n");
}

bool parsing_options(bool* verbose, int* delay, UniformValues* uniform_values,
  int* roadmap, int* argc, char** argv)
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
    } else if (strcmp(argv[i], "-v") == 0) {
      *verbose = true;
    } else if (strcmp(argv[i], "-R") == 0) {
      if (++i < *argc)
      {
        *roadmap = atoi(argv[i]);
        if ((*roadmap < EXIT_SUCCESS_RM) || (*roadmap > EXIT_FAILURE_RM))
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
