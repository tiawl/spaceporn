#include "shader.h"

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
    VERB(verbose, printf("%s      \"%s\" opened\n", spaces, *filepath));

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
      fprintf(stderr, "%s      Buffer malloc() failed\n", spaces);
      return false;
    }

    VERB(verbose, printf("%s      Closing \"%s\" ...\n", spaces, *filepath));
    fclose(f);
    VERB(verbose, printf("%s      \"%s\" closed\n", spaces, *filepath));

  } else {
    fprintf(stderr, "%s      Failed to read inside \"%s\": %s\n", spaces,
      *filepath, strerror(errno));
    return false;
  }

  return true;
}

void freeRegex(Regex* regex, bool verbose)
{
  if (regex->dir_path)
  {
    VERB(verbose, printf("      Freeing dir_path memory ...\n"));
    free(regex->dir_path);
    regex->dir_path = NULL;
    VERB(verbose, printf("      Memory freed successfully\n"));
  }

  if (regex->header_filepath)
  {
    VERB(verbose, printf("      Freeing header_filepath memory ...\n"));
    free(regex->header_filepath);
    regex->header_filepath = NULL;
    VERB(verbose, printf("      Memory freed successfully\n"));
  }

  if (regex->header_buffer)
  {
    VERB(verbose, printf("      Freeing header_buffer memory ...\n"));
    free(regex->header_buffer);
    regex->header_buffer = NULL;
    VERB(verbose, printf("      Memory freed successfully\n"));
  }

  if (regex->first_match)
  {
    VERB(verbose, printf("      Freeing first_match memory ...\n"));
    free(regex->first_match);
    regex->first_match = NULL;
    VERB(verbose, printf("      Memory freed successfully\n"));
  }

  if (regex->headers)
  {
    for (size_t i = 0; i < regex->headers_length; ++i)
    {
      VERB(verbose, printf("      Freeing headers[%lu] memory ...\n",
        i));
      free((regex->headers)[i]);
      VERB(verbose, printf("      Memory freed successfully\n"));
    }

    VERB(verbose, printf("      Freeing headers memory ...\n"));
    free(regex->headers);
    regex->headers = NULL;
    VERB(verbose, printf("      Memory freed successfully\n"));
  }

  VERB(verbose, printf("      Freeing regex structure ...\n"));
  regfree(&(regex->regex));
  VERB(verbose, printf("      Memory freed successfully\n"));
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
    regmatch_t m[nmatch + 1];
    const char* rpl;
    const char* p = replace;

    char* new;
    char* search_start = *str;

    // replace only first occurence
    VERB(verbose, printf("%s      Comparing regex pattern ...\n", spaces));
    if (regexec(&regex, search_start, nmatch + 1, m, REG_NOTBOL) == 0)
    {
      VERB(verbose, printf("%s      Regex pattern compared successfully\n",
        spaces));

      VERB(verbose, printf("%s      Allocating memore for new ...\n",
        spaces));
      new = malloc(sizeof(char) * (strlen(*str) + strlen(replace)));
      if (!new)
      {
        fprintf(stderr, "%s      new malloc() failed\n", spaces);
        return false;
      }
      *new = '\0';
      VERB(verbose, printf("%s      Memory allocated successfully\n",
        spaces));

      VERB(verbose, printf("%s      Concatenating strings 1 ...\n", spaces));
      strncat(new, *str, search_start - *str);
      VERB(verbose, printf("%s      Strings concatenated successfully\n",
        spaces));

      p = rpl = replace;

      VERB(verbose, printf("%s      Concatenating strings 2 ...\n", spaces));
      strncat(new, search_start, m[0].rm_so); // test before pattern
      VERB(verbose, printf("%s      Strings concatenated successfully\n",
        spaces));

      VERB(verbose, printf("%s      Adding rpl ...\n", spaces));
      strcat(new, p); // trailing of rpl
      VERB(verbose, printf("%s      rpl added successfully\n", spaces));

      VERB(verbose, printf("%s      Trailing *str ...\n", spaces));
      strcat(new, search_start + m[0].rm_eo);
      VERB(verbose, printf("%s      *str trailed successfully\n", spaces));

      VERB(verbose, printf("%s      Reallocating memory for *str ...\n",
        spaces));
      *str = realloc(*str, sizeof(char) * (strlen(new) + 1));
      if (!*str)
      {
        fprintf(stderr, "        *str realloc() failed\n");
        return false;
      }
      VERB(verbose, printf("%s      Memory reallocated successfully\n",
        spaces));

      VERB(verbose, printf("%s      Copying new in *str ...\n", spaces));
      strcpy(*str, new);
      VERB(verbose, printf("%s      Copied successfully\n", spaces));

      VERB(verbose, printf("%s      Freeing new ...\n", spaces));
      free(new);
      VERB(verbose, printf("%s      Memory freed successfully\n", spaces));
    }

    VERB(verbose, printf("%s      Freeing regex structure ...\n", spaces));
    regfree(&regex);
    VERB(verbose, printf("%s      Memory freed successfully\n", spaces));

    return true;
  } else {
    fprintf(stderr, "%s      Regex compilation failed\n", spaces);
    return false;
  }
}

