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

bool regex_replace(char** str, const char* pattern, const char* replace,
  const char* spaces, bool verbose, enum Roadmap roadmap)
{
  regex_t regex;

  VERB(verbose, printf("%s      Compiling regex pattern: \"%s\" ...\n",
    spaces, pattern));
  if (regcomp(&regex, pattern, REG_EXTENDED | REG_NEWLINE) == 0)
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
    if (regexec(&regex, *str, nmatch + 1, m, 0) == 0)
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
      *str = realloc(*str, sizeof(char) * (strlen(new) + 1));
      if (!*str)
      {
        VERB(verbose, fprintf(stderr, "%s      ", spaces));
        fprintf(stderr, "*str realloc() failed\n");
        return false;
      }
      VERB(verbose, printf("%s      Memory reallocated successfully\n",
        spaces));

      VERB(verbose, printf("%s      Copying new in *str ...\n", spaces));
      strcpy(*str, new);
      VERB(verbose, printf("%s      Copied successfully\n", spaces));
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
  bool verbose, enum Roadmap roadmap)
{
  long length;

  VERB(verbose, printf("%s      Opening \"%s\" ...\n", spaces, *filepath));
  FILE* f = NULL;

  if (roadmap != FOPEN_FAILED_RM)
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
    length = ftell(f);
    VERB(verbose, printf("%s      File position of the stream computed\n",
      spaces));

    VERB(verbose, printf("%s      Setting file position of the stream to the \
beginning ...\n", spaces));
    fseek(f, 0, SEEK_SET);
    VERB(verbose, printf("%s      Stream positionned\n", spaces));

    VERB(verbose, printf("%s      Allocating memory for reading file buffer \
...\n", spaces));
    if ((roadmap != BUFFER_MALLOC_FAILED_RM) &&
      (roadmap != SHADER_COMPILATION_FAILED_RM) &&
      (roadmap != LINKING_PROGRAM_FAILED_RM))
    {
      *buffer = malloc(length);
    }

    if (*buffer)
    {
      VERB(verbose, printf("%s      Memory for reading file buffer \
allocated successfully\n", spaces));

      VERB(verbose, printf("%s      Reading file into buffer ...\n", spaces))
      if ((roadmap != SHADER_COMPILATION_FAILED_RM) &&
        (roadmap != LINKING_PROGRAM_FAILED_RM))
      {
        fread(*buffer, 1, length - 1, f);
        (*buffer)[length - 1] = '\0'; // fread does not 0 terminate strings
      }
      VERB(verbose, printf("%s      Buffer filled with:\n\
------------------------------------------------------------------------------\
\n%s\n\
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
  bool is_main, const char* spaces, bool verbose, enum Roadmap roadmap)
{
  size_t i = 0;
  size_t j = 0;

  size_t marker_length;
  char* header;
  size_t header_length = 0;
  unsigned line = 1;

  FILE* file = NULL;
  char tmp_ch;
  unsigned lines_header;

  VERB(verbose, printf("%s    Computing length of buffer file ...\n",
    spaces));
  size_t buffer_length = strlen(*buffer);
  VERB(verbose, printf("%s    Length of buffer file is %lu\n", spaces,
    buffer_length));

  VERB(verbose, printf("%s    Iterating over the buffer ...\n", spaces));
  while (i <= buffer_length)
  {
    if (((*buffer)[i] == '\n') || (is_main && ((*buffer)[i] == '\0')))
    {
      VERB(verbose, printf("%s      New line detected\n", spaces));

      VERB(verbose, printf("%s      Computing length of marker ...\n",
        spaces));
      marker_length = strlen(*filename) + strlen(" // :") +
        floor(log10(line)) + 1 + 1;
      if (header_length > 0)
      {
        marker_length += header_length + strlen(" // :") +
          floor(log10(lines_header)) + 1;
      }
      VERB(verbose, printf("%s      Length of marker is %lu\n", spaces,
        marker_length));

      VERB(verbose, printf("%s      Building marker ...\n", spaces));
      char marker[marker_length];
      if (header_length > 0)
      {
        snprintf(marker, marker_length + 1, " // %s:%u // %s:%u", *filename,
          line, header, lines_header);
      } else {
        snprintf(marker, marker_length + 1, " // %s:%u", *filename, line);
      }
      VERB(verbose, printf("%s      Marker is \"%s\"\n", spaces, marker));

      char new[strlen(*buffer) + marker_length];
      new[0] = '\0';

      VERB(verbose, printf("%s      Building new file buffer ...\n",
        spaces));

      VERB(verbose, printf("%s        Copying first file buffer part \
...\n", spaces));
      strncat(new, *buffer, i);
      VERB(verbose, printf("%s        First file buffer part copied \
successfully\n", spaces));

      VERB(verbose, printf("%s        Concatenating marker ...\n", spaces));
      strncat(new, marker, marker_length);
      VERB(verbose, printf("%s        Marker concatenated\n", spaces));

      VERB(verbose, printf("%s        Concatenating last file buffer part \
...\n", spaces));
      strncat(new, *buffer + i, strlen(*buffer) - i);
      VERB(verbose, printf("%s        Last file buffer part concatenated \
successfully\n", spaces));

      VERB(verbose, printf("%s      New buffer file built\n", spaces));

      VERB(verbose, printf("%s      Reallocating memory for buffer ...\n",
        spaces));
      *buffer = realloc(*buffer, sizeof(char) * (strlen(new) + 1));
      if (!buffer)
      {
        VERB(verbose, fprintf(stderr, "%s      ", spaces));
        fprintf(stderr, "realloc() buffer failed\n");
        return false;
      }
      VERB(verbose, printf("%s      Memory reallocated successfully\n",
        spaces));

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

      if (header_length > 0)
      {
        header_length = 0;

        VERB(verbose, printf("%s      Freeing header marker ...\n",
          spaces));
        free(header);
        VERB(verbose, printf("%s      Memory freed successfully\n",
          spaces));
      }
    } else if (i > 9) {
      if (((*buffer)[i - 10] == '#') && ((*buffer)[i - 9] == 'i') &&
        ((*buffer)[i - 8] == 'n') && ((*buffer)[i - 7] == 'c') &&
        ((*buffer)[i - 6] == 'l') && ((*buffer)[i - 5] == 'u') &&
        ((*buffer)[i - 4] == 'd') && ((*buffer)[i - 3] == 'e') &&
        ((*buffer)[i - 2] == ' ') && ((*buffer)[i - 1] == '\"'))
      {
        VERB(verbose, printf("%s      Header line detected\n", spaces));
        VERB(verbose, printf("%s      First index of the header name \
at %lu\n", spaces, i));

        VERB(verbose, printf("%s      Iterating until the second double \
quotes character ...\n", spaces));
        j = i + 1;
        while ((*buffer)[j] != '\"')
        {
          ++j;
        }
        VERB(verbose, printf("%s      Second double quotes of header line \
found at %lu\n", spaces, j));

        header_length = j - i;
        VERB(verbose, printf("%s      Header length is %lu\n", spaces,
          header_length));

        VERB(verbose, printf("%s      Allocating memory for header file \
name ...\n", spaces));
        header = malloc(sizeof(char) * (header_length + 1));
        if (!header)
        {
          VERB(verbose, fprintf(stderr, "%s      ", spaces));
          fprintf(stderr, "malloc() header failed\n");
          return false;
        }
        *header = '\0';
        VERB(verbose, printf("%s      Memory allocated successfully\n",
          spaces));

        VERB(verbose, printf("%s      Copying header file name ...\n",
          spaces));
        strncat(header, *buffer + i, header_length);
        VERB(verbose, printf("%s      Header file name copied \
successfully\n", spaces));

        char new[strlen(dir_path) + header_length];
        new[0] = '\0';

        VERB(verbose, printf("%s      Copying absolute directory path into \
temporary variable ...\n", spaces));
        strcat(new, dir_path);
        VERB(verbose, printf("%s      Absolute directory path copied \
successfully\n", spaces));

        VERB(verbose, printf("%s      Concatenating header file name into \
temporary variable ...\n", spaces));
        strcat(new, header);
        VERB(verbose, printf("%s      Header file name concatenated \
successfully\n", spaces));

        VERB(verbose, printf("%s      Opening \"%s\" ...\n", spaces, new));
        file = fopen(new, "r");
        if (!file)
        {
          VERB(verbose, fprintf(stderr, "%s      ", spaces));
          fprintf(stderr, "Failed to read inside \"%s\": %s\n", new,
            strerror(errno));
          return false;
        }
        VERB(verbose, printf("%s      File opened successfully\n", spaces));

        VERB(verbose, printf("%s      Computing number of line into \"%s\" \
...\n", spaces, new));
        lines_header = 0;
        while ((tmp_ch = fgetc(file)) != EOF)
        {
          if (tmp_ch == '\n')
          {
            lines_header++;
          }
        }
        VERB(verbose, printf("%s      The file contains %u lines\n", spaces,
          lines_header));

        VERB(verbose, printf("%s      Closing \"%s\" ...\n", spaces, new));
        fclose(file);
        VERB(verbose, printf("%s      File closed successfully\n", spaces));

        i = j;
      }
    }
    ++i;
  }

  return true;
}

bool searchAndReplaceHeaders(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap)
{
  Regex regex;
  regex.header_buffer = NULL;
  regex.headers = NULL;
  regex.headers_length = 1;

  char dir_path[strlen(*filepath) - 9];
  dir_path[0] = '\0';

  VERB(verbose, printf("    Copying string into dir_path ...\n"));
  strncat(dir_path, *filepath, strlen(*filepath) - 9);
  VERB(verbose, printf("    \"%s\" successfully copied\n", dir_path));

  VERB(verbose, printf("    Compiling regex pattern: \"%s\" ...\n",
    INCLUDE_HEADER_PATTERN));
  int regex_error = regcomp(&(regex.regex), INCLUDE_HEADER_PATTERN,
    REG_EXTENDED | REG_NEWLINE);

  if (regex_error == 0)
  {
    VERB(verbose, printf("    Regex pattern compiled successfully\n"));

    size_t nmatch = regex.regex.re_nsub;
    VERB(verbose, printf("    Regex subexpressions found: %lu\n", nmatch));

    regmatch_t m[nmatch + 1];

    bool is_already_included = false;

    VERB(verbose, printf("    Allocating memory for headers ...\n");)
    regex.headers = malloc(sizeof(char*));
    if (!regex.headers)
    {
      VERB(verbose, fprintf(stderr, "    "));
      fprintf (stderr, "headers malloc() failed\n");
      freeRegex(&regex, "", verbose);
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));

    regex.headers_length = 1;
    VERB(verbose, printf("    Allocating memory for headers[0] ...\n");)
    (regex.headers)[0] = malloc(sizeof(char) * (strlen("main.glsl") + 1));
    if (!(regex.headers)[0])
    {
      VERB(verbose, fprintf(stderr, "    "));
      fprintf (stderr, "headers[0] malloc() failed\n");
      freeRegex(&regex, "", verbose);
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));

    VERB(verbose, printf("    Copying string into headers[0] ...\n"));
    strcpy((regex.headers)[0], "main.glsl");
    (regex.headers)[0][strlen((regex.headers)[0])] = '\0';
    VERB(verbose, printf("    \"%s\" successfully copied\n",
      (regex.headers)[0]));

    VERB(verbose, printf("    Adding markers to \"%s\" ...\n",
      (regex.headers)[0]));
    if (!addMarkers(&((regex.headers)[0]), buffer, dir_path, true, "",
      verbose, roadmap))
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
      start_header = m[0].rm_so + 10;
      VERB(verbose, printf("    Start index of header is %lu\n",
        start_header));
      end_header = m[0].rm_eo - 1;
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
\"%s\" line into buffer file with regex_replace() ...\n", first_match));
        if (!regex_replace(buffer, INCLUDE_HEADER_PATTERN, "", "  ", verbose,
          roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "regex_replace() failed\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      Line successfully deleted\n"));
      } else {

        VERB(verbose, printf("      \"%s\" is not already included\n",
          first_match));

        regex.headers_length++;

        VERB(verbose, printf("      Reallocating memory for headers ...\n");)
        regex.headers = realloc(regex.headers,
          sizeof(char*) * regex.headers_length);
        if (!regex.headers)
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf (stderr, "headers realloc() failed\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      Memory reallocated successfully\n"));

        VERB(verbose, printf("      Allocating memory for headers[%lu] \
...\n", regex.headers_length - 1);)
        (regex.headers)[regex.headers_length - 1] =
          malloc(sizeof(char) * (end_header - start_header + 1));
        if (!(regex.headers)[regex.headers_length - 1])
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf (stderr, "headers[%lu] malloc() failed\n",
            regex.headers_length - 1);
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      Memory allocated successfully\n"));

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
        if (!readFile(&header_filepath_p, &(regex.header_buffer), "  ",
          verbose, roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "Failed to read file\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      File read successfully\n"));

        VERB(verbose, printf("      Adding markers to \"%s\" ...\n",
          (regex.headers)[regex.headers_length - 1]));
        if (!addMarkers(&((regex.headers)[regex.headers_length - 1]),
          &(regex.header_buffer), dir_path, false, "  ", verbose, roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "Unable to mark the file\n");
          freeRegex(&regex, "  ", verbose);
          return false;
        }
        VERB(verbose, printf("      Markers added\n"));

        VERB(verbose, printf("      Replacing header \"%s\" by its content \
into buffer file ...\n", first_match));
        if (!regex_replace(buffer, INCLUDE_HEADER_PATTERN,
          regex.header_buffer, "  ", verbose, roadmap))
        {
          VERB(verbose, fprintf(stderr, "      "));
          fprintf(stderr, "regex_replace() failed\n");
          freeRegex(&regex, "  ", verbose);
          return false;
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
    VERB(verbose, printf("    File buffer is now:\n\
------------------------------------------------------------------------------\
\n%s\n\
------------------------------------------------------------------------------\
\n", *buffer));

    freeRegex(&regex, "", verbose);

    if (match != REG_NOMATCH)
    {
      VERB(verbose, printf("    Searching for regex error ...\n"));
      size_t size = regerror(regex_error, &(regex.regex), NULL, 0);
      VERB(verbose, printf("    Size of regex error is %lu\n", size));

      char text[size];

      regerror(regex_error, &(regex.regex), &(text[0]), size);
      VERB(verbose, fprintf(stderr, "    "));
      fprintf(stderr, "Regex error: %s\n", text);
    }
  } else {
    VERB(verbose, fprintf(stderr, "    "));
    fprintf(stderr, "Regex compilation failed\n");
    return false;
  }

  return true;
}

