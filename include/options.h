#ifndef SPACEPORN_OPTIONS_H
#define SPACEPORN_OPTIONS_H

#include <string.h>
#include <unistd.h>

#include "path.h"
#include "uniform.h"

#define NAME                        "spaceporn-cli"
#define BIN_NAME                        "spaceporn"
#define VERSION                             "0.0.0"
#define BRANCH                           GCC_BRANCH

#define DEFAULT_FPS                              30
#define DEFAULT_ANIMATIONS                    false
#define DEFAULT_MOTION                        false
#define DEFAULT_COLOR                          MONO
#define DEFAULT_SLIDE                             1

#define ANIMATION_FLAG                         "-a"
#define BGGEN_FLAG                             "-b"
#define COLOR_FLAG                             "-c"
#define ATLASFORCED_FLAG                       "-f"
#define FPS_FLAG                               "-r"
#define SLIDE_FLAG                             "-s"
#define STOP_FLAG                              "-t"
#define PIXEL_FLAG                             "-x"
#define ZOOM_FLAG                              "-z"
#define FRAGMENTFILEROADMAPS_FLAG              "-F"
#define MAXROADMAP_FLAG                        "-M"
#define ROADMAP_FLAG                           "-R"
#define VERTEXFILEROADMAPS_FLAG                "-T"
#define VERBOSE_FLAG                           "-V"

#define MIN_PIXELS                              200
#define MAX_PIXELS                              600
#define MIN_FPS                                   1
#define MAX_FPS                                  60
#define MIN_ZOOM                                  1
#define MAX_ZOOM                                 40

#define DECIMAL                                  10
#define UNDEFINED_SIZE 0

void help();
bool parsing_options(long* fps, bool* new_atlas, long* png_width,
  long* png_height, long* slide_delay, UniformValues* uniform_values,
  Log* log, int* argc, char** argv);

#endif