bool addMarkers(char** filename, char** buffer, const char* dir_path,
  bool is_main, bool verbose, enum Roadmap roadmap)
{
  size_t i = 0;
  size_t j = 0;

  char* new;
  char* marker;
  size_t marker_length;
  char* header;
  size_t header_length = 0;
  unsigned line = 1;

  FILE* f = NULL;
  char ch;
  unsigned lines_header;

  size_t buffer_length = strlen(*buffer);

  while (i <= buffer_length)
  {
    if (((*buffer)[i] == '\n') || (is_main && ((*buffer)[i] == '\0')))
    {
      marker_length = strlen(*filename) + strlen(" // :") +
        floor(log10(line)) + 1 + 1;
      if (header_length > 0)
      {
        marker_length += header_length + strlen(" // :") +
          floor(log10(lines_header)) + 1;
      }
      marker = malloc(sizeof(char) * marker_length);
      if (header_length > 0)
      {
        snprintf(marker, marker_length + 1, " // %s:%u // %s:%u", *filename,
          line, header, lines_header);
      } else {
        snprintf(marker, marker_length + 1, " // %s:%u", *filename, line);
      }

      new = malloc(sizeof(char) * (strlen(*buffer) + marker_length + 1));
      *new = '\0';
      strncat(new, *buffer, i);
      strncat(new, marker, marker_length);
      strncat(new, *buffer + i, strlen(*buffer) - i);

      *buffer = realloc(*buffer, sizeof(char) * (strlen(new) + 1));
      strcpy(*buffer, new);
      buffer_length = strlen(*buffer);

      while (((*buffer)[i] != '\n') && ((*buffer)[i] != '\0'))
      {
        ++i;
      }
      ++line;

      free(new);
      free(marker);

      if (header_length > 0)
      {
        header_length = 0;
        free(header);
      }
    } else if (i > 9) {
      if (((*buffer)[i - 10] == '#') && ((*buffer)[i - 9] == 'i') &&
        ((*buffer)[i - 8] == 'n') && ((*buffer)[i - 7] == 'c') &&
        ((*buffer)[i - 6] == 'l') && ((*buffer)[i - 5] == 'u') &&
        ((*buffer)[i - 4] == 'd') && ((*buffer)[i - 3] == 'e') &&
        ((*buffer)[i - 2] == ' ') && ((*buffer)[i - 1] == '\"'))
      {
        j = i + 1;
        while ((*buffer)[j] != '\"')
        {
          ++j;
        }

        header_length = j - i + 1;
        header = malloc(sizeof(char) * header_length);
        *header = '\0';
        strncat(header, *buffer + i, header_length - 1);

        new = malloc(sizeof(char) * (strlen(dir_path) + header_length + 1));
        *new = '\0';
        strcat(new, dir_path);
        strcat(new, header);

        lines_header = 0;

        f = fopen(new, "r");
        if (f == NULL)
        {
          return false;
        }

        while ((ch = fgetc(f)) != EOF)
        {
          if (ch == '\n')
          {
            lines_header++;
          }
        }

        fclose(f);
        free(new);

        i = j;
      }
    }
    ++i;
  }

  return true;
}