bool improveLogShader(char** message, char** buffer, size_t maxLength,
  bool verbose, enum Roadmap roadmap)
{
  regex_t regex;

  VERB(verbose, printf("    Compiling regex pattern: \"%s\" ...\n",
    STARTLINE_SHADERLOG_PATTERN));
  if (regcomp(&regex, STARTLINE_SHADERLOG_PATTERN, REG_EXTENDED | REG_NEWLINE)
    == 0)
  {
    VERB(verbose, printf("    Regex pattern compiled successfully\n"));

    size_t nmatch = regex.re_nsub;
    VERB(verbose, printf("    Regex subexpressions found: %lu\n", nmatch));

    regmatch_t m[nmatch + 1];

    VERB(verbose, printf("    Comparing regex pattern ...\n"));
    int match = regexec(&regex, *message, nmatch + 1, m, 0);

    size_t start;
    size_t end;

    unsigned l;

    while (match == 0)
    {
      VERB(verbose, printf("    Regex pattern found\n"));

      start = m[1].rm_so;
      VERB(verbose, printf("    Start index of parenthesis expression is \
%lu\n", start));
      end = m[1].rm_eo;
      VERB(verbose, printf("    End index of parenthesis expression is %lu\n",
        end));

      char line[end - start];
      line[0] = '\0';

      VERB(verbose, printf("    Copying line number of buffer file error \
...\n"));
      strncat(line, *message + start, end - start);
      VERB(verbose, printf("    Line number successfully copied\n"));

      VERB(verbose, printf("    Casting line number string to unsigned int \
...\n"));
      l = strtoul(line, NULL, 10);
      VERB(verbose, printf("    Line number successfully casted\n"));

      VERB(verbose, printf("    Line number is %u\n", l));

      unsigned i = 0;
      end = 0;

      VERB(verbose, printf("    Searching corresponding line into buffer \
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
        printf("    Corresponding line is \"%s\"\n", buffer_line););

      start = end;
      while ((*buffer)[start] != '/')
      {
        --start;
      }
      start += 2;

      char marker[end - start];
      marker[0] = '\0';
      strncat(marker, (*buffer) + start, end - start);

      regex_replace(message, STARTLINE_SHADERLOG_PATTERN, marker, "", verbose,
        roadmap);

      match = regexec(&regex, *message, nmatch + 1, m, 0);
    }
  } else {
    VERB(verbose, fprintf(stderr, "    "));
    fprintf(stderr, "Regex compilation failed\n");
    return false;
  }

  regfree(&regex);

  return true;
}
