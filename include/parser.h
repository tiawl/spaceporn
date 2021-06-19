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
#define BAR \
  "---------------------------------------------------------------------------"

#include "util.h"

typedef struct
{
  char* header_buffer;
  char** headers;
  size_t headers_length;
  regex_t regex;
} Regex;

void freeRegex(Regex* regex, const char* spaces, Log* log);
bool replace(char** str, const char* pattern, const char* replace,
  const char* spaces, Log* log);
bool readFile(char** filepath, char** buffer, const char* spaces, Log* log);
bool addMarkers(char** filename, char** buffer, const char* spaces, Log* log);
bool searchAndReplaceHeaders(char** buffer, char** dirpath, Log* log);
bool improveLogShader(char** message, char** buffer, Log* log);

#endif