bool buildFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap)
{
  VERB(verbose, printf("    Reading file %s ... \n", *filepath));
  if (!readFile(filepath, buffer, "", verbose, roadmap))
  {
    fprintf(stderr, "    Failed to read file\n");
    return false;
  }
  VERB(verbose, printf("    File read successfully\n"));

  Regex regex;
  regex.dir_path = NULL;
  regex.header_filepath = NULL;
  regex.header_buffer = NULL;
  regex.first_match = NULL;
  regex.headers = NULL;
  regex.headers_length = 1;

  char* pattern_header = "^#include \"[/-_[:alnum:]]+\\.glsl\"";
  char* pattern_main = "main.glsl$";

  VERB(verbose, printf("    Compiling regex pattern: \"%s\" ...\n",
    pattern_header));
  int regex_error =
    regcomp(&(regex.regex), pattern_header, REG_EXTENDED | REG_NEWLINE);

  VERB(verbose, printf("    Allocating memory for dir_path ...\n");)
  regex.dir_path = malloc(sizeof(char) * (strlen(*filepath) + 1));
  if (!regex.dir_path)
  {
    fprintf (stderr, "    dir_path malloc() failed\n");
    return false;
  }
  *(regex.dir_path) = '\0';
  VERB(verbose, printf("    Memory allocated successfully\n"));

  VERB(verbose, printf("    Copying string into dir_path ...\n"));
  strncat(regex.dir_path, *filepath, strlen(*filepath) - 9);
  VERB(verbose, printf("    \"%s\" successfully copied\n", regex.dir_path));

  if (regex_error == 0)
  {
    VERB(verbose, printf("    Regex pattern compiled successfully\n"));

    size_t nmatch = regex.regex.re_nsub;
    regmatch_t m[nmatch + 1];

    bool is_already_headerd = false;

    VERB(verbose, printf("    Allocating memory for headers ...\n");)
    regex.headers = malloc(sizeof(char*));
    if (!regex.headers)
    {
      fprintf (stderr, "    headers malloc() failed\n");
      freeRegex(&regex, verbose);
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));

    regex.headers_length = 1;
    VERB(verbose, printf("    Allocating memory for headers[0] ...\n");)
    (regex.headers)[0] = malloc(sizeof(char) * (strlen("main.glsl") + 1));
    if (!(regex.headers)[0])
    {
      fprintf (stderr, "    headers[0] malloc() failed\n");
      freeRegex(&regex, verbose);
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
    if (!addMarkers(&((regex.headers)[0]), buffer, regex.dir_path, true,
      verbose, roadmap))
    {
      fprintf(stderr, "    Unable to mark the file\n");
      freeRegex(&regex, verbose);
      return false;
    }
    VERB(verbose, printf("    Markers added\n"));

    VERB(verbose, printf("    Comparing regex pattern to buffer file ...\n"));
    int match = regexec(&(regex.regex), *buffer, nmatch + 1, m, REG_NOTBOL);
    VERB(verbose, printf("    Regex pattern compared successfully\n"));

    size_t start_header;
    size_t end_header;

    VERB(verbose, printf("    Searching regex pattern into buffer file \
...\n"));
    while (match == 0)
    {
      start_header = m[0].rm_so + 10;
      end_header = m[0].rm_eo - 1;

      VERB(verbose, printf("      Allocating memory for first_match ...\n");)
      regex.first_match =
        malloc(sizeof(char) * (end_header - start_header + 1));
      if (!regex.first_match)
      {
        fprintf (stderr, "      first_match malloc() failed\n");
        freeRegex(&regex, verbose);
        return false;
      }
      VERB(verbose, printf("      Memory allocated successfully\n"));

      VERB(verbose, printf("      Copying into first_match ...\n"));
      strncpy(regex.first_match, (*buffer) + start_header,
        end_header - start_header);
      (regex.first_match)[end_header - start_header] = '\0';
      VERB(verbose, printf("      \"%s\" successfully copied\n",
        regex.first_match));

      VERB(verbose, printf("      Comparing first_match to the cache ...\n"));
      is_already_headerd = false;
      for (size_t i = 0; (i < regex.headers_length) &&
        !is_already_headerd; ++i)
      {
        VERB(verbose, printf("        Comparing \"%s\" to \"%s\" ...\n",
          (regex.headers)[i], regex.first_match));
        is_already_headerd |=
          (strcmp((regex.headers)[i], regex.first_match) == 0);
        VERB(verbose, printf("        %s\n",
          is_already_headerd ? "Same string" : "Not the same string"));
      }

      if (is_already_headerd)
      {
        VERB(verbose, printf("      \"%s\" was already headerd\n",
          regex.first_match));

        VERB(verbose, printf("      Deleting first occurence of #header \
\"%s\" line into buffer file with regex_replace() ...\n", regex.first_match));
        if (!regex_replace(buffer, pattern_header, "", "  ", verbose,
          roadmap))
        {
          fprintf(stderr, "      regex_replace() failed\n");
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      Line successfully deleted\n"));
      } else {

        VERB(verbose, printf("      \"%s\" is not already headerd\n",
          regex.first_match));

        regex.headers_length++;

        VERB(verbose, printf("      Reallocating memory for headers ...\n");)
        regex.headers = realloc(regex.headers,
          sizeof(char*) * regex.headers_length);
        if (!regex.headers)
        {
          fprintf (stderr, "      headers realloc() failed\n");
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      Memory reallocated successfully\n"));

        VERB(verbose, printf("      Allocating memory for headers[%lu] \
...\n", regex.headers_length - 1);)
        (regex.headers)[regex.headers_length - 1] =
          malloc(sizeof(char) * (end_header - start_header + 1));
        if (!(regex.headers)[regex.headers_length - 1])
        {
          fprintf (stderr, "      headers[%lu] malloc() failed\n",
            regex.headers_length - 1);
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      Memory allocated successfully\n"));

        VERB(verbose, printf("      Copying string into headers[%lu] ...\n",
          regex.headers_length - 1));
        strncpy((regex.headers)[regex.headers_length - 1],
          regex.first_match, end_header - start_header);
        (regex.headers)[regex.headers_length - 1]
          [end_header - start_header] = '\0';
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          (regex.headers)[regex.headers_length - 1]));

        VERB(verbose, printf("      Allocating memory for header_filepath \
...\n");)
        regex.header_filepath =
          malloc(sizeof(char) * (strlen(*filepath) + 1));
        if (!regex.header_filepath)
        {
          fprintf(stderr, "      header_filepath malloc() failed\n");
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      Memory allocated successfully\n"));

        VERB(verbose, printf("      Copying string into header_filepath \
...\n"));
        strcpy(regex.header_filepath, *filepath);
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          regex.header_filepath));

        VERB(verbose, printf("      Replacing first occurence of \"%s\" by \
\"%s\" into \"%s\" ...\n", pattern_main, regex.first_match,
          regex.header_filepath));
        if (!regex_replace(&(regex.header_filepath), pattern_main,
          regex.first_match, "  ", verbose, roadmap))
        {
          fprintf(stderr, "      regex_replace() failed\n");
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      Regex replacement done: %s\n",
          regex.header_filepath));
        VERB(verbose, printf("      Reading file %s ... \n",
          regex.header_filepath));
        if (!readFile(&(regex.header_filepath), &(regex.header_buffer),
          "  ", verbose, roadmap))
        {
          fprintf(stderr, "      Failed to read file\n");
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      File read successfully\n"));

        VERB(verbose, printf("      Adding markers to \"%s\" ...\n",
          (regex.headers)[regex.headers_length - 1]));
        if (!addMarkers(&((regex.headers)[regex.headers_length - 1]),
          &(regex.header_buffer), regex.dir_path, false, verbose, roadmap))
        {
          fprintf(stderr, "      Unable to mark the file\n");
          freeRegex(&regex, verbose);
          return false;
        }
        VERB(verbose, printf("      Markers added\n"));

        if (!regex_replace(buffer, pattern_header, regex.header_buffer,
          "  ", verbose, roadmap))
        {
          fprintf(stderr, "      regex_replace() failed\n");
          freeRegex(&regex, verbose);
          return false;
        }

        VERB(verbose, printf("      Freeing header_filepath memory ...\n"));
        free(regex.header_filepath);
        regex.header_filepath = NULL;
        VERB(verbose, printf("      Memory freed successfully\n"));

        VERB(verbose, printf("      Freeing header_buffer memory ...\n"));
        free(regex.header_buffer);
        regex.header_buffer = NULL;
        VERB(verbose, printf("      Memory freed successfully\n"));
      }

      VERB(verbose, printf("      Freeing first_match memory ...\n"));
      free(regex.first_match);
      regex.first_match = NULL;
      VERB(verbose, printf("      Memory freed successfully\n"));

      VERB(verbose,
        printf("      Comparing regex pattern to buffer file ...\n"));
      match = regexec(&(regex.regex), *buffer, nmatch + 1, m, REG_NOTBOL);
      VERB(verbose, printf("      Regex pattern compared successfully\n"));
    }
    VERB(verbose, printf("    File buffer is now:\n\
------------------------------------------------------------------------------\
\n%s\n\
------------------------------------------------------------------------------\
\n", *buffer));

    freeRegex(&regex, verbose);

    if (match != REG_NOMATCH)
    {
      VERB(verbose, printf("    Searching for regex errors ...\n"));
      size_t size = regerror(regex_error, &(regex.regex), NULL, 0);

      VERB(verbose, printf("      Allocating text memory ...\n"));
      char* text = malloc(sizeof(*text) * size);
      if (!text)
      {
        fprintf (stderr, "      text malloc() failed\n");
        return false;
      }
      VERB(verbose, printf("      Memory allocated successfully\n"));

      regerror(regex_error, &(regex.regex), text, size);
      fprintf(stderr, "    Regex error: %s\n", text);

      VERB(verbose, printf("    Freeing text memory ...\n"));
      free(text);
      VERB(verbose, printf("    Memory freed successfully\n"));
    }
  } else {
    fprintf(stderr, "    Regex compilation failed\n");
    return false;
  }

  return true;
}

