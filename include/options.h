#ifndef XTELESKOP_OPTIONS_H
#define XTELESKOP_OPTIONS_H

#include <string.h>
#include <unistd.h>

#include "path.h"
#include "uniform.h"

#define NAME "xteleskop"
#define VERSION "0.1"
#define DEFAULT_DELAY 30000

void help();
bool parsing_options(bool* verbose, int* delay, UniformValues* uniform_values,
  Roadmap* roadmap, int* argc, char** argv);

#endif
