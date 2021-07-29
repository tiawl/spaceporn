#ifndef XTELESKTOP_PARSER_H
#define XTELESKTOP_PARSER_H

#include <errno.h>
#include <math.h>
#include <regex.h>
#include <string.h>

#include "util.h"

typedef struct
{
  char* header_buffer;
  char** headers;
  size_t headers_length;
  regex_t regex;
} Regex;

void freeRegex(Regex* regex, const char* spaces, bool verbose);
bool regex_replace(char** str, const char* pattern, const char* replace,
  const char* spaces, bool verbose, enum Roadmap roadmap);
bool readFile(char** filepath, char** buffer, const char* spaces,
  bool verbose, enum Roadmap roadmap);
bool addMarkers(char** filename, char** buffer, const char* dir_path,
  bool is_main, const char* spaces, bool verbose, enum Roadmap roadmap);
bool searchAndReplaceHeaders(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap);
bool improveLogShader(char** message, char** buffer, size_t maxLength,
  bool verbose, enum Roadmap roadmap);

#endif