bool buildVertexShaderFile(Shaders* shaders, bool verbose,
  enum Roadmap roadmap)
{
  if (roadmap == FOPEN_VERTEX_FILE_FAILED_RM)
  {
    roadmap = FOPEN_FAILED_RM;
  }

  if (roadmap == BUFFER_VERTEX_FILE_MALLOC_FAILED_RM)
  {
    roadmap = BUFFER_MALLOC_FAILED_RM;
  }

  if (roadmap == VERTEX_SHADER_COMPILATION_FAILED_RM)
  {
    roadmap = SHADER_COMPILATION_FAILED_RM;
    shaders->vertex_file = ERRONEOUS_VERTEX_SHADER;
  } else if (roadmap == LINKING_PROGRAM_FAILED_RM) {
    shaders->vertex_file = MISSINGMAIN_VERTEX_SHADER;
  }

  if (!buildFile(&(shaders->vshaderpath), &(shaders->vertex_file), verbose,
    roadmap))
  {
    fprintf(stderr, "  Failed to build vertex shader file\n");
    return false;
  }

  return true;
}

bool buildFragmentShaderFile(Shaders* shaders, bool verbose,
  enum Roadmap roadmap)
{
  if (roadmap == FOPEN_FRAGMENT_FILE_FAILED_RM)
  {
    roadmap = FOPEN_FAILED_RM;
  }

