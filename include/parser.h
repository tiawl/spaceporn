#ifndef SPACEPORN_PARSER_H
#define SPACEPORN_PARSER_H

#include <errno.h>
#include <math.h>
#include <regex.h>
#include <string.h>

#define INCLUDE_HEADER_PATTERN \
  "^[[:space:]]*#[[:space:]]*include \"([/-_[:alnum:]]+\\.glsl)\""
#define STARTLINE_SHADERLOG_PATTERN \
  "^[[:digit:]]+:([[:digit:]]+)\\([[:digit:]]+\\)"

#include "util.h"

typedef struct
{
  char* header_buffer;
  char** headers;
  size_t headers_length;
  regex_t regex;
} Regex;

void freeRegex(Regex* regex, const char* spaces, bool verbose);
bool replace(char** str, const char* pattern, const char* replace,
  const char* spaces, bool verbose, Roadmap* roadmap);
bool readFile(char** filepath, char** buffer, const char* spaces,
  bool verbose, Roadmap* roadmap);
bool addMarkers(char** filename, char** buffer, const char* dir_path,
  const char* spaces, bool verbose, Roadmap* roadmap);
bool searchAndReplaceHeaders(char** filepath, char** buffer, bool verbose,
  Roadmap* roadmap);
bool improveLogShader(char** message, char** buffer, size_t maxLength,
  bool verbose, Roadmap* roadmap);

#endif
