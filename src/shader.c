#include "shader.h"

bool buildFile(char** filepath, char** buffer, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("    Reading file \"%s\" ...\n", *filepath));
    if (!readFile(filepath, buffer, "", verbose, roadmap))
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "Failed to read file\n");
      status = false;
      break;
    }
    LOG(verbose, printf("    File read successfully\n"));

    if (!searchAndReplaceHeaders(filepath, buffer, verbose, roadmap))
    {
      status = false;
      break;
    }
  } while (false);

  return status;
}

bool buildVertexShaderFile(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

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
    LOG(verbose, printf("  "));
    fprintf((verbose ? stdout : stderr),
      "Failed to build vertex shader file\n");
    status = false;
  }

  return status;
}

bool buildFragmentShaderFile(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

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
    LOG(verbose, printf("  "));
    fprintf((verbose ? stdout : stderr),
      "Failed to build fragment shader file\n");
    status = false;
  }

  return status;
}

bool checkLogShader(GLuint* shader, GLenum shaderType, char* buffer,
  bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    GLint shaderCompiled = GL_FALSE;
    GL_CHECK(glGetShaderiv(*shader, GL_COMPILE_STATUS, &shaderCompiled),
      status);

    if (shaderCompiled != GL_TRUE)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "Unable to compile %s shader\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");

      GLint maxLength = 0;

      LOG(verbose, printf("    Querying log length of %s shader ...\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
      GL_CHECK(glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &maxLength), status);
      LOG(verbose, printf("    Log length of %s shader is %d\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex", maxLength));

      if (maxLength > 0)
      {
        char* message = malloc(sizeof(char) * maxLength);

        LOG(verbose, printf("    Querying log info of %s shader ...\n",
          shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
        GL_CHECK(glGetShaderInfoLog(*shader, maxLength, &maxLength, message),
          status);

        if (!improveLogShader(&message, &buffer, maxLength, verbose, roadmap))
        {
          free(message);
          status = false;
          break;
        }

        LOG(verbose, printf("    Log info of %s shader found:\n",
          shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
        fprintf((verbose ? stdout : stderr), "\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", message);

        free(message);
      }

      status = false;
      break;
    }
  } while (false);

  return status;
}

bool loadShader(Shaders* shaders, GLenum shaderType, bool verbose,
  Roadmap* roadmap)
{
  bool status = true;

  do
  {
    GLuint* shader = shaderType == GL_FRAGMENT_SHADER ?
      &(shaders->fragment_shader) : &(shaders->vertex_shader);

    LOG(verbose, printf("    Creating %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(*shader = glCreateShader(shaderType), status);
    LOG(verbose, printf("    %s shader %d created\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex", *shader));

    LOG(verbose, printf("    Setting source code in %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glShaderSource(*shader, 1, shaderType == GL_FRAGMENT_SHADER ?
      (const GLchar**) &(shaders->fragment_file) :
        (const GLchar**) &(shaders->vertex_file), NULL), status);
    LOG(verbose, printf("    Source code in %s shader set\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

    LOG(verbose, printf("    Compiling %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glCompileShader(*shader), status);
    LOG(verbose, printf("    %s shader probably compiled\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));

    LOG(verbose, printf("    Checking compile status of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    if (!checkLogShader(shader, shaderType, shaderType == GL_FRAGMENT_SHADER ?
      shaders->fragment_file : shaders->vertex_file, verbose, roadmap))
    {
      status = false;
      break;
    }
    LOG(verbose, printf("    %s shader compiled\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));
  } while (false);

  return status;
}

bool loadVertexShader(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

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
    LOG(verbose, printf("  "));
    fprintf((verbose ? stdout : stderr), "Failed to compile vertex shader\n");
    status = false;
  }

  return status;
}

bool loadFragmentShader(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

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
    LOG(verbose, printf("  "));
    fprintf((verbose ? stdout : stderr), "Failed to compile fragment shader\n");
    status = false;
  }

  return status;
}

bool checkLogProgram(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Checking linking status of OpenGL program ...\n"));

    GLint programSuccess = GL_TRUE;
    GL_CHECK(glGetProgramiv(shaders->program, GL_LINK_STATUS, &programSuccess),
      status);

    if (programSuccess != GL_TRUE)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Unable to link OpenGL program\n");

      GLint maxLength = 0;

      LOG(verbose, printf("  Querying log length of OpenGL program \
...\n"));
      GL_CHECK(glGetProgramiv(shaders->program, GL_INFO_LOG_LENGTH,
        &maxLength), status);
      LOG(verbose, printf("  Log length of OpenGL program is %d\n",
        maxLength));

      if (maxLength > 0)
      {
        char message[maxLength];

        LOG(verbose, printf("  Querying log info of OpenGL program ...\n"));
        GL_CHECK(glGetProgramInfoLog(shaders->program, maxLength, &maxLength,
          message), status);
        LOG(verbose, printf("  Log info of OpenGL program found:\n"));

        fprintf((verbose ? stdout : stderr), "\
------------------------------------------------------------------------------\
\n%s\
------------------------------------------------------------------------------\
\n", &(message[0]));
      }

      status = false;
      break;
    }
  } while (false);

  return status;
}

bool loadProgram(Context* context, Shaders* shaders, bool verbose,
  Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Creating OpenGL Program ...\n"));
    GL_CHECK(shaders->program = glCreateProgram(), status);
    LOG(verbose, printf("  OpenGL Program %d created\n", shaders->program));

    LOG(verbose, printf("  Building vertex shader file ...\n"));
    if (!buildVertexShaderFile(shaders, verbose, roadmap))
    {
      status = false;
      break;
    }
    LOG(verbose, printf("  Vertex shader file built\n"));

    LOG(verbose, printf("  Building fragment shader file ...\n"));
    if (!buildFragmentShaderFile(shaders, verbose, roadmap))
    {
      status = false;
      break;
    }
    LOG(verbose, printf("  Fragment shader file built\n"));

    LOG(verbose, printf("  Loading vertex shader ...\n"));
    if (!loadVertexShader(shaders, verbose, roadmap))
    {
      status = false;
      break;
    }
    LOG(verbose, printf("  Vertex shader loaded\n"));

    LOG(verbose, printf("  Loading fragment shader ...\n"));
    if (!loadFragmentShader(shaders, verbose, roadmap))
    {
      status = false;
      break;
    }
    LOG(verbose, printf("  Fragment shader loaded\n"));

    LOG(verbose, printf("  Attaching vertex shader to OpenGL program ...\n"));
    GL_CHECK(glAttachShader(shaders->program, shaders->vertex_shader), status);
    LOG(verbose, printf("  Vertex shader attached\n"));

    LOG(verbose, printf("  Attaching fragment shader to OpenGL program \
  ...\n"));
    GL_CHECK(glAttachShader(shaders->program, shaders->fragment_shader),
      status);
    LOG(verbose, printf("  Fragment shader attached\n"));

    LOG(verbose, printf("  Linking OpenGL program ...\n"));
    GL_CHECK(glLinkProgram(shaders->program), status);
    LOG(verbose, printf("  OpenGL program probably linked\n"));

    if (!checkLogProgram(shaders, verbose, roadmap))
    {
      status = false;
      break;
    }
    LOG(verbose, printf("  OpenGL program linked\n"));

    LOG(verbose, printf("  Checking OpenGL program execution ...\n"));
    GL_CHECK(glValidateProgram(shaders->program), status);
    LOG(verbose, printf("  OpenGL program execution checked\n"));

    LOG(verbose, printf("  Installing OpenGL program as part of current \
rendering state...\n"));
    GL_CHECK(glUseProgram(shaders->program), status);
    LOG(verbose, printf("  OpenGL program installed\n"));

    LOG(verbose, printf("  Specifying viewport ...\n"));
    GL_CHECK(glViewport(0, 0, context->window_attribs.width,
      context->window_attribs.height), status);
    LOG(verbose, printf("  Viewport specified\n"));

    LOG(verbose, printf("  Detaching vertex shader to OpenGL program ...\n"));
    GL_CHECK(glDetachShader(shaders->program, shaders->vertex_shader), status);
    LOG(verbose, printf("  Vertex shader detached\n"));

    LOG(verbose, printf("  Detaching fragment shader to OpenGL program \
...\n"));
    GL_CHECK(glDetachShader(shaders->program, shaders->fragment_shader),
      status);
    LOG(verbose, printf("  Fragment shader detached\n"));
  } while (false);

  return status;
}

bool freeProgram(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  if (shaders->vertex_file)
  {
    LOG(verbose, printf("Freeing vertex file ...\n"));
    free(shaders->vertex_file);
    shaders->vertex_file = NULL;
    LOG(verbose, printf("Vertex file freed\n"));
  }

  if (shaders->fragment_file)
  {
    LOG(verbose, printf("Freeing fragment file ...\n"));
    free(shaders->fragment_file);
    shaders->fragment_file = NULL;
    LOG(verbose, printf("Fragment file freed\n"));
  }

  do
  {
    if (shaders->vertex_shader)
    {
      LOG(verbose, printf("Deleting vertex shader ...\n"));
      GL_CHECK(glDeleteShader(shaders->vertex_shader), status);
      shaders->vertex_shader = 0;
      LOG(verbose, printf("Vertex shader deleted\n"));
    }
  } while (false);

  do
  {
    if (shaders->fragment_shader)
    {
      LOG(verbose, printf("Deleting fragment shader ...\n"));
      GL_CHECK(glDeleteShader(shaders->fragment_shader), status);
      shaders->fragment_shader = 0;
      LOG(verbose, printf("Fragment shader deleted\n"));
    }
  } while (false);

  do
  {
    if (shaders->program)
    {
      LOG(verbose, printf("Deleting OpenGL program ...\n"));
      GL_CHECK(glDeleteProgram(shaders->program), status);
      shaders->program = 0;
      LOG(verbose, printf("OpenGL program deleted\n"));
    }
  } while (false);

  return status;
}
