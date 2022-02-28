#include "parser.h"

void freeRegex(Regex* regex, const char* spaces, Log* log)
{
  if (regex->header_buffer)
  {
    writeLog(log, stdout, DEBUG, "", "%s    Freeing header_buffer memory ...\n",
      spaces);
    free(regex->header_buffer);
    regex->header_buffer = NULL;
    writeLog(log, stdout, DEBUG, "", "%s    Memory freed successfully\n",
      spaces);
  }

  if (regex->headers)
  {
    for (size_t i = 0; i < regex->headers_length; ++i)
    {
      writeLog(log, stdout, DEBUG, "",
        "%s    Freeing headers[%lu] memory ...\n", spaces, i);
      free((regex->headers)[i]);
      writeLog(log, stdout, DEBUG, "", "%s    Memory freed successfully\n",
        spaces);
    }

    writeLog(log, stdout, DEBUG, "", "%s    Freeing headers memory ...\n",
      spaces);
    free(regex->headers);
    regex->headers = NULL;
    writeLog(log, stdout, DEBUG, "", "%s    Memory freed successfully\n",
      spaces);
  }

  writeLog(log, stdout, DEBUG, "", "%s    Freeing regex structure ...\n",
    spaces);
  regfree(&(regex->regex));
  writeLog(log, stdout, DEBUG, "", "%s    Memory freed successfully\n", spaces);
}

