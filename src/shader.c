#include "shader.h"

bool buildFile(char** filepath, char** buffer, bool verbose, Roadmap* roadmap)
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

bool buildVertexShaderFile(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  if (roadmap->id == FOPEN_VERTEX_FILE_FAILED_RM)
  {
    roadmap->id = FOPEN_FAILED_RM;
  } else if (roadmap->id == BUFFER_VERTEX_FILE_MALLOC_FAILED_RM) {
    roadmap->id = BUFFER_MALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REGCOMP_FAILED_RM) {
    roadmap->id = SARH_REGCOMP_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_HEADERS_MALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADERS_MALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADER_MALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM) {
    roadmap->id = SARH_ADDMARKERS_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REPLACE_1_REGCOMP_FAILED_RM) {
    roadmap->id = SARH_REPLACE_1_REGCOMP_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REPLACE_1_REALLOC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_1_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REPLACE_1_REGEXEC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_1_REGEXEC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_HEADERS_REALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADERS_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_HEADER_REALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADER_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_READFILE_BUFFER_MALLOC_FAILED_RM) {
    roadmap->id = SARH_READFILE_BUFFER_MALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_READFILE_FOPEN_FAILED_RM) {
    roadmap->id = SARH_READFILE_FOPEN_FAILED_RM;
  } else if (roadmap->id ==
    VERTEX_FILE_SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) {
      roadmap->id = SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REPLACE_2_REGCOMP_FAILED_RM) {
    roadmap->id = SARH_REPLACE_2_REGCOMP_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REPLACE_2_REALLOC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_2_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_2_REGEXEC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_SARH_REGEXEC_FAILED_RM) {
    roadmap->id = SARH_REGEXEC_FAILED_RM;
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

bool buildFragmentShaderFile(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  if (roadmap->id == FOPEN_FRAGMENT_FILE_FAILED_RM)
  {
    roadmap->id = FOPEN_FAILED_RM;
  } else if (roadmap->id == BUFFER_FRAGMENT_FILE_MALLOC_FAILED_RM) {
    roadmap->id = BUFFER_MALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REGCOMP_FAILED_RM) {
    roadmap->id = SARH_REGCOMP_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_HEADERS_MALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADERS_MALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_HEADER_MALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADER_MALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM) {
    roadmap->id = SARH_ADDMARKERS_REALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REPLACE_1_REGCOMP_FAILED_RM) {
    roadmap->id = SARH_REPLACE_1_REGCOMP_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REPLACE_1_REALLOC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_1_REALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REPLACE_1_REGEXEC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_1_REGEXEC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_HEADERS_REALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADERS_REALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_HEADER_REALLOC_FAILED_RM) {
    roadmap->id = SARH_HEADER_REALLOC_FAILED_RM;
  } else if (roadmap->id ==
    FRAGMENT_FILE_SARH_READFILE_BUFFER_MALLOC_FAILED_RM) {
      roadmap->id = SARH_READFILE_BUFFER_MALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_READFILE_FOPEN_FAILED_RM) {
    roadmap->id = SARH_READFILE_FOPEN_FAILED_RM;
  } else if (roadmap->id ==
    FRAGMENT_FILE_SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) {
      roadmap->id = SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REPLACE_2_REGCOMP_FAILED_RM) {
    roadmap->id = SARH_REPLACE_2_REGCOMP_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REPLACE_2_REALLOC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_2_REALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM) {
    roadmap->id = SARH_REPLACE_2_REGEXEC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_SARH_REGEXEC_FAILED_RM) {
    roadmap->id = SARH_REGEXEC_FAILED_RM;
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
  bool verbose, Roadmap* roadmap)
{
  GLint shaderCompiled = GL_FALSE;
  GL_CHECK(glGetShaderiv(*shader, GL_COMPILE_STATUS, &shaderCompiled));

  if (shaderCompiled != GL_TRUE)
  {
    VERB(verbose, fprintf(stderr, "    "));
    fprintf(stderr, "Unable to compile %s shader\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");

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

      if (!improveLogShader(&message, &buffer, maxLength, verbose, roadmap))
      {
        return false;
      }

      VERB(verbose, printf("    Log info of %s shader found:\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
      fprintf(stderr, "\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", message);

      free(message);
    }

    return false;
  }

  return true;
}

bool loadShader(Shaders* shaders, GLenum shaderType, bool verbose,
  Roadmap* roadmap)
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

bool loadVertexShader(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  if (roadmap->id == VERTEX_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
  {
    roadmap->id = IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_ILS_REPLACE_REALLOC_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_ILS_REPLACE_REGEXEC_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_ILS_REGCOMP_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REGCOMP_FAILED_RM;
  } else if (roadmap->id == VERTEX_FILE_ILS_REGEXEC_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REGEXEC_FAILED_RM;
  }
  if (!loadShader(shaders, GL_VERTEX_SHADER, verbose, roadmap))
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Failed to compile vertex shader\n");
    return false;
  }

  return true;
}

bool loadFragmentShader(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  if (roadmap->id == FRAGMENT_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
  {
    roadmap->id = IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_ILS_REPLACE_REALLOC_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_ILS_REPLACE_REGEXEC_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_ILS_REGCOMP_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REGCOMP_FAILED_RM;
  } else if (roadmap->id == FRAGMENT_FILE_ILS_REGEXEC_FAILED_RM) {
    roadmap->id = IMPROVELOGSHADER_REGEXEC_FAILED_RM;
  }
  if (!loadShader(shaders, GL_FRAGMENT_SHADER, verbose, roadmap))
  {
    VERB(verbose, fprintf(stderr, "  "));
    fprintf(stderr, "Failed to compile fragment shader\n");
    return false;
  }

  return true;
}

bool checkLogProgram(Shaders* shaders, bool verbose, Roadmap* roadmap)
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
  Roadmap* roadmap)
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
