#include "parser.h"

void freeRegex(Regex* regex, const char* spaces, bool verbose)
{
  if (regex->header_buffer)
  {
    VERB(verbose, printf("%s    Freeing header_buffer memory ...\n", spaces));
    free(regex->header_buffer);
    regex->header_buffer = NULL;
    VERB(verbose, printf("%s    Memory freed successfully\n", spaces));
  }

  if (regex->headers)
  {
    for (size_t i = 0; i < regex->headers_length; ++i)
    {
      VERB(verbose, printf("%s    Freeing headers[%lu] memory ...\n", spaces,
        i));
      free((regex->headers)[i]);
      VERB(verbose, printf("%s    Memory freed successfully\n", spaces));
    }

    VERB(verbose, printf("%s    Freeing headers memory ...\n", spaces));
    free(regex->headers);
    regex->headers = NULL;
    VERB(verbose, printf("%s    Memory freed successfully\n", spaces));
  }

  VERB(verbose, printf("%s    Freeing regex structure ...\n", spaces));
  regfree(&(regex->regex));
  VERB(verbose, printf("%s    Memory freed successfully\n", spaces));
}

bool replace(char** str, const char* pattern, const char* replace,
  const char* spaces, bool verbose, Roadmap* roadmap)
{
  regex_t regex;

  VERB(verbose, printf("%s      Compiling regex pattern: \"%s\" ...\n",
    spaces, pattern));

  if ((roadmap->id != REPLACE_REGCOMP_FAILED_RM) &&
    (regcomp(&regex, pattern, REG_EXTENDED | REG_NEWLINE) == 0))
  {
    VERB(verbose, printf("%s      Regex pattern compiled successfully\n",
      spaces));

    size_t nmatch = regex.re_nsub;
    VERB(verbose, printf("%s      Regex subexpressions found: %lu\n", spaces,
      nmatch));

    regmatch_t m[nmatch + 1];

    size_t start;
    size_t end;

    // replace only first occurence
    VERB(verbose, printf("%s      Comparing regex pattern ...\n", spaces));
    int match = regexec(&regex, *str, nmatch + 1, m, 0);
    if ((match == 0) && (roadmap->id != REPLACE_REGEXEC_FAILED_RM))
    {
      VERB(verbose, printf("%s      Regex pattern found\n", spaces));

      start = m[0].rm_so;
      VERB(verbose, printf("%s      Start index of first match is %lu\n",
        spaces, start));
      end = m[0].rm_eo;
      VERB(verbose, printf("%s      End index of first match is %lu\n",
        spaces, end));

      char new[strlen(*str) + strlen(replace)];
      new[0] = '\0';

      VERB(verbose, printf("%s      Building new string ...\n", spaces));
      VERB(verbose, printf("%s        Copying first part of the \
original string ...\n", spaces));
      strncat(new, *str, start);
      VERB(verbose, printf("%s        Strings copied successfully\n",
        spaces));

      VERB(verbose, printf("%s        Concatenating replaced part \
...\n", spaces));
      strcat(new, replace);
      VERB(verbose, printf("%s        Replaced part added successfully\n",
        spaces));

      VERB(verbose, printf("%s        Concatenating last part of the \
original string ...\n", spaces));
      strncat(new, *str + end, strlen(*str) - end);
      VERB(verbose, printf("%s        Strings concatenated successfully\n",
        spaces));
      VERB(verbose, printf("%s      New string built\n", spaces));

      VERB(verbose, printf("%s      Reallocating memory for *str ...\n",
        spaces));
      if (roadmap->id != REPLACE_REALLOC_FAILED_RM)
      {
        *str = realloc(*str, sizeof(char) * (strlen(new) + 1));
      } else {
        free(*str);
        *str = NULL;
      }

      if (!*str)
      {
        VERB(verbose, fprintf(stderr, "%s      ", spaces));
        fprintf(stderr, "*str realloc() failed\n");
        regfree(&regex);
        return false;
      }
      VERB(verbose, printf("%s      Memory reallocated successfully\n",
        spaces));

      VERB(verbose, printf("%s      Copying new in *str ...\n", spaces));
      strcpy(*str, new);
      VERB(verbose, printf("%s      Copied successfully\n", spaces));
    } else if ((match == REG_NOMATCH)
      && (roadmap->id != REPLACE_REGEXEC_FAILED_RM)) {
        VERB(verbose, printf("%s      Regex pattern not found\n", spaces));
    } else {
      if (roadmap->id != REPLACE_REGEXEC_FAILED_RM)
      {
        int regex_error = 1;
        size_t size = regerror(regex_error, &regex, NULL, 0);
        VERB(verbose, printf("%s      Message size of regex error is %lu\n",
          spaces, size));

        char text[size];

        regerror(regex_error, &regex, &(text[0]), size);

        VERB(verbose, printf("%s      Freeing regex structure ...\n", spaces));
        regfree(&regex);
        VERB(verbose, printf("%s      Memory freed successfully\n", spaces));

        VERB(verbose, fprintf(stderr, "%s      ", spaces));
        fprintf(stderr, "Regex error: %s\n", text);
        return false;
      } else {
        VERB(verbose, printf("%s      Freeing regex structure ...\n", spaces));
        regfree(&regex);
        VERB(verbose, printf("%s      Memory freed successfully\n", spaces));

        return false;
      }
    }

    VERB(verbose, printf("%s      Freeing regex structure ...\n", spaces));
    regfree(&regex);
    VERB(verbose, printf("%s      Memory freed successfully\n", spaces));

    return true;
  } else {
    VERB(verbose, fprintf(stderr, "%s      ", spaces));
    fprintf(stderr, "Regex compilation failed\n");
    return false;
  }
}