bool replace(char** str, const char* pattern, const char* replace,
  const char* spaces, Log* log)
{
  bool status = true;

  do
  {
    regex_t regex;

    writeLog(log, stdout, DEBUG, "",
      "%s      Compiling regex pattern: \"%s\" ...\n", spaces, pattern);

    if ((log->roadmap.id != REPLACE_REGCOMP_FAILED_RM) &&
      (regcomp(&regex, pattern, REG_EXTENDED | REG_NEWLINE) == 0))
    {
      writeLog(log, stdout, DEBUG, "",
        "%s      Regex pattern compiled successfully\n", spaces);

      size_t nmatch = regex.re_nsub;
      writeLog(log, stdout, DEBUG, "",
        "%s      Regex subexpressions found: %lu\n", spaces, nmatch);

      regmatch_t m[nmatch + 1];

      size_t start;
      size_t end;

      // replace only first occurence
      writeLog(log, stdout, DEBUG, "", "%s      Comparing regex pattern ...\n",
        spaces);
      int match = regexec(&regex, *str, nmatch + 1, m, 0);
      if ((match == 0) && (log->roadmap.id != REPLACE_REGEXEC_FAILED_RM))
      {
        writeLog(log, stdout, DEBUG, "", "%s      Regex pattern found\n",
          spaces);

        start = m[0].rm_so;
        writeLog(log, stdout, DEBUG, "",
          "%s      Start index of first match is %lu\n", spaces, start);
        end = m[0].rm_eo;
        writeLog(log, stdout, DEBUG, "",
          "%s      End index of first match is %lu\n", spaces, end);

        char new[strlen(*str) + strlen(replace)];
        new[0] = '\0';

        writeLog(log, stdout, DEBUG, "", "%s      Building new string ...\n",
          spaces);
        writeLog(log, stdout, DEBUG, "", "%s        Copying first part %s",
          spaces, "of the original string ...\n");
        strncat(new, *str, start);
        writeLog(log, stdout, DEBUG, "",
          "%s        Strings copied successfully\n", spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s        Concatenating replaced part ...\n", spaces);
        strcat(new, replace);
        writeLog(log, stdout, DEBUG, "",
          "%s        Replaced part added successfully\n", spaces);

        writeLog(log, stdout, DEBUG, "", "%s        Concatenating last %s",
          spaces, "part of the original string ...\n");
        strncat(new, *str + end, strlen(*str) - end);
        writeLog(log, stdout, DEBUG, "",
          "%s        Strings concatenated successfully\n", spaces);
        writeLog(log, stdout, DEBUG, "", "%s      New string built\n", spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s      Reallocating memory for *str ...\n", spaces);
        if (log->roadmap.id != REPLACE_REALLOC_FAILED_RM)
        {
          *str = realloc(*str, sizeof(char) * (strlen(new) + 1));
        } else {
          free(*str);
          *str = NULL;
        }

        if (!*str)
        {
          writeLog(log, (log->verbose ? stdout : stderr), ERROR,
            (strlen(spaces) > 0 ? "        " : "      "),
            "*str realloc() failed\n");
          regfree(&regex);

          status = false;
          break;
        }
        writeLog(log, stdout, DEBUG, "",
          "%s      Memory reallocated successfully\n", spaces);

        writeLog(log, stdout, DEBUG, "", "%s      Copying new in *str ...\n",
          spaces);
        strcpy(*str, new);
        writeLog(log, stdout, DEBUG, "", "%s      Copied successfully\n",
          spaces);
      } else if ((match == REG_NOMATCH)
        && (log->roadmap.id != REPLACE_REGEXEC_FAILED_RM)) {
          writeLog(log, stdout, DEBUG, "", "%s      Regex pattern not found\n",
            spaces);
      } else {
        if (log->roadmap.id != REPLACE_REGEXEC_FAILED_RM)
        {
          int regex_error = 1;
          size_t size = regerror(regex_error, &regex, NULL, 0);
          writeLog(log, stdout, DEBUG, "",
            "%s      Message size of regex error is %lu\n", spaces, size);

          char text[size];

          regerror(regex_error, &regex, &(text[0]), size);

          writeLog(log, stdout, DEBUG, "",
            "%s      Freeing regex structure ...\n", spaces);
          regfree(&regex);
          writeLog(log, stdout, DEBUG, "",
            "%s      Memory freed successfully\n", spaces);

          writeLog(log, (log->verbose ? stdout : stderr), ERROR,
            (strlen(spaces) > 0 ? "        " : "      "),
            "Regex error: %s\n", text);

          status = false;
          break;
        } else {
          writeLog(log, stdout, DEBUG, "",
            "%s      Freeing regex structure ...\n", spaces);
          regfree(&regex);
          writeLog(log, stdout, DEBUG, "",
            "%s      Memory freed successfully\n", spaces);

          status = false;
          break;
        }
      }

      writeLog(log, stdout, DEBUG, "", "%s      Freeing regex structure ...\n",
        spaces);
      regfree(&regex);
      writeLog(log, stdout, DEBUG, "", "%s      Memory freed successfully\n",
        spaces);

      break;
    } else {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "",
        (strlen(spaces) ? "        " : "      "),
        "Regex compilation failed\n");

      status = false;
      break;
    }
  } while (false);

  return status;
}

bool readFile(char** filepath, char** buffer, const char* spaces, Log* log)
{
  bool status = true;

  do
  {
    long length;

    writeLog(log, stdout, INFO, "", "%s      Opening \"%s\" ...\n", spaces,
      *filepath);
    FILE* f = NULL;

    if (log->roadmap.id != FOPEN_FAILED_RM)
    {
      f = fopen(*filepath, "rb");
    }

    if (f)
    {
      writeLog(log, stdout, INFO, "", "%s      File opened successfully\n",
        spaces);

      writeLog(log, stdout, DEBUG, "",
        "%s      Setting file position of the stream to the end ...\n",
        spaces);
      fseek(f, 0, SEEK_END);
      writeLog(log, stdout, DEBUG, "", "%s      Stream positionned\n", spaces);

      writeLog(log, stdout, DEBUG, "",
        "%s      Computing file position of the stream ...\n", spaces);
      char relative_path[19];
      strncpy(relative_path, *filepath + (strlen(*filepath) - 18), 18);
      relative_path[18] = '\0';
      if (((log->roadmap.id == VERTEX_SHADER_COMPILATION_FAILED_RM)
        || (log->roadmap.id == VERTEX_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
        || (log->roadmap.id == VERTEX_FILE_ILS_REPLACE_REALLOC_FAILED_RM)
        || (log->roadmap.id == VERTEX_FILE_ILS_REPLACE_REGEXEC_FAILED_RM)
        || (log->roadmap.id == VERTEX_FILE_ILS_REGCOMP_FAILED_RM)
        || (log->roadmap.id == VERTEX_FILE_ILS_REGEXEC_FAILED_RM))
        && (strcmp(relative_path, "s/vertex/main.glsl") == 0))
      {
        length = ERRONEOUS_VERTEX_SHADER;
      } else if (((log->roadmap.id == FRAGMENT_SHADER_COMPILATION_FAILED_RM)
        || (log->roadmap.id == FRAGMENT_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
        || (log->roadmap.id == FRAGMENT_FILE_ILS_REPLACE_REALLOC_FAILED_RM)
        || (log->roadmap.id == FRAGMENT_FILE_ILS_REPLACE_REGEXEC_FAILED_RM)
        || (log->roadmap.id == FRAGMENT_FILE_ILS_REGCOMP_FAILED_RM)
        || (log->roadmap.id == FRAGMENT_FILE_ILS_REGEXEC_FAILED_RM))
        && (strcmp(relative_path, "fragment/main.glsl") == 0)) {
          length = ERRONEOUS_FRAGMENT_SHADER;
      } else if ((log->roadmap.id == LINKING_PROGRAM_FAILED_RM)
        && (strcmp(relative_path, "s/vertex/main.glsl") == 0)) {
          length = MISSINGMAIN_VERTEX_SHADER;
      } else {
        length = ftell(f);
      }
      writeLog(log, stdout, DEBUG, "",
        "%s      File position of the stream computed\n", spaces);

      writeLog(log, stdout, DEBUG, "",
        "%s      Setting file position of the stream to the beginning ...\n",
        spaces);
      fseek(f, 0, SEEK_SET);
      writeLog(log, stdout, DEBUG, "", "%s      Stream positionned\n", spaces);

      writeLog(log, stdout, DEBUG, "",
        "%s      Allocating memory for reading file buffer ...\n", spaces);
      if (log->roadmap.id != BUFFER_MALLOC_FAILED_RM)
      {
        *buffer = malloc(length + 1);
      }

      if (*buffer)
      {
        writeLog(log, stdout, DEBUG, "",
          "%s      Memory for reading file buffer allocated successfully\n",
          spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s      Reading file into buffer ...\n", spaces);
        fread(*buffer, 1, length, f);
        // fread does not 0 terminate strings
        (*buffer)[length] = '\0';
        writeLog(log, stdout, DEBUG, "",
          "%s      Buffer filled with:\n%s\n%s%s\n", spaces, BAR, *buffer, BAR);

      } else {
        writeLog(log, (log->verbose ? stdout : stderr), ERROR,
          (strlen(spaces) > 0 ? "        " : "      "),
          "Buffer malloc() failed\n");

        status = false;
        break;
      }

      writeLog(log, stdout, DEBUG, "", "%s      Closing \"%s\" ...\n", spaces,
        *filepath);
      fclose(f);
      writeLog(log, stdout, DEBUG, "", "%s      File closed successfully\n",
        spaces);

    } else {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR,
        (strlen(spaces) > 0 ? "        " : "      "),
        "Failed to read inside \"%s\": %s\n", *filepath, strerror(errno));

      status = false;
      break;
    }
  } while (false);

  return status;
}

bool addMarkers(char** filename, char** buffer, const char* spaces, Log* log)
{
  bool status = true;

  do
  {
    size_t i = 0;

    size_t marker_length;
    unsigned line = 1;

    writeLog(log, stdout, DEBUG, "",
      "%s    Computing length of buffer file ...\n", spaces);
    size_t buffer_length = strlen(*buffer);
    writeLog(log, stdout, DEBUG, "", "%s    Length of buffer file is %lu\n",
      spaces, buffer_length);

    writeLog(log, stdout, DEBUG, "",
      "%s    Computing lines number in buffer file ...\n", spaces);
    unsigned buffer_lines = 0;
    while (i <= buffer_length)
    {
      if ((*buffer)[i] == '\n')
      {
        ++buffer_lines;
      }
      ++i;
    }
    writeLog(log, stdout, DEBUG, "",
      "%s    Lines number of buffer file is %u\n", spaces, buffer_lines);

    i = 0;

    writeLog(log, stdout, DEBUG, "",
      "%s    Reallocating memory for buffer ...\n", spaces);
    if ((log->roadmap.id != SARH_ADDMARKERS_REALLOC_FAILED_RM)
      || (strcmp(log->roadmap.glsl_file, *filename) != 0))
    {
      *buffer = realloc(*buffer, sizeof(char) * (buffer_length + 1 +
        (strlen(*filename) + strlen(" // :") + floor(log10(buffer_lines)) + 1)
        * buffer_lines));
    } else {
      free(*buffer);
      *buffer = NULL;
    }

    if (!*buffer)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR,
        (strlen(spaces) > 0 ? "        " : "      "),
        "realloc() buffer failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "%s    Memory reallocated successfully\n",
      spaces);

    writeLog(log, stdout, DEBUG, "", "%s    Iterating over the buffer ...\n",
      spaces);
    while (i <= buffer_length)
    {
      if ((*buffer)[i] == '\n')
      {
        writeLog(log, stdout, DEBUG, "", "%s      New line detected\n", spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s      Computing length of marker ...\n", spaces);
        marker_length = strlen(*filename) + strlen(" // :") +
          floor(log10(line)) + 1 + 1;
        writeLog(log, stdout, DEBUG, "", "%s      Length of marker is %lu\n",
          spaces, marker_length);

        writeLog(log, stdout, DEBUG, "", "%s      Building marker ...\n",
          spaces);
        char marker[marker_length];
        snprintf(marker, marker_length + 1, " // %s:%u", *filename, line);
        writeLog(log, stdout, DEBUG, "", "%s      Marker is \"%s\"\n",
          spaces, marker);

        writeLog(log, stdout, DEBUG, "",
          "%s      Building new file buffer ...\n", spaces);

        char new[buffer_length + marker_length];
        new[0] = '\0';

        writeLog(log, stdout, DEBUG, "",
          "%s        Copying first file buffer part ...\n", spaces);
        strncat(new, *buffer, i);
        writeLog(log, stdout, DEBUG, "",
          "%s        First file buffer part copied successfully\n", spaces);

        writeLog(log, stdout, DEBUG, "", "%s        Concatenating marker ...\n",
          spaces);
        strcat(new, marker);
        writeLog(log, stdout, DEBUG, "", "%s        Marker concatenated\n",
          spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s        Concatenating last file buffer part ...\n", spaces);
        strncat(new, *buffer + i, buffer_length - i);
        writeLog(log, stdout, DEBUG, "",
          "%s        Last file buffer part concatenated successfully\n",
          spaces);

        writeLog(log, stdout, DEBUG, "", "%s      New buffer file built\n",
          spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s      Copying temporary variable into file buffer ...\n", spaces);
        strcpy(*buffer, new);
        writeLog(log, stdout, DEBUG, "",
          "%s      Temporary variable copied successfully\n", spaces);

        writeLog(log, stdout, DEBUG, "",
          "%s      Recomputing length of buffer file ...\n", spaces);
        buffer_length = strlen(*buffer);
        writeLog(log, stdout, DEBUG, "",
          "%s      Length of buffer files is %lu\n", spaces, buffer_length);

        writeLog(log, stdout, DEBUG, "",
          "%s      Iterating until the end of the newly created marker ...\n",
          spaces);
        while (((*buffer)[i] != '\n') && ((*buffer)[i] != '\0'))
        {
          ++i;
        }
        writeLog(log, stdout, DEBUG, "", "%s      Marker found\n", spaces);
        ++line;
      }
      ++i;
    }
  } while (false);

  return status;
}

bool searchAndReplaceHeaders(char** dirpath, char** buffer, Log* log)
{
  bool status = true;

  do
  {
    Regex regex;
    regex.header_buffer = NULL;
    regex.headers = NULL;
    regex.headers_length = 0;

    writeLog(log, stdout, DEBUG, "",
      "    Compiling regex pattern: \"%s\" ...\n", INCLUDE_HEADER_PATTERN);
    int regex_error = 1;
    if (log->roadmap.id != SARH_REGCOMP_FAILED_RM)
    {
      regex_error = regcomp(&(regex.regex), INCLUDE_HEADER_PATTERN,
        REG_EXTENDED | REG_NEWLINE);
    }

    if (regex_error == 0)
    {
      writeLog(log, stdout, DEBUG, "",
        "    Regex pattern compiled successfully\n");

      size_t nmatch = regex.regex.re_nsub;
      writeLog(log, stdout, DEBUG, "", "    Regex subexpressions found: %lu\n",
        nmatch);

      regmatch_t m[nmatch + 1];

      bool is_already_included = false;

      writeLog(log, stdout, DEBUG, "",
        "    Allocating memory for headers ...\n");
      if (log->roadmap.id != SARH_HEADERS_MALLOC_FAILED_RM)
      {
        regex.headers = malloc(sizeof(char*));
      }

      if (!regex.headers)
      {
        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
          "headers malloc() failed\n");
        freeRegex(&regex, "", log);

        status = false;
        break;
      }
      writeLog(log, stdout, DEBUG, "", "    Memory allocated successfully\n");

      writeLog(log, stdout, DEBUG, "",
        "    Allocating memory for headers[0] ...\n");
      if ((log->roadmap.id != SARH_HEADER_MALLOC_FAILED_RM)
        || (strcmp(log->roadmap.glsl_file, "main.glsl") != 0))
      {
        (regex.headers)[0] = malloc(sizeof(char) * (strlen("main.glsl") + 1));
      } else {
        (regex.headers)[0] = NULL;
      }

      if (!(regex.headers)[0])
      {
        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
          "headers[0] malloc() failed\n");
        freeRegex(&regex, "", log);

        status = false;
        break;
      }
      writeLog(log, stdout, DEBUG, "", "    Memory allocated successfully\n");
      regex.headers_length = 1;

      writeLog(log, stdout, DEBUG, "",
        "    Copying string into headers[0] ...\n");
      strcpy((regex.headers)[0], "main.glsl");
      (regex.headers)[0][strlen((regex.headers)[0])] = '\0';
      writeLog(log, stdout, DEBUG, "", "    \"%s\" successfully copied\n",
        (regex.headers)[0]);

      writeLog(log, stdout, DEBUG, "", "    Adding markers to \"%s\" ...\n",
        (regex.headers)[0]);
      if (!addMarkers(&((regex.headers)[0]), buffer, "", log))
      {
        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
          "Unable to mark the file\n");
        freeRegex(&regex, "", log);

        status = false;
        break;
      }
      writeLog(log, stdout, DEBUG, "", "    Markers added:\n%s\n%s%s\n", BAR,
        *buffer, BAR);

      writeLog(log, stdout, DEBUG, "",
        "    Comparing regex pattern to buffer file ...\n");
      int match = regexec(&(regex.regex), *buffer, nmatch + 1, m, 0);

      size_t start_header;
      size_t end_header;

      while (match == 0)
      {
        writeLog(log, stdout, DEBUG, "",
          "    Regex pattern found into buffer file\n");
        start_header = m[1].rm_so;
        writeLog(log, stdout, DEBUG, "", "    Start index of header is %lu\n",
          start_header);
        end_header = m[1].rm_eo;
        writeLog(log, stdout, DEBUG, "", "    End index of header is %lu\n",
          end_header);

        char first_match[end_header - start_header];
        writeLog(log, stdout, DEBUG, "", "    Header length is %lu\n",
          end_header - start_header);

        first_match[0] = '\0';

        writeLog(log, stdout, DEBUG, "",
          "      Copying into first_match ...\n");
        strncat(first_match, (*buffer) + start_header,
          end_header - start_header);
        writeLog(log, stdout, DEBUG, "", "      \"%s\" successfully copied\n",
          first_match);

        writeLog(log, stdout, DEBUG, "",
          "      Comparing first_match to the cache ...\n");
        is_already_included = false;
        for (size_t i = 0; (i < regex.headers_length) &&
          !is_already_included; ++i)
        {
          writeLog(log, stdout, DEBUG, "",
            "        Comparing \"%s\" to \"%s\" ...\n",
            (regex.headers)[i], first_match);
          is_already_included |= (strcmp((regex.headers)[i], first_match) == 0);
          writeLog(log, stdout, DEBUG, "", "        %s\n",
            is_already_included ? "Same strings" : "Not same strings");
        }

        if (is_already_included)
        {
          writeLog(log, stdout, DEBUG, "", "      \"%s\" is already included\n",
            first_match);

          writeLog(log, stdout, DEBUG, "", "      Deleting %s \"%s\" %s\n",
            "first occurence of header", first_match,
            "line into buffer file with replace() ...");
          if ((log->roadmap.id == SARH_REPLACE_1_REGCOMP_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0))
          {
              log->roadmap.id = REPLACE_REGCOMP_FAILED_RM;
          } else if ((log->roadmap.id == SARH_REPLACE_1_REALLOC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0)) {
              log->roadmap.id = REPLACE_REALLOC_FAILED_RM;
          } else if ((log->roadmap.id == SARH_REPLACE_1_REGEXEC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0)) {
              log->roadmap.id = REPLACE_REGEXEC_FAILED_RM;
          }

          if (!replace(buffer, INCLUDE_HEADER_PATTERN, "", "  ", log))
          {
            writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
              "replace() failed\n");
            freeRegex(&regex, "  ", log);

            status = false;
            break;
          }

          if ((log->roadmap.id == REPLACE_REGCOMP_FAILED_RM) ||
            (log->roadmap.id == REPLACE_REALLOC_FAILED_RM) ||
            (log->roadmap.id == REPLACE_REGEXEC_FAILED_RM))
          {
            log->roadmap.id = BREAK_SUCCESS_RM;
          }
          writeLog(log, stdout, DEBUG, "", "      Line successfully deleted\n");
        } else {

          writeLog(log, stdout, DEBUG, "",
            "      \"%s\" is not already included\n", first_match);

          writeLog(log, stdout, DEBUG, "",
            "      Reallocating memory for headers ...\n");
          if ((log->roadmap.id != SARH_HEADERS_REALLOC_FAILED_RM) ||
            (strcmp(log->roadmap.glsl_file, first_match) != 0))
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
            writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
              "headers realloc() failed\n");
            freeRegex(&regex, "  ", log);

            status = false;
            break;
          }
          writeLog(log, stdout, DEBUG, "",
            "      Memory reallocated successfully\n");

          writeLog(log, stdout, DEBUG, "",
            "      Allocating memory for headers[%lu] ...\n",
            regex.headers_length);
          if ((log->roadmap.id == SARH_HEADER_REALLOC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0))
          {
            (regex.headers)[regex.headers_length] = NULL;
          } else {
            (regex.headers)[regex.headers_length] =
              malloc(sizeof(char) * (end_header - start_header + 1));
          }

          if (!(regex.headers)[regex.headers_length])
          {
            writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
              "headers[%lu] malloc() failed\n", regex.headers_length);
            freeRegex(&regex, "  ", log);

            status = false;
            break;
          }
          writeLog(log, stdout, DEBUG, "",
            "      Memory allocated successfully\n");

          regex.headers_length++;

          writeLog(log, stdout, DEBUG, "",
            "      Copying string into headers[%lu] ...\n",
            regex.headers_length - 1);
          strncpy((regex.headers)[regex.headers_length - 1], first_match,
            end_header - start_header);
          (regex.headers)[regex.headers_length - 1]
            [end_header - start_header] = '\0';
          writeLog(log, stdout, DEBUG, "", "      \"%s\" successfully copied\n",
            (regex.headers)[regex.headers_length - 1]);

          char header_filepath[strlen(*dirpath) + strlen(first_match) + 1];

          writeLog(log, stdout, DEBUG, "",
            "      Copying string into header_filepath ...\n");
          strcpy(header_filepath, *dirpath);
          writeLog(log, stdout, DEBUG, "", "      \"%s\" successfully copied\n",
            header_filepath);

          writeLog(log, stdout, DEBUG, "",
            "      Concatenating string into header_filepath ...\n");
          strcat(header_filepath, first_match);
          writeLog(log, stdout, DEBUG, "", "      \"%s\" successfully copied\n",
            header_filepath);

          writeLog(log, stdout, DEBUG, "", "      Reading file \"%s\" ...\n",
            header_filepath);
          char* header_filepath_p = &(header_filepath[0]);

          if ((log->roadmap.id == SARH_READFILE_BUFFER_MALLOC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0))
          {
            log->roadmap.id = BUFFER_MALLOC_FAILED_RM;
          } else if ((log->roadmap.id == SARH_READFILE_FOPEN_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0)) {
              log->roadmap.id = FOPEN_FAILED_RM;
          }

          if (!readFile(&header_filepath_p, &(regex.header_buffer), "  ", log))
          {
            writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
              "Failed to read file\n");
            freeRegex(&regex, "  ", log);

            status = false;
            break;
          }

          if ((log->roadmap.id == BUFFER_MALLOC_FAILED_RM) ||
            (log->roadmap.id == FOPEN_FAILED_RM))
          {
            log->roadmap.id = BREAK_SUCCESS_RM;
          }
          writeLog(log, stdout, DEBUG, "", "      File read successfully\n");

          writeLog(log, stdout, DEBUG, "",
            "      Adding markers to \"%s\" ...\n",
            (regex.headers)[regex.headers_length - 1]);
          if ((log->roadmap.id == SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0))
          {
            log->roadmap.id = SARH_ADDMARKERS_REALLOC_FAILED_RM;
          }

          if (!addMarkers(&((regex.headers)[regex.headers_length - 1]),
            &(regex.header_buffer), "  ", log))
          {
            writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
              "Unable to mark the file\n");
            freeRegex(&regex, "  ", log);

            status = false;
            break;
          }

          if (log->roadmap.id == SARH_ADDMARKERS_REALLOC_FAILED_RM)
          {
            log->roadmap.id = BREAK_SUCCESS_RM;
          }
          writeLog(log, stdout, DEBUG, "", "      Markers added:\n%s\n%s%s\n",
            BAR, regex.header_buffer, BAR);

          writeLog(log, stdout, DEBUG, "", "      Replacing header \"%s\" %s",
            first_match, "by its content into buffer file ...\n");
          if ((log->roadmap.id == SARH_REPLACE_2_REGCOMP_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0))
          {
            log->roadmap.id = REPLACE_REGCOMP_FAILED_RM;
          } else if ((log->roadmap.id == SARH_REPLACE_2_REALLOC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0)) {
              log->roadmap.id = REPLACE_REALLOC_FAILED_RM;
          } else if ((log->roadmap.id == SARH_REPLACE_2_REGEXEC_FAILED_RM) &&
            (strcmp(log->roadmap.glsl_file, first_match) == 0)) {
              log->roadmap.id = REPLACE_REGEXEC_FAILED_RM;
          }

          if (!replace(buffer, INCLUDE_HEADER_PATTERN,
            regex.header_buffer, "  ", log))
          {
            writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
              "replace() failed\n");
            freeRegex(&regex, "  ", log);

            status = false;
            break;
          }

          if ((log->roadmap.id == REPLACE_REGCOMP_FAILED_RM) ||
            (log->roadmap.id == REPLACE_REALLOC_FAILED_RM) ||
            (log->roadmap.id == REPLACE_REGEXEC_FAILED_RM))
          {
            log->roadmap.id = BREAK_SUCCESS_RM;
          }
          writeLog(log, stdout, DEBUG, "", "      %s\n%s\n%s%s\n",
            "Buffer file filled with header content:", BAR, *buffer, BAR);

          writeLog(log, stdout, DEBUG, "",
            "      Freeing header_buffer memory ...\n");
          free(regex.header_buffer);
          regex.header_buffer = NULL;
          writeLog(log, stdout, DEBUG, "", "      Memory freed successfully\n");
        }

        writeLog(log, stdout, DEBUG, "",
          "      Comparing regex pattern to buffer file ...\n");
        match = regexec(&(regex.regex), *buffer, nmatch + 1, m, 0);
      }

      if (!status)
      {
        break;
      }

      writeLog(log, stdout, DEBUG, "", "    Regex pattern not found\n");
      writeLog(log, stdout, DEBUG, "", "    File buffer is now:\n%s\n%s%s\n",
        BAR, *buffer, BAR);

      freeRegex(&regex, "", log);

      writeLog(log, stdout, INFO, "", "    Searching for regex error ...\n");
      if ((match != REG_NOMATCH) ||
        (log->roadmap.id == SARH_REGEXEC_FAILED_RM))
      {
        if (log->roadmap.id != SARH_REGEXEC_FAILED_RM)
        {
          size_t size = regerror(regex_error, &(regex.regex), NULL, 0);
          writeLog(log, stdout, DEBUG, "",
            "    Message size of regex error is %lu\n", size);

          char text[size];

          regerror(regex_error, &(regex.regex), &(text[0]), size);

          writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
            "Regex error: %s\n", text);
        }

        status = false;
        break;
      }
      writeLog(log, stdout, INFO, "", "    No regex error\n");
    } else {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Regex compilation failed\n");

      status = false;
      break;
    }
  } while (false);

  if ((log->roadmap.id == SARH_ADDMARKERS_REALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_HEADER_MALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_REGEXEC_FAILED_RM) ||
    (log->roadmap.id == SARH_REPLACE_2_REGEXEC_FAILED_RM) ||
    (log->roadmap.id == SARH_REPLACE_2_REALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_REPLACE_2_REGCOMP_FAILED_RM) ||
    (log->roadmap.id == SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_READFILE_FOPEN_FAILED_RM) ||
    (log->roadmap.id == SARH_READFILE_BUFFER_MALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_HEADER_REALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_HEADERS_REALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_REPLACE_1_REGEXEC_FAILED_RM) ||
    (log->roadmap.id == SARH_REPLACE_1_REALLOC_FAILED_RM) ||
    (log->roadmap.id == SARH_REPLACE_1_REGCOMP_FAILED_RM))
  {
    log->roadmap.id = BREAK_SUCCESS_RM;
  }

  return status;
}

