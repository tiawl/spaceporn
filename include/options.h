#ifndef XTELESKOP_OPTIONS_H
#define XTELESKOP_OPTIONS_H

#include <string.h>
#include <unistd.h>

#include "path.h"
#include "uniform.h"

#define NAME "xteleskop"
#define VERSION "0.1"

#define DEFAULT_FPS 30
#define DEFAULT_PIXELS 300
#define DEFAULT_ZOOM 25
#define DEFAULT_ANIMATIONS false
#define DEFAULT_MOTION false
#define DEFAULT_PALETTES false

#define ANIMATION_FLAG "-a"
#define FPS_FLAG "-f"
#define CAMERAMOTION_FLAG "-m"
#define PALETTES_FLAG "-p"
#define PIXEL_FLAG "-x"
#define ZOOM_FLAG "-z"
#define ROADMAP_FLAG "-R"
#define VERBOSE_FLAG "-V"

#define MIN_PIXELS 200
#define MAX_PIXELS 600
#define MIN_FPS 1
#define MAX_FPS 60
#define MIN_ZOOM 10
#define MAX_ZOOM 50

void help();
bool parsing_options(bool* verbose, int* fps, UniformValues* uniform_values,
  Roadmap* roadmap, int* argc, char** argv);

#endif
