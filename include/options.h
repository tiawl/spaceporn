#ifndef XTELESKTOP_OPTIONS_H
#define XTELESKTOP_OPTIONS_H

#include <string.h>

#include "uniform.h"

#define NAME "xtelesktop"
#define VERSION "0.1"
#define DEFAULT_DELAY 30000

void help();
bool parsing_options(bool* verbose, int* delay, UniformValues* uniform_values,
  Roadmap* roadmap, int* argc, char** argv);

#endif