bool improveLogShader(char** message, char** buffer, Log* log)
{
  bool status = true;

  do
  {
    regex_t regex;

    writeLog(log, stdout, DEBUG, "",
      "      Compiling regex pattern: \"%s\" ...\n",
      STARTLINE_SHADERLOG_PATTERN);

    int regex_error = 1;
    if (log->roadmap.id != IMPROVELOGSHADER_REGCOMP_FAILED_RM)
    {
      regex_error = regcomp(&regex, STARTLINE_SHADERLOG_PATTERN,
        REG_EXTENDED | REG_NEWLINE);
    }

    if (regex_error == 0)
    {
      writeLog(log, stdout, DEBUG, "",
        "      Regex pattern compiled successfully\n");

      size_t nmatch = regex.re_nsub;
      writeLog(log, stdout, DEBUG, "",
        "      Regex subexpressions found: %lu\n", nmatch);

      regmatch_t m[nmatch + 1];

      writeLog(log, stdout, DEBUG, "", "      Comparing regex pattern ...\n");
      int match = regexec(&regex, *message, nmatch + 1, m, 0);

      size_t start;
      size_t end;

      unsigned l;

      while (match == 0)
      {
        writeLog(log, stdout, DEBUG, "", "      Regex pattern found\n");

        start = m[1].rm_so;
        writeLog(log, stdout, DEBUG, "",
          "      Start index of parenthesis expression is %lu\n", start);
        end = m[1].rm_eo;
        writeLog(log, stdout, DEBUG, "",
          "      End index of parenthesis expression is %lu\n", end);

        char line[end - start];
        line[0] = '\0';

        writeLog(log, stdout, DEBUG, "",
          "      Copying line number of buffer file error ...\n");
        strncat(line, *message + start, end - start);
        writeLog(log, stdout, DEBUG, "",
          "      Line number successfully copied\n");

        writeLog(log, stdout, DEBUG, "",
          "      Casting line number string to unsigned int ...\n");
        l = strtoul(line, NULL, 10);
        writeLog(log, stdout, DEBUG, "",
          "      Line number successfully casted\n");

        writeLog(log, stdout, DEBUG, "", "      Line number is %u\n", l);

        unsigned i = 0;
        end = 0;

        writeLog(log, stdout, DEBUG, "",
          "      Searching corresponding line into buffer file ...\n");
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
        start = end - 1;
        while ((*buffer)[start] != '\n')
        {
          start--;
        }
        char buffer_line[end - start - 1];
        buffer_line[0] = '\0';
        strncat(buffer_line, (*buffer) + start + 1, end - start - 1);
        writeLog(log, stdout, DEBUG, "", "      Corresponding line is \"%s\"\n",
          buffer_line);

        start = end;

        writeLog(log, stdout, DEBUG, "",
          "      Searching marker into line ...\n");
        while (((*buffer)[start - 3] != ' ') || ((*buffer)[start - 2] != '/') ||
          ((*buffer)[start - 1] != '/') || ((*buffer)[start] != ' '))
        {
          --start;
        }
        start++;
        writeLog(log, stdout, DEBUG, "", "      Corresponding marker found\n");

        char marker[end - start];
        marker[0] = '\0';

        writeLog(log, stdout, DEBUG, "", "      Copying marker ...\n");
        strncat(marker, (*buffer) + start, end - start);
        writeLog(log, stdout, DEBUG, "", "      Marker successfully copied\n");

        writeLog(log, stdout, DEBUG, "",
          "      Replacing original log data by marker ...\n");
        if (log->roadmap.id == IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM)
        {
          log->roadmap.id = REPLACE_REGCOMP_FAILED_RM;
        } else if (log->roadmap.id ==
          IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM) {
            log->roadmap.id = REPLACE_REALLOC_FAILED_RM;
        } else if (log->roadmap.id ==
          IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM) {
            log->roadmap.id = REPLACE_REGEXEC_FAILED_RM;
        }

        if (!replace(message, STARTLINE_SHADERLOG_PATTERN, marker, "  ", log))
        {
          writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
            "replace() failed\n");
          regfree(&regex);

          status = false;
          break;
        }
        writeLog(log, stdout, DEBUG, "", "      Log data replaced\n");

        writeLog(log, stdout, DEBUG, "", "      Comparing regex pattern ...\n");
        match = regexec(&regex, *message, nmatch + 1, m, 0);
      }

      if (!status)
      {
        break;
      }

      writeLog(log, stdout, INFO, "", "      Searching for regex error ...\n");
      if ((match != REG_NOMATCH)
        || (log->roadmap.id == IMPROVELOGSHADER_REGEXEC_FAILED_RM))
      {
        if (log->roadmap.id != IMPROVELOGSHADER_REGEXEC_FAILED_RM)
        {
          regex_error = 1;
          size_t size = regerror(regex_error, &regex, NULL, 0);
          writeLog(log, stdout, DEBUG, "",
            "      Message size of regex error is %lu\n", size);

          char text[size];

          regerror(regex_error, &regex, &(text[0]), size);

          writeLog(log, stdout, DEBUG, "",
            "      Freeing regex structure ...\n");
          regfree(&regex);
          writeLog(log, stdout, DEBUG, "", "      Memory freed successfully\n");

          writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
            "Regex error: %s\n", text);

          status = false;
          break;
        } else {
          writeLog(log, stdout, DEBUG, "",
            "      Freeing regex structure ...\n");
          regfree(&regex);
          writeLog(log, stdout, DEBUG, "", "      Memory freed successfully\n");

          status = false;
          break;
        }
      }
      writeLog(log, stdout, INFO, "",
        "      No regex error. Regex pattern not found\n");
    } else {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "      ",
        "Regex compilation failed\n");

      status = false;
      break;
    }

    writeLog(log, stdout, DEBUG, "", "      Freeing regex structure ...\n");
    regfree(&regex);
    writeLog(log, stdout, DEBUG, "", "      Memory freed successfully\n");
  } while (false);

  return status;
}
