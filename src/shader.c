#include "shader.h"

bool readFile(char** filepath, char** buffer, char* spaces, bool verbose,
  enum Roadmap roadmap)
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

/* replaces regex in pattern with replacement observing capture groups
   *str MUST be free-able, i.e. obtained by strdup, malloc, ...
   back references are indicated by char codes 1-31 and none of those chars
      can be used in the replacement string such as a tab.
   will not search for matches within replaced text, this will begin searching
      for the next match after the end of prev match
   returns:
     false if pattern cannot be compiled OR
           if count of back references and capture groups don't match
*/
bool regex_replace(char** str, const char* pattern, const char* replace)
{
  regex_t reg;
  unsigned int replacements = 0;

  if(!regcomp(&reg, pattern, REG_EXTENDED | REG_NEWLINE))
  {
    size_t nmatch = reg.re_nsub;
    regmatch_t m[nmatch + 1];
    const char *rpl, *p;

    // count back references in replace
    p = replace;

    // look for matches and replace
    char *new;
    char *search_start = *str;

    // replace only first occurence
    if (!regexec(&reg, search_start, nmatch + 1, m, REG_NOTBOL))
    {
      // make enough room
      new = malloc(sizeof(char) * (strlen(*str) + strlen(replace)));
      if (!new)
      {
        fprintf(stderr, "new malloc() failed\n");
        return false;
      }
      *new = '\0';
      strncat(new, *str, search_start - *str);
      p = rpl = replace;
      int c;
      strncat(new, search_start, m[0].rm_so); // test before pattern
      for(int k=0; k<nmatch; k++)
      {
        while(*++p > 31); // skip printable char
        c = *p;  // back reference (e.g. \1, \2, ...)
        strncat(new, rpl, p - rpl); // add head of rpl

        // concat match
        strncat(new, search_start + m[c].rm_so, m[c].rm_eo - m[c].rm_so);
        rpl = p++; // skip back reference, next match
      }
      strcat(new, p); // trailing of rpl
      unsigned int new_start_offset = strlen(new);
      strcat(new, search_start + m[0].rm_eo); // trailing text in *str
      free(*str);
      *str = malloc(sizeof(char) * (strlen(new) + 1));
      if (!*str)
      {
        fprintf(stderr, "*str malloc() failed\n");
        return false;
      }
      strcpy(*str, new);
      search_start = *str + new_start_offset;
      free(new);
      replacements++;
    }
    regfree(&reg);

    // ajust size
    *str = realloc(*str, sizeof(char) * (strlen(*str) + 1));
    if (!*str)
    {
      fprintf(stderr, "*str realloc() failed\n");
      return false;
    }
    return true;
  } else {
    fprintf(stderr, "Regex compilation failed\n");
    return false;
  }
}

