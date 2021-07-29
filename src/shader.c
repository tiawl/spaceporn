#include "shader.h"

bool buildFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap)
{
  VERB(verbose, printf("    Reading file \"%s\" ... \n", *filepath));
  if (!readFile(filepath, buffer, "", verbose, roadmap))
  {
    VERB(verbose, fprintf(stderr, "    "));
    fprintf(stderr, "Failed to read file\n");
    return false;
  }
  VERB(verbose, printf("    File read successfully\n"));

  if (!searchAndReplaceHeaders(filepath, buffer, verbose, roadmap))
  {
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
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Failed to build vertex shader file\n");
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
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Failed to build fragment shader file\n");
    return false;
  }

  return true;
}

bool checkLogShader(GLuint* shader, GLenum shaderType, char* buffer,
  bool verbose, enum Roadmap roadmap)
{
  GLint shaderCompiled = GL_FALSE;
  GL_CHECK(glGetShaderiv(*shader, GL_COMPILE_STATUS, &shaderCompiled));

  if (shaderCompiled != GL_TRUE)
  {
    VERB(verbose, fprintf(stderr, "    "));
    fprintf(stderr, "Unable to compile %s shader\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex");

    GLint maxLength = 0;

    VERB(verbose, printf("    Querying log length of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &maxLength));
    VERB(verbose, printf("    Log length of %s shader is %d\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex", maxLength));

    if (maxLength > 0)
    {
      char* message = malloc(sizeof(char) * maxLength);

      VERB(verbose, printf("    Querying log info of %s shader ...\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
      GL_CHECK(glGetShaderInfoLog(*shader, maxLength, &maxLength, message));
      VERB(verbose, printf("    Log info of %s shader found:\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

      regex_t regex;
      char* pattern_startlinelog =
        "^[[:digit:]]+:([[:digit:]]+)\\([[:digit:]]+\\)";

      VERB(verbose, printf("    Compiling regex pattern: \"%s\" ...\n",
        pattern_startlinelog));
      if (regcomp(&regex, pattern_startlinelog, REG_EXTENDED | REG_NEWLINE)
        == 0)
      {
        VERB(verbose, printf("    Regex pattern compiled successfully\n"));

        size_t nmatch = regex.re_nsub;
        regmatch_t m[nmatch + 1];
        int match = regexec(&regex, message, nmatch + 1, m, 0);

        size_t start;
        size_t end;

        unsigned l;

        while (match == 0)
        {
          start = m[1].rm_so;
          end = m[1].rm_eo;

          char line[end - start];
          line[0] = '\0';
          strncat(line, message + start, end - start);
          l = strtoul(line, NULL, 10);

          unsigned i = 0;
          end = 0;

          while ((i < l) && (buffer[end] != '\0'))
          {
            if (buffer[end] == '\n')
            {
              ++i;
            }
            if (i < l)
            {
              ++end;
            }
          }

          start = end;
          while (buffer[start] != '/')
          {
            --start;
          }
          start += 2;

          char marker[end - start];
          marker[0] = '\0';
          strncat(marker, buffer + start, end - start);

          regex_replace(&message, pattern_startlinelog, marker, "", verbose,
            roadmap);

          match = regexec(&regex, message, nmatch + 1, m, 0);
        }
      } else {
      }

      fprintf(stderr, "\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", message);

      free(message);
      regfree(&regex);
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
  if (!checkLogShader(shader, shaderType, shaderType == GL_FRAGMENT_SHADER ?
    shaders->fragment_file : shaders->vertex_file, verbose, roadmap))
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
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Failed to compile vertex shader\n");
    return false;
  }

  return true;
}

bool loadFragmentShader(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  if (!loadShader(shaders, GL_FRAGMENT_SHADER, verbose, roadmap))
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Failed to compile fragment shader\n");
    return false;
  }

  return true;
}

bool checkLogProgram(Shaders* shaders, bool verbose, enum Roadmap roadmap)
{
  VERB(verbose, printf("  Checking linking status of OpenGL program ...\n"));

  GLint programSuccess = GL_TRUE;
  GL_CHECK(glGetProgramiv(shaders->program, GL_LINK_STATUS, &programSuccess));

  if (programSuccess != GL_TRUE)
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Unable to link OpenGL program \n");

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

  if (!checkLogProgram(shaders, verbose, roadmap))
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