bool readFile(char** filepath, char** buffer, const char* spaces,
  bool verbose, Roadmap* roadmap)
{
  long length;

  VERB(verbose, printf("%s      Opening \"%s\" ...\n", spaces, *filepath));
  FILE* f = NULL;

  if (roadmap->id != FOPEN_FAILED_RM)
  {
    f = fopen(*filepath, "r");
  }

  if (f)
  {
    VERB(verbose, printf("%s      File opened successfully\n", spaces));

    VERB(verbose, printf("%s      Setting file position of the stream to the \
end ...\n", spaces));
    fseek(f, 0, SEEK_END);
    VERB(verbose, printf("%s      Stream positionned\n", spaces));

    VERB(verbose, printf("%s      Computing file position of the stream \
...\n", spaces));
    char relative_path[19];
    strncpy(relative_path, *filepath + (strlen(*filepath) - 18), 18);
    relative_path[18] = '\0';
    if (((roadmap->id == VERTEX_SHADER_COMPILATION_FAILED_RM)
      && (strcmp(relative_path, "s/vertex/main.glsl") == 0))
      || (roadmap->id == VERTEX_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
      || (roadmap->id == VERTEX_FILE_ILS_REPLACE_REALLOC_FAILED_RM)
      || (roadmap->id == VERTEX_FILE_ILS_REPLACE_REGEXEC_FAILED_RM)
      || (roadmap->id == VERTEX_FILE_ILS_REGCOMP_FAILED_RM)
      || (roadmap->id == VERTEX_FILE_ILS_REGEXEC_FAILED_RM))
    {
      length = ERRONEOUS_VERTEX_SHADER;
    } else if (((roadmap->id == FRAGMENT_SHADER_COMPILATION_FAILED_RM)
      && (strcmp(relative_path, "fragment/main.glsl") == 0))
      || (roadmap->id == FRAGMENT_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
      || (roadmap->id == FRAGMENT_FILE_ILS_REPLACE_REALLOC_FAILED_RM)
      || (roadmap->id == FRAGMENT_FILE_ILS_REPLACE_REGEXEC_FAILED_RM)
      || (roadmap->id == FRAGMENT_FILE_ILS_REGCOMP_FAILED_RM)
      || (roadmap->id == FRAGMENT_FILE_ILS_REGEXEC_FAILED_RM)) {
        length = ERRONEOUS_FRAGMENT_SHADER;
    } else if ((roadmap->id == LINKING_PROGRAM_FAILED_RM)
      && (strcmp(relative_path, "s/vertex/main.glsl") == 0)) {
        length = MISSINGMAIN_VERTEX_SHADER;
    } else {
      length = ftell(f);
    }
    VERB(verbose, printf("%s      File position of the stream computed\n",
      spaces));

    VERB(verbose, printf("%s      Setting file position of the stream to the \
beginning ...\n", spaces));
    fseek(f, 0, SEEK_SET);
    VERB(verbose, printf("%s      Stream positionned\n", spaces));

    VERB(verbose, printf("%s      Allocating memory for reading file buffer \
...\n", spaces));
    if (roadmap->id != BUFFER_MALLOC_FAILED_RM)
    {
      *buffer = malloc(length + 1);
    }

    if (*buffer)
    {
      VERB(verbose, printf("%s      Memory for reading file buffer \
allocated successfully\n", spaces));

      VERB(verbose, printf("%s      Reading file into buffer ...\n", spaces))
      fread(*buffer, 1, length, f);
      (*buffer)[length] = '\0'; // fread does not 0 terminate strings
      VERB(verbose, printf("%s      Buffer filled with:\n\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", spaces, *buffer))

    } else {
      VERB(verbose, fprintf(stderr, "%s      ", spaces));
      fprintf(stderr, "Buffer malloc() failed\n");
      return false;
    }

    VERB(verbose, printf("%s      Closing \"%s\" ...\n", spaces, *filepath));
    fclose(f);
    VERB(verbose, printf("%s      File closed successfully\n", spaces));

  } else {
    VERB(verbose, fprintf(stderr, "%s      ", spaces));
    fprintf(stderr, "Failed to read inside \"%s\": %s\n", *filepath,
      strerror(errno));
    return false;
  }

  return true;
}

bool addMarkers(char** filename, char** buffer, const char* dir_path,
  const char* spaces, bool verbose, Roadmap* roadmap)
{
  size_t i = 0;

  size_t marker_length;
  unsigned line = 1;

  VERB(verbose, printf("%s    Computing length of buffer file ...\n",
    spaces));
  size_t buffer_length = strlen(*buffer);
  VERB(verbose, printf("%s    Length of buffer file is %lu\n", spaces,
    buffer_length));

  VERB(verbose, printf("%s    Computing lines number in buffer file ...\n",
    spaces));
  unsigned buffer_lines = 0;
  while (i <= buffer_length)
  {
    if ((*buffer)[i] == '\n')
    {
      ++buffer_lines;
    }
    ++i;
  }
  VERB(verbose, printf("%s    Lines number of buffer file is %u\n", spaces,
    buffer_lines));

  i = 0;

  VERB(verbose, printf("%s    Reallocating memory for buffer ...\n",
    spaces));
  if ((roadmap->id != SARH_ADDMARKERS_REALLOC_FAILED_RM)
    || (strcmp(roadmap->glsl_file, *filename) != 0))
  {
    *buffer = realloc(*buffer, sizeof(char) * (buffer_length + 1 +
      (strlen(*filename) + strlen(" // :") + floor(log10(buffer_lines)) + 1) *
      buffer_lines));
  } else {
    free(*buffer);
    *buffer = NULL;
  }

  if (!*buffer)
  {
    VERB(verbose, fprintf(stderr, "%s      ", spaces));
    fprintf(stderr, "realloc() buffer failed\n");
    return false;
  }
  VERB(verbose, printf("%s    Memory reallocated successfully\n",
    spaces));

  VERB(verbose, printf("%s    Iterating over the buffer ...\n", spaces));
  while (i <= buffer_length)
  {
    if ((*buffer)[i] == '\n')
    {
      VERB(verbose, printf("%s      New line detected\n", spaces));

      VERB(verbose, printf("%s      Computing length of marker ...\n",
        spaces));
      marker_length = strlen(*filename) + strlen(" // :") +
        floor(log10(line)) + 1 + 1;
      VERB(verbose, printf("%s      Length of marker is %lu\n", spaces,
        marker_length));

      VERB(verbose, printf("%s      Building marker ...\n", spaces));
      char marker[marker_length];
      snprintf(marker, marker_length + 1, " // %s:%u", *filename, line);
      VERB(verbose, printf("%s      Marker is \"%s\"\n", spaces, marker));

      VERB(verbose, printf("%s      Building new file buffer ...\n",
        spaces));

      char new[buffer_length + marker_length];
      new[0] = '\0';

      VERB(verbose, printf("%s        Copying first file buffer part \
...\n", spaces));
      strncat(new, *buffer, i);
      VERB(verbose, printf("%s        First file buffer part copied \
successfully\n", spaces));

      VERB(verbose, printf("%s        Concatenating marker ...\n", spaces));
      strcat(new, marker);
      VERB(verbose, printf("%s        Marker concatenated\n", spaces));

      VERB(verbose, printf("%s        Concatenating last file buffer part \
...\n", spaces));
      strncat(new, *buffer + i, buffer_length - i);
      VERB(verbose, printf("%s        Last file buffer part concatenated \
successfully\n", spaces));

      VERB(verbose, printf("%s      New buffer file built\n", spaces));

      VERB(verbose, printf("%s      Copying temporary variable into file \
buffer ...\n", spaces));
      strcpy(*buffer, new);
      VERB(verbose, printf("%s      Temporary variable copied \
successfully\n", spaces));

      VERB(verbose, printf("%s      Recomputing length of buffer file \
...\n", spaces));
      buffer_length = strlen(*buffer);
      VERB(verbose, printf("%s      Length of buffer files is %lu\n",
        spaces, buffer_length));

      VERB(verbose, printf("%s      Iterating until the end of the newly \
created marker ...\n", spaces));
      while (((*buffer)[i] != '\n') && ((*buffer)[i] != '\0'))
      {
        ++i;
      }
      VERB(verbose, printf("%s      Marker found\n", spaces));
      ++line;
    }
    ++i;
  }

  return true;
}

bool searchAndReplaceHeaders(char** filepath, char** buffer, bool verbose,
  Roadmap* roadmap)
{
  Regex regex;
  regex.header_buffer = NULL;
  regex.headers = NULL;
  regex.headers_length = 0;

  char dir_path[strlen(*filepath) - 9];
  dir_path[0] = '\0';

  VERB(verbose, printf("    Copying string into dir_path ...\n"));
  strncat(dir_path, *filepath, strlen(*filepath) - 9);
  VERB(verbose, printf("    \"%s\" successfully copied\n", dir_path));

  VERB(verbose, printf("    Compiling regex pattern: \"%s\" ...\n",
    INCLUDE_HEADER_PATTERN));
  int regex_error = 1;
  if (roadmap->id != SARH_REGCOMP_FAILED_RM)
  {
    regex_error = regcomp(&(regex.regex), INCLUDE_HEADER_PATTERN,
      REG_EXTENDED | REG_NEWLINE);
  }

  if (regex_error == 0)
  {
    VERB(verbose, printf("    Regex pattern compiled successfully\n"));

    size_t nmatch = regex.regex.re_nsub;
    VERB(verbose, printf("    Regex subexpressions found: %lu\n", nmatch));

    regmatch_t m[nmatch + 1];

    bool is_already_included = false;

    VERB(verbose, printf("    Allocating memory for headers ...\n");)
    if (roadmap->id != SARH_HEADERS_MALLOC_FAILED_RM)
    {
      regex.headers = malloc(sizeof(char*));
    }

    if (!regex.headers)
    {
      VERB(verbose, fprintf(stderr, "    "));
      fprintf(stderr, "headers malloc() failed\n");
      freeRegex(&regex, "", verbose);
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));

    VERB(verbose, printf("    Allocating memory for headers[0] ...\n");)
    if ((roadmap->id != SARH_HEADER_MALLOC_FAILED_RM)
      || (strcmp(roadmap->glsl_file, "main.glsl") != 0))
    {
      (regex.headers)[0] = malloc(sizeof(char) * (strlen("main.glsl") + 1));
    } else {
      (regex.headers)[0] = NULL;
    }

    if (!(regex.headers)[0])
    {
      VERB(verbose, fprintf(stderr, "    "));
      fprintf (stderr, "headers[0] malloc() failed\n");
      freeRegex(&regex, "", verbose);
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));
    regex.headers_length = 1;

    VERB(verbose, printf("    Copying string into headers[0] ...\n"));
    strcpy((regex.headers)[0], "main.glsl");
    (regex.headers)[0][strlen((regex.headers)[0])] = '\0';
    VERB(verbose, printf("    \"%s\" successfully copied\n",
      (regex.headers)[0]));

    VERB(verbose, printf("    Adding markers to \"%s\" ...\n",
      (regex.headers)[0]));
    if (!addMarkers(&((regex.headers)[0]), buffer, dir_path, "", verbose,
      roadmap))
    {
      VERB(verbose, fprintf(stderr, "    "));
      fprintf(stderr, "Unable to mark the file\n");
      freeRegex(&regex, "", verbose);
      return false;
    }
    VERB(verbose, printf("    Markers added\n"));

    VERB(verbose, printf("    Comparing regex pattern to buffer file ...\n"));
    int match = regexec(&(regex.regex), *buffer, nmatch + 1, m, 0);

    size_t start_header;
    size_t end_header;

    while (match == 0)
    {
      VERB(verbose, printf("    Regex pattern found into buffer file\n"));
      start_header = m[1].rm_so;
      VERB(verbose, printf("    Start index of header is %lu\n",
        start_header));
      end_header = m[1].rm_eo;
      VERB(verbose, printf("    End index of header is %lu\n", end_header));

      char first_match[end_header - start_header];
      VERB(verbose, printf("    Header length is %lu\n",
        end_header - start_header));

      first_match[0] = '\0';

      VERB(verbose, printf("      Copying into first_match ...\n"));
      strncat(first_match, (*buffer) + start_header,
        end_header - start_header);
      VERB(verbose, printf("      \"%s\" successfully copied\n",
        first_match));

      VERB(verbose, printf("      Comparing first_match to the cache ...\n"));
      is_already_included = false;
      for (size_t i = 0; (i < regex.headers_length) &&
        !is_already_included; ++i)
      {
        VERB(verbose, printf("        Comparing \"%s\" to \"%s\" ...\n",
          (regex.headers)[i], first_match));
        is_already_included |= (strcmp((regex.headers)[i], first_match) == 0);
        VERB(verbose, printf("        %s\n",
          is_already_included ? "Same strings" : "Not same strings"));
      }

      if (is_already_included)
      {
        VERB(verbose, printf("      \"%s\" is already included\n",
          first_match));

        VERB(verbose, printf("      Deleting first occurence of #header \
\"%s\" line into buffer file with replace() ...\n", first_match));
        if ((roadmap->id == SARH_REPLACE_1_REGCOMP_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0))
        {
            roadmap->id = REPLACE_REGCOMP_FAILED_RM;
        } else if ((roadmap->id == SARH_REPLACE_1_REALLOC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0)) {
            roadmap->id = REPLACE_REALLOC_FAILED_RM;
        } else if ((roadmap->id == SARH_REPLACE_1_REGEXEC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0)) {
            roadmap->id = REPLACE_REGEXEC_FAILED_RM;
        }

        if (!replace(buffer, INCLUDE_HEADER_PATTERN, "", "  ", verbose,
          roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "replace() failed\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }

        if ((roadmap->id == REPLACE_REGCOMP_FAILED_RM) ||
          (roadmap->id == REPLACE_REALLOC_FAILED_RM) ||
          (roadmap->id == REPLACE_REGEXEC_FAILED_RM))
        {
          roadmap->id = BREAK_SUCCESS_RM;
        }
        VERB(verbose, printf("      Line successfully deleted\n"));
      } else {

        VERB(verbose, printf("      \"%s\" is not already included\n",
          first_match));

        VERB(verbose, printf("      Reallocating memory for headers ...\n");)
        if ((roadmap->id != SARH_HEADERS_REALLOC_FAILED_RM) ||
          (strcmp(roadmap->glsl_file, first_match) != 0))
        {
          regex.headers = realloc(regex.headers,
            sizeof(char*) * (regex.headers_length + 1));
        } else {
          for (size_t i = 0; i < regex.headers_length; ++i)
          {
            free((regex.headers)[i]);
          }
          free(regex.headers);
          regex.headers = NULL;
        }

        if (!regex.headers)
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf (stderr, "headers realloc() failed\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      Memory reallocated successfully\n"));

        VERB(verbose, printf("      Allocating memory for headers[%lu] \
...\n", regex.headers_length);)
        if ((roadmap->id == SARH_HEADER_REALLOC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0))
        {
          (regex.headers)[regex.headers_length] = NULL;
        } else {
          (regex.headers)[regex.headers_length] =
            malloc(sizeof(char) * (end_header - start_header + 1));
        }

        if (!(regex.headers)[regex.headers_length])
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf (stderr, "headers[%lu] malloc() failed\n",
            regex.headers_length);
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      Memory allocated successfully\n"));

        regex.headers_length++;

        VERB(verbose, printf("      Copying string into headers[%lu] ...\n",
          regex.headers_length - 1));
        strncpy((regex.headers)[regex.headers_length - 1], first_match,
          end_header - start_header);
        (regex.headers)[regex.headers_length - 1]
          [end_header - start_header] = '\0';
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          (regex.headers)[regex.headers_length - 1]));

        char header_filepath[strlen(dir_path) + strlen(first_match) + 1];

        VERB(verbose, printf("      Copying string into header_filepath \
...\n"));
        strcpy(header_filepath, dir_path);
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          header_filepath));

        VERB(verbose, printf("      Concatenating string into \
header_filepath ...\n"));
        strcat(header_filepath, first_match);
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          header_filepath));

        VERB(verbose, printf("      Reading file \"%s\" ... \n",
          header_filepath));
        char* header_filepath_p = &(header_filepath[0]);

        if ((roadmap->id == SARH_READFILE_BUFFER_MALLOC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0))
        {
          roadmap->id = BUFFER_MALLOC_FAILED_RM;
        } else if ((roadmap->id == SARH_READFILE_FOPEN_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0)) {
            roadmap->id = FOPEN_FAILED_RM;
        }

        if (!readFile(&header_filepath_p, &(regex.header_buffer), "  ",
          verbose, roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "Failed to read file\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }

        if ((roadmap->id == BUFFER_MALLOC_FAILED_RM) ||
          (roadmap->id == FOPEN_FAILED_RM))
        {
          roadmap->id = BREAK_SUCCESS_RM;
        }
        VERB(verbose, printf("      File read successfully\n"));

        VERB(verbose, printf("      Adding markers to \"%s\" ...\n",
          (regex.headers)[regex.headers_length - 1]));
        if ((roadmap->id == SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0))
        {
          roadmap->id = SARH_ADDMARKERS_REALLOC_FAILED_RM;
        }

        if (!addMarkers(&((regex.headers)[regex.headers_length - 1]),
          &(regex.header_buffer), dir_path, "  ", verbose, roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "Unable to mark the file\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }

        if (roadmap->id == SARH_ADDMARKERS_REALLOC_FAILED_RM)
        {
          roadmap->id = BREAK_SUCCESS_RM;
        }
        VERB(verbose, printf("      Markers added\n"));

        VERB(verbose, printf("      Replacing header \"%s\" by its content \
into buffer file ...\n", first_match));
        if ((roadmap->id == SARH_REPLACE_2_REGCOMP_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0))
        {
          roadmap->id = REPLACE_REGCOMP_FAILED_RM;
        } else if ((roadmap->id == SARH_REPLACE_2_REALLOC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0)) {
            roadmap->id = REPLACE_REALLOC_FAILED_RM;
        } else if ((roadmap->id == SARH_REPLACE_2_REGEXEC_FAILED_RM) &&
          (strcmp(roadmap->glsl_file, first_match) == 0)) {
            roadmap->id = REPLACE_REGEXEC_FAILED_RM;
        }

        if (!replace(buffer, INCLUDE_HEADER_PATTERN,
          regex.header_buffer, "  ", verbose, roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "replace() failed\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }

        if ((roadmap->id == REPLACE_REGCOMP_FAILED_RM) ||
          (roadmap->id == REPLACE_REALLOC_FAILED_RM) ||
          (roadmap->id == REPLACE_REGEXEC_FAILED_RM))
        {
          roadmap->id = BREAK_SUCCESS_RM;
        }
        VERB(verbose, printf("      Buffer file filled by header content\n"));

        VERB(verbose, printf("      Freeing header_buffer memory ...\n"));
        free(regex.header_buffer);
        regex.header_buffer = NULL;
        VERB(verbose, printf("      Memory freed successfully\n"));
      }

      VERB(verbose,
        printf("      Comparing regex pattern to buffer file ...\n"));
      match = regexec(&(regex.regex), *buffer, nmatch + 1, m, 0);
    }
    VERB(verbose, printf("    Regex pattern not found\n"));
    VERB(verbose, printf("    File buffer is now:\n\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", *buffer));

    freeRegex(&regex, "", verbose);

    VERB(verbose, printf("    Searching for regex error ...\n"));
    if ((match != REG_NOMATCH) || (roadmap->id == SARH_REGEXEC_FAILED_RM))
    {
      if (roadmap->id != SARH_REGEXEC_FAILED_RM)
      {
        size_t size = regerror(regex_error, &(regex.regex), NULL, 0);
        VERB(verbose, printf("    Message size of regex error is %lu\n", size));

        char text[size];

        regerror(regex_error, &(regex.regex), &(text[0]), size);

        VERB(verbose, fprintf(stderr, "    "));
        fprintf(stderr, "Regex error: %s\n", text);
      }
      return false;
    }
    VERB(verbose, printf("    No regex error\n"));
  } else {
    VERB(verbose, fprintf(stderr, "    "));
    fprintf(stderr, "Regex compilation failed\n");
    return false;
  }

  if ((roadmap->id == SARH_ADDMARKERS_REALLOC_FAILED_RM) ||
    (roadmap->id == SARH_HEADER_MALLOC_FAILED_RM) ||
    (roadmap->id == SARH_REGEXEC_FAILED_RM) ||
    (roadmap->id == SARH_REPLACE_2_REGEXEC_FAILED_RM) ||
    (roadmap->id == SARH_REPLACE_2_REALLOC_FAILED_RM) ||
    (roadmap->id == SARH_REPLACE_2_REGCOMP_FAILED_RM) ||
    (roadmap->id == SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) ||
    (roadmap->id == SARH_READFILE_FOPEN_FAILED_RM) ||
    (roadmap->id == SARH_READFILE_BUFFER_MALLOC_FAILED_RM) ||
    (roadmap->id == SARH_HEADER_REALLOC_FAILED_RM) ||
    (roadmap->id == SARH_HEADERS_REALLOC_FAILED_RM) ||
    (roadmap->id == SARH_REPLACE_1_REGEXEC_FAILED_RM) ||
    (roadmap->id == SARH_REPLACE_1_REALLOC_FAILED_RM) ||
    (roadmap->id == SARH_REPLACE_1_REGCOMP_FAILED_RM))
  {
    roadmap->id = BREAK_SUCCESS_RM;
  }

  return true;
}

bool improveLogShader(char** message, char** buffer, size_t maxLength,
  bool verbose, Roadmap* roadmap)
{
  regex_t regex;

  VERB(verbose, printf("      Compiling regex pattern: \"%s\" ...\n",
    STARTLINE_SHADERLOG_PATTERN));

  int regex_error = 1;
  if (roadmap->id != IMPROVELOGSHADER_REGCOMP_FAILED_RM)
  {
    regex_error = regcomp(&regex, STARTLINE_SHADERLOG_PATTERN,
      REG_EXTENDED | REG_NEWLINE);
  }

  if (regex_error == 0)
  {
    VERB(verbose, printf("      Regex pattern compiled successfully\n"));

    size_t nmatch = regex.re_nsub;
    VERB(verbose, printf("      Regex subexpressions found: %lu\n", nmatch));

    regmatch_t m[nmatch + 1];

    VERB(verbose, printf("      Comparing regex pattern ...\n"));
    int match = regexec(&regex, *message, nmatch + 1, m, 0);

    size_t start;
    size_t end;

    unsigned l;

    while (match == 0)
    {
      VERB(verbose, printf("      Regex pattern found\n"));

      start = m[1].rm_so;
      VERB(verbose, printf("      Start index of parenthesis expression is \
%lu\n", start));
      end = m[1].rm_eo;
      VERB(verbose, printf("      End index of parenthesis expression is %lu\n",
        end));

      char line[end - start];
      line[0] = '\0';

      VERB(verbose, printf("      Copying line number of buffer file error \
...\n"));
      strncat(line, *message + start, end - start);
      VERB(verbose, printf("      Line number successfully copied\n"));

      VERB(verbose, printf("      Casting line number string to unsigned int \
...\n"));
      l = strtoul(line, NULL, 10);
      VERB(verbose, printf("      Line number successfully casted\n"));

      VERB(verbose, printf("      Line number is %u\n", l));

      unsigned i = 0;
      end = 0;

      VERB(verbose, printf("      Searching corresponding line into buffer \
file ...\n"));
      while ((i < l) && ((*buffer)[end] != '\0'))
      {
        if ((*buffer)[end] == '\n')
        {
          ++i;
        }
        if (i < l)
        {
          ++end;
        }
      }
      VERB(verbose, start = end - 1;
        while ((*buffer)[start] != '\n')
        {
          start--;
        }
        char buffer_line[end - start - 1];
        buffer_line[0] = '\0';
        strncat(buffer_line, (*buffer) + start + 1, end - start - 1);
        printf("      Corresponding line is \"%s\"\n", buffer_line););

      start = end;

      VERB(verbose, printf("      Searching marker into line ...\n"));
      while (((*buffer)[start - 3] != ' ') || ((*buffer)[start - 2] != '/') ||
        ((*buffer)[start - 1] != '/') || ((*buffer)[start] != ' '))
      {
        --start;
      }
      start++;
      VERB(verbose, printf("      Corresponding marker found\n"));

      char marker[end - start];
      marker[0] = '\0';

      VERB(verbose, printf("      Copying marker ...\n"));
      strncat(marker, (*buffer) + start, end - start);
      VERB(verbose, printf("      Marker successfully copied\n"));

      VERB(verbose, printf("      Replacing original log data by marker \
...\n"));
      if (roadmap->id == IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM)
      {
        roadmap->id = REPLACE_REGCOMP_FAILED_RM;
      } else if (roadmap->id == IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM) {
        roadmap->id = REPLACE_REALLOC_FAILED_RM;
      } else if (roadmap->id == IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM) {
        roadmap->id = REPLACE_REGEXEC_FAILED_RM;
      }

      if (!replace(message, STARTLINE_SHADERLOG_PATTERN, marker, "  ",
        verbose, roadmap))
      {
        VERB(verbose, fprintf(stderr, "      "));
        fprintf(stderr, "replace() failed\n");
        regfree(&regex);
        return false;
      }
      VERB(verbose, printf("      Log data replaced\n"));

      VERB(verbose, printf("      Comparing regex pattern ...\n"));
      match = regexec(&regex, *message, nmatch + 1, m, 0);
    }

    VERB(verbose, printf("      Searching for regex error ...\n"));
    if ((match != REG_NOMATCH)
      || (roadmap->id == IMPROVELOGSHADER_REGEXEC_FAILED_RM))
    {
      if (roadmap->id != IMPROVELOGSHADER_REGEXEC_FAILED_RM)
      {
        regex_error = 1;
        size_t size = regerror(regex_error, &regex, NULL, 0);
        VERB(verbose, printf("      Message size of regex error is %lu\n",
          size));

        char text[size];

        regerror(regex_error, &regex, &(text[0]), size);

        VERB(verbose, printf("      Freeing regex structure ...\n"));
        regfree(&regex);
        VERB(verbose, printf("      Memory freed successfully\n"));

        VERB(verbose, fprintf(stderr, "      "));
        fprintf(stderr, "Regex error: %s\n", text);
        return false;
      } else {
        VERB(verbose, printf("      Freeing regex structure ...\n"));
        regfree(&regex);
        VERB(verbose, printf("      Memory freed successfully\n"));

        return false;
      }
    }
    VERB(verbose, printf("      No regex error. Regex pattern not found\n"));
  } else {
    VERB(verbose, fprintf(stderr, "      "));
    fprintf(stderr, "Regex compilation failed\n");
    return false;
  }

  VERB(verbose, printf("      Freeing regex structure ...\n"));
  regfree(&regex);
  VERB(verbose, printf("      Memory freed successfully\n"));

  return true;
}