bool buildFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap)
{
  VERB(verbose, printf("    Reading file %s ... \n", *filepath));
  if (!readFile(filepath, buffer, "", verbose, roadmap))
  {
    fprintf(stderr, "      Failed to read file\n");
    return false;
  }
  VERB(verbose, printf("    File read successfully\n"));

  regex_t regex;
  char* pattern_include = "^#include \"[/-_[:alnum:]]+\\.glsl\"";
  char* pattern_main = "main.glsl$";

  VERB(verbose, printf("    Compiling regex pattern: \"%s\" ...\n",
    pattern_include));
  int regex_error =
    regcomp(&regex, pattern_include, REG_EXTENDED | REG_NEWLINE);

  char* tmp_buffer;

  if (regex_error == 0)
  {
    VERB(verbose, printf("    Regex pattern compiled successfully\n"));

    size_t nmatch = regex.re_nsub;
    regmatch_t m[nmatch + 1];

    VERB(verbose, printf("    Comparing regex pattern to buffer file ...\n"));
    int match = regexec(&regex, *buffer, nmatch + 1, m, REG_NOTBOL);
    VERB(verbose, printf("    Regex pattern compared successfully\n"));

    bool is_already_included = false;

    VERB(verbose, printf("    Allocating memory for includes ...\n");)
    char** includes = malloc(sizeof(char*));
    if (!includes)
    {
      fprintf (stderr, "    includes malloc() failed\n");
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));

    size_t includes_length = 1;
    VERB(verbose, printf("    Allocating memory for includes[0] ...\n");)
    includes[0] = malloc(sizeof(char) * (strlen("main.glsl") + 1));
    if (!includes[includes_length - 1])
    {
      fprintf (stderr, "    includes[0] malloc() failed\n");
      return false;
    }
    VERB(verbose, printf("    Memory allocated successfully\n"));

    VERB(verbose, printf("    Copying string into includes[0] ...\n"));
    strcpy(includes[0], "main.glsl");
    includes[0][strlen(includes[0])] = '\0';
    VERB(verbose, printf("    \"%s\" successfully copied\n", includes[0]));

    size_t start_include;
    size_t end_include;

    char* first_match;
    char* header_filepath;

    VERB(verbose, printf("    Searching regex pattern into buffer file \
...\n"));
    while (match == 0)
    {
      start_include = m[0].rm_so + 10;
      end_include = m[0].rm_eo - 1;

      VERB(verbose, printf("      Allocating memory for first_match ...\n");)
      first_match = malloc(sizeof(char) * (end_include - start_include + 1));
      if (!first_match)
      {
        fprintf (stderr, "      first_match malloc() failed\n");
        return false;
      }
      VERB(verbose, printf("      Memory allocated successfully\n"));

      VERB(verbose, printf("      Copying into first_match ...\n"));
      strncpy(first_match, (*buffer) + start_include,
        end_include - start_include);
      first_match[end_include - start_include] = '\0';
      VERB(verbose, printf("      \"%s\" successfully copied\n",
        first_match));

      VERB(verbose, printf("      Comparing first_match to the cache ...\n"));
      is_already_included = false;
      for (size_t i = 0; (i < includes_length) && !is_already_included; ++i)
      {
        VERB(verbose, printf("        Comparing \"%s\" to \"%s\" ...\n",
          includes[i], first_match));
        is_already_included |= strcmp(includes[i], first_match) == 0;
        VERB(verbose, printf("        %s\n",
          is_already_included ? "Same string" : "Not the same string"));
      }

      if (is_already_included)
      {
        VERB(verbose, printf("      \"%s\" was already included\n",
          first_match));

        VERB(verbose, printf("      Deleting first occurence of #include \
\"%s\" line into buffer file with regex_replace() ...\n", first_match));
        if (!regex_replace(buffer, pattern_include, ""))
        {
          fprintf(stderr, "      regex_replace() failed\n");
          return false;
        }
        VERB(verbose, printf("      Line successfully deleted\n"));
      } else {

        VERB(verbose, printf("      \"%s\" is not already included\n",
          first_match));

        includes_length++;

        VERB(verbose, printf("      Reallocating memory for includes ...\n");)
        includes = realloc(includes, sizeof(char*) * includes_length);
        if (!includes)
        {
          fprintf (stderr, "      includes realloc() failed\n");
          return false;
        }
        VERB(verbose, printf("      Memory reallocated successfully\n"));

        VERB(verbose, printf("      Allocating memory for includes[%lu] \
...\n", includes_length - 1);)
        includes[includes_length - 1] =
          malloc(sizeof(char) * (end_include - start_include + 1));
        if (!includes[includes_length - 1])
        {
          fprintf (stderr, "      includes[%lu] malloc() failed\n",
            includes_length - 1);
          return false;
        }
        VERB(verbose, printf("      Memory allocated successfully\n"));

        VERB(verbose, printf("      Copying string into includes[%lu] ...\n",
          includes_length - 1));
        strncpy(includes[includes_length - 1], first_match,
          end_include - start_include);
        includes[includes_length - 1][end_include - start_include] = '\0';
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          includes[includes_length - 1]));

        VERB(verbose, printf("      Allocating memory for header_filepath \
...\n");)
        header_filepath = malloc(sizeof(char) * (strlen(*filepath) + 1));
        if (!header_filepath)
        {
          fprintf(stderr, "      header_filepath malloc() failed\n");
          return false;
        }
        VERB(verbose, printf("      Memory allocated successfully\n"));

        VERB(verbose, printf("      Copying string into header_filepath \
...\n"));
        strcpy(header_filepath, *filepath);
        VERB(verbose, printf("      \"%s\" successfully copied\n",
          header_filepath));

        VERB(verbose, printf("      Replacing first occurence of \"%s\" by \
\"%s\" into \"%s\" ...\n", pattern_main, first_match, header_filepath));
        if (!regex_replace(&header_filepath, pattern_main, first_match))
        {
          fprintf(stderr, "      regex_replace() failed\n");
          return false;
        }
        VERB(verbose, printf("      Regex replacement done: %s\n",
          header_filepath));

        VERB(verbose, printf("      Reading file %s ... \n",
          header_filepath));
        if (!readFile(&header_filepath, &tmp_buffer, "  ", verbose, roadmap))
        {
          free(header_filepath);
          free(first_match);
          for (size_t i = 0; i < includes_length; ++i)
          {
            free(includes[i]);
          }
          free(includes);
          regfree(&regex);
          return false;
        }
        VERB(verbose, printf("      File read successfully\n"));

        if (!regex_replace(buffer, pattern_include, tmp_buffer))
        {
          fprintf(stderr, "      regex_replace() failed\n");

          VERB(verbose, printf("      Freeing header_filepath memory ...\n"));
          free(header_filepath);
          VERB(verbose, printf("      Memory freed successfully\n"));

          VERB(verbose, printf("      Freeing tmp_buffer memory ...\n"));
          free(tmp_buffer);
          VERB(verbose, printf("      Memory freed successfully\n"));

          VERB(verbose, printf("      Freeing first_match memory ...\n"));
          free(first_match);
          VERB(verbose, printf("      Memory freed successfully\n"));

          for (size_t i = 0; i < includes_length; ++i)
          {
            VERB(verbose, printf("      Freeing includes[%lu] memory ...\n",
              i));
            free(includes[i]);
            VERB(verbose, printf("      Memory freed successfully\n"));
          }

          VERB(verbose, printf("      Freeing includes memory ...\n"));
          free(includes);
          VERB(verbose, printf("      Memory freed successfully\n"));

          VERB(verbose, printf("      Freeing regex structure ...\n"));
          regfree(&regex);
          VERB(verbose, printf("      Memory freed successfully\n"));

          return false;
        }
        VERB(verbose, printf("      Freeing header_filepath memory ...\n"));
        free(header_filepath);
        VERB(verbose, printf("      Memory freed successfully\n"));

        VERB(verbose, printf("      Freeing tmp_buffer memory ...\n"));
        free(tmp_buffer);
        VERB(verbose, printf("      Memory freed successfully\n"));
      }

      VERB(verbose, printf("      Freeing first_match memory ...\n"));
      free(first_match);
      VERB(verbose, printf("      Memory freed successfully\n"));

      VERB(verbose,
        printf("      Comparing regex pattern to buffer file ...\n"));
      match = regexec(&regex, *buffer, nmatch + 1, m, REG_NOTBOL);
      VERB(verbose, printf("      Regex pattern compared successfully\n"));
    }
    VERB(verbose, printf("    File buffer is now:\n\
------------------------------------------------------------------------------\
\n%s\n\
------------------------------------------------------------------------------\
\n", *buffer));

    for (size_t i = 0; i < includes_length; ++i)
    {
      VERB(verbose, printf("    Freeing includes[%lu] memory ...\n", i));
      VERB(verbose, printf("    Memory freed successfully\n"));
      free(includes[i]);
    }

    VERB(verbose, printf("    Freeing includes memory ...\n"));
    free(includes);
    VERB(verbose, printf("    Memory freed successfully\n"));

    VERB(verbose, printf("    Freeing regex structure ...\n"));
    regfree(&regex);
    VERB(verbose, printf("    Memory freed successfully\n"));

    if (match != REG_NOMATCH)
    {
      VERB(verbose, printf("    Searching for regex errors ...\n"));
      size_t size = regerror(regex_error, &regex, NULL, 0);

      VERB(verbose, printf("      Allocating text memory ...\n"));
      char* text = malloc(sizeof(*text) * size);
      if (!text)
      {
        fprintf (stderr, "      text malloc() failed\n");
        return false;
      }
      VERB(verbose, printf("      Memory allocated successfully\n"));

      regerror(regex_error, &regex, text, size);
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