  if (roadmap == BUFFER_FRAGMENT_FILE_MALLOC_FAILED_RM)
  {
    roadmap = BUFFER_MALLOC_FAILED_RM;
  }

  if (roadmap == FRAGMENT_SHADER_COMPILATION_FAILED_RM)
  {
    roadmap = SHADER_COMPILATION_FAILED_RM;
    shaders->fragment_file = ERRONEOUS_FRAGMENT_SHADER;
  } else if (roadmap == LINKING_PROGRAM_FAILED_RM) {
    roadmap = EXIT_SUCCESS_RM;
  }

  if (!buildFile(&(shaders->fshaderpath), &(shaders->fragment_file), verbose,
    roadmap))
  {
    fprintf(stderr, "  Failed to build fragment shader file\n");
    return false;
  }

  return true;
}

bool checkingLogShader(GLuint* shader, GLenum shaderType, bool verbose,
  enum Roadmap roadmap)
{
  GLint shaderCompiled = GL_FALSE;
  GL_CHECK(glGetShaderiv(*shader, GL_COMPILE_STATUS, &shaderCompiled));

  if (shaderCompiled != GL_TRUE)
  {
    fprintf(stderr, "    Unable to compile %s shader\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex");

    GLint maxLength = 0;

    VERB(verbose, printf("    Querying log length of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &maxLength));
    VERB(verbose, printf("    Log length of %s shader is %d\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex", maxLength));

    if (maxLength > 0)
    {
      char message[maxLength];

      VERB(verbose, printf("    Querying log info of %s shader ...\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
      GL_CHECK(glGetShaderInfoLog(*shader, maxLength, &maxLength, message));
      VERB(verbose, printf("    Log info of %s shader found:\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

      fprintf(stderr, "\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", &(message[0]));
    }

    return false;
  }

  return true;
}

bool loadShader(Shaders* shaders, GLenum shaderType, bool verbose,
  enum Roadmap roadmap)
{
  GLuint* shader = shaderType == GL_FRAGMENT_SHADER ?
    &(shaders->fragment_shader) : &(shaders->vertex_shader);

  VERB(verbose, printf("    Creating %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(*shader = glCreateShader(shaderType));
  VERB(verbose, printf("    %s shader %d created\n",
    shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex", *shader));

  VERB(verbose, printf("    Setting source code in %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(glShaderSource(*shader, 1, shaderType == GL_FRAGMENT_SHADER ?
    (const GLchar**) &(shaders->fragment_file) :
      (const GLchar**) &(shaders->vertex_file), NULL));
  VERB(verbose, printf("    Source code in %s shader set\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

  VERB(verbose, printf("    Compiling %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(glCompileShader(*shader));
  VERB(verbose, printf("    %s shader probably compiled\n",
    shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));

  VERB(verbose, printf("    Checking compile status of %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  if (!checkingLogShader(shader, shaderType, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("    %s shader compiled\n",
    shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));

  return true;
}

bool loadVertexShader(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  if (!loadShader(shaders, GL_VERTEX_SHADER, verbose, roadmap))
  {
    fprintf(stderr, "  Failed to compile vertex shader\n");
    return false;
  }

  return true;
}

bool loadFragmentShader(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  if (!loadShader(shaders, GL_FRAGMENT_SHADER, verbose, roadmap))
  {
    fprintf(stderr, "  Failed to compile fragment shader\n");
    return false;
  }

  return true;
}

bool checkingLogProgram(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Checking linking status of OpenGL program ...\n"));

  GLint programSuccess = GL_TRUE;
  GL_CHECK(glGetProgramiv(shaders->program, GL_LINK_STATUS, &programSuccess));

  if (programSuccess != GL_TRUE)
  {
    fprintf(stderr, "  Unable to link OpenGL program \n");

    GLint maxLength = 0;

    VERB(verbose, printf("  Querying log length of OpenGL program \
...\n"));
    GL_CHECK(glGetProgramiv(shaders->program, GL_INFO_LOG_LENGTH,
      &maxLength));
    VERB(verbose, printf("  Log length of OpenGL program is %d\n",
      maxLength));

    if (maxLength > 0)
    {
      char message[maxLength];

      VERB(verbose, printf("  Querying log info of OpenGL program ...\n"));
      GL_CHECK(glGetProgramInfoLog(shaders->program, maxLength, &maxLength,
        message));
      VERB(verbose, printf("  Log info of OpenGL program found:\n"));

      fprintf(stderr, "\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", &(message[0]));
    }

    return false;
  }
  return true;
}

bool loadProgram(Context* context, Shaders* shaders, bool verbose,
  enum Roadmap roadmap)
{
  VERB(verbose, printf("  Creating OpenGL Program ...\n"));
  GL_CHECK(shaders->program = glCreateProgram());
  VERB(verbose, printf("  OpenGL Program %d created\n", shaders->program));

  VERB(verbose, printf("  Building vertex shader file ...\n"));
  if (!buildVertexShaderFile(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  Vertex shader file built\n"));

  VERB(verbose, printf("  Building fragment shader file ...\n"));
  if (!buildFragmentShaderFile(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  Fragment shader file built\n"));

  VERB(verbose, printf("  Loading vertex shader ...\n"));
  if (!loadVertexShader(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  Vertex shader loaded\n"));

  VERB(verbose, printf("  Loading fragment shader ...\n"));
  if (!loadFragmentShader(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  Fragment shader loaded\n"));

  VERB(verbose, printf("  Attaching vertex shader to OpenGL program ...\n"));
  GL_CHECK(glAttachShader(shaders->program, shaders->vertex_shader));
  VERB(verbose, printf("  Vertex shader attached\n"));

  VERB(verbose, printf("  Attaching fragment shader to OpenGL program \
...\n"));
  GL_CHECK(glAttachShader(shaders->program, shaders->fragment_shader));
  VERB(verbose, printf("  Fragment shader attached\n"));

  VERB(verbose, printf("  Linking OpenGL program ...\n"));
  GL_CHECK(glLinkProgram(shaders->program));
  VERB(verbose, printf("  OpenGL program probably linked\n"));

  if (!checkingLogProgram(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  OpenGL program linked\n"));

  VERB(verbose, printf("  Checking OpenGL program execution ...\n"));
  GL_CHECK(glValidateProgram(shaders->program));
  VERB(verbose, printf("  OpenGL program execution checked\n"));

  VERB(verbose, printf("  Installing OpenGL program as part of current \
rendering state...\n"));
  GL_CHECK(glUseProgram(shaders->program));
  VERB(verbose, printf("  OpenGL program installed\n"));

  VERB(verbose, printf("  Specifying viewport ...\n"));
  GL_CHECK(glViewport(0, 0, context->window_attribs.width,
    context->window_attribs.height));
  VERB(verbose, printf("  Viewport specified\n"));

  VERB(verbose, printf("  Detaching vertex shader to OpenGL program ...\n"));
  GL_CHECK(glDetachShader(shaders->program, shaders->vertex_shader));
  VERB(verbose, printf("  Vertex shader detached\n"));

  VERB(verbose, printf("  Detaching fragment shader to OpenGL program \
...\n"));
  GL_CHECK(glDetachShader(shaders->program, shaders->fragment_shader));
  VERB(verbose, printf("  Fragment shader detached\n"));

  return true;
}
