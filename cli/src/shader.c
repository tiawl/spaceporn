#include "shader.h"

bool buildFile(char** filepath, char** buffer, char** dirpath, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "", "    Reading file \"%s\" ...\n",
      *filepath);
    if (!readFile(filepath, buffer, "", log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Failed to read file\n");
      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    File read successfully\n");

    if (!searchAndReplaceHeaders(dirpath, buffer, log))
    {
      status = false;
      break;
    }
  } while (false);

  return status;
}

bool buildVertexShaderFile(Shaders* shaders, Log* log)
{
  bool status = true;

  if (log->roadmap.id == FOPEN_VERTEX_FILE_FAILED_RM)
  {
    log->roadmap.id = FOPEN_FAILED_RM;
  } else if (log->roadmap.id == BUFFER_VERTEX_FILE_MALLOC_FAILED_RM) {
    log->roadmap.id = BUFFER_MALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_REGCOMP_FAILED_RM) {
    log->roadmap.id = SARH_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_HEADERS_MALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADERS_MALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_HEADER_MALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADER_MALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    VERTEX_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_ADDMARKERS_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    VERTEX_FILE_SARH_REPLACE_1_REGCOMP_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_1_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id ==
    VERTEX_FILE_SARH_REPLACE_1_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_1_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    VERTEX_FILE_SARH_REPLACE_1_REGEXEC_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_1_REGEXEC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_HEADERS_REALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADERS_REALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_HEADER_REALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADER_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    VERTEX_FILE_SARH_READFILE_BUFFER_MALLOC_FAILED_RM) {
      log->roadmap.id = SARH_READFILE_BUFFER_MALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_READFILE_FOPEN_FAILED_RM) {
    log->roadmap.id = SARH_READFILE_FOPEN_FAILED_RM;
  } else if (log->roadmap.id ==
    VERTEX_FILE_SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_REPLACE_2_REGCOMP_FAILED_RM) {
    log->roadmap.id = SARH_REPLACE_2_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_REPLACE_2_REALLOC_FAILED_RM) {
    log->roadmap.id = SARH_REPLACE_2_REALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM) {
    log->roadmap.id = SARH_REPLACE_2_REGEXEC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_SARH_REGEXEC_FAILED_RM) {
    log->roadmap.id = SARH_REGEXEC_FAILED_RM;
  }

  if (!buildFile(&(shaders->vshaderpath), &(shaders->vertex_file),
    &(shaders->vshaderdir), log))
  {
    writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
      "Failed to build vertex shader file\n");
    status = false;
  }

  return status;
}

bool buildFragmentShaderFile(Shaders* shaders, Log* log)
{
  bool status = true;

  if (log->roadmap.id == FOPEN_FRAGMENT_FILE_FAILED_RM)
  {
    log->roadmap.id = FOPEN_FAILED_RM;
  } else if (log->roadmap.id == BUFFER_FRAGMENT_FILE_MALLOC_FAILED_RM) {
    log->roadmap.id = BUFFER_MALLOC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_SARH_REGCOMP_FAILED_RM) {
    log->roadmap.id = SARH_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_SARH_HEADERS_MALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADERS_MALLOC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_SARH_HEADER_MALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADER_MALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_ADDMARKERS_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_ADDMARKERS_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_REPLACE_1_REGCOMP_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_1_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_REPLACE_1_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_1_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_REPLACE_1_REGEXEC_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_1_REGEXEC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_HEADERS_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_HEADERS_REALLOC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_SARH_HEADER_REALLOC_FAILED_RM) {
    log->roadmap.id = SARH_HEADER_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_READFILE_BUFFER_MALLOC_FAILED_RM) {
      log->roadmap.id = SARH_READFILE_BUFFER_MALLOC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_SARH_READFILE_FOPEN_FAILED_RM) {
    log->roadmap.id = SARH_READFILE_FOPEN_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_ADDMARKERS_IN_LOOP_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_REPLACE_2_REGCOMP_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_2_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_REPLACE_2_REALLOC_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_2_REALLOC_FAILED_RM;
  } else if (log->roadmap.id ==
    FRAGMENT_FILE_SARH_REPLACE_2_REGEXEC_FAILED_RM) {
      log->roadmap.id = SARH_REPLACE_2_REGEXEC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_SARH_REGEXEC_FAILED_RM) {
    log->roadmap.id = SARH_REGEXEC_FAILED_RM;
  }

  if (!buildFile(&(shaders->fshaderpath), &(shaders->fragment_file),
    &(shaders->fshaderdir), log))
  {
    writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
      "Failed to build fragment shader file\n");
    status = false;
  }

  return status;
}

bool checkLogShader(GLuint* shader, GLenum shaderType, char* buffer, Log* log)
{
  bool status = true;

  do
  {
    GLint shaderCompiled = GL_FALSE;
    GL_CHECK(glGetShaderiv(*shader, GL_COMPILE_STATUS, &shaderCompiled),
      status, log);

    if (shaderCompiled != GL_TRUE)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Unable to compile %s shader\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");

      GLint maxLength = 0;

      writeLog(log, stdout, DEBUG, "",
        "    Querying log length of %s shader ...\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
      GL_CHECK(glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &maxLength), status,
        log);
      writeLog(log, stdout, DEBUG, "", "    Log length of %s shader is %d\n",
        shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex", maxLength);

      if (maxLength > 0)
      {
        char* message = malloc(sizeof(char) * maxLength);

        writeLog(log, stdout, DEBUG, "",
          "    Querying log info of %s shader ...\n",
          shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
        GL_CHECK(glGetShaderInfoLog(*shader, maxLength, &maxLength, message),
          status, log);

        if (!improveLogShader(&message, &buffer, log))
        {
          free(message);
          status = false;
          break;
        }

        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
          "Log info of %s shader found:\n",
          shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "", "%s\n%s%s\n",
          BAR, message, BAR);

        free(message);
      }

      status = false;
      break;
    }
  } while (false);

  return status;
}

bool loadShader(Shaders* shaders, GLenum shaderType, Log* log)
{
  bool status = true;

  do
  {
    GLuint* shader = shaderType == GL_FRAGMENT_SHADER ?
      &(shaders->fragment_shader) : &(shaders->vertex_shader);

    writeLog(log, stdout, INFO, "", "    Creating %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
    GL_CHECK(*shader = glCreateShader(shaderType), status, log);
    writeLog(log, stdout, INFO, "", "    %s shader %d created\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex", *shader);

    writeLog(log, stdout, DEBUG, "",
      "    Setting source code in %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
    GL_CHECK(glShaderSource(*shader, 1, shaderType == GL_FRAGMENT_SHADER ?
      (const GLchar**) &(shaders->fragment_file) :
        (const GLchar**) &(shaders->vertex_file), NULL), status, log);
    writeLog(log, stdout, DEBUG, "", "    Source code in %s shader set\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");

    writeLog(log, stdout, INFO, "", "    Compiling %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
    GL_CHECK(glCompileShader(*shader), status, log);
    writeLog(log, stdout, DEBUG, "", "    %s shader probably compiled\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex");

    writeLog(log, stdout, DEBUG, "",
      "    Checking compile status of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex");
    if (!checkLogShader(shader, shaderType, shaderType == GL_FRAGMENT_SHADER ?
      shaders->fragment_file : shaders->vertex_file, log))
    {
      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "", "    %s shader compiled\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex");
  } while (false);

  return status;
}

bool loadVertexShader(Shaders* shaders, Log* log)
{
  bool status = true;

  if (log->roadmap.id == VERTEX_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
  {
    log->roadmap.id = IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_ILS_REPLACE_REALLOC_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_ILS_REPLACE_REGEXEC_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_ILS_REGCOMP_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == VERTEX_FILE_ILS_REGEXEC_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REGEXEC_FAILED_RM;
  }
  if (!loadShader(shaders, GL_VERTEX_SHADER, log))
  {
    writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
      "Failed to compile vertex shader\n");
    status = false;
  }

  return status;
}

bool loadFragmentShader(Shaders* shaders, Log* log)
{
  bool status = true;

  if (log->roadmap.id == FRAGMENT_FILE_ILS_REPLACE_REGCOMP_FAILED_RM)
  {
    log->roadmap.id = IMPROVELOGSHADER_REPLACE_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_ILS_REPLACE_REALLOC_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REPLACE_REALLOC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_ILS_REPLACE_REGEXEC_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REPLACE_REGEXEC_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_ILS_REGCOMP_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REGCOMP_FAILED_RM;
  } else if (log->roadmap.id == FRAGMENT_FILE_ILS_REGEXEC_FAILED_RM) {
    log->roadmap.id = IMPROVELOGSHADER_REGEXEC_FAILED_RM;
  }
  if (!loadShader(shaders, GL_FRAGMENT_SHADER, log))
  {
    writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
      "Failed to compile fragment shader\n");
    status = false;
  }

  return status;
}

bool checkLogProgram(Shaders* shaders, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "",
      "  Checking linking status of OpenGL program ...\n");

    GLint programSuccess = GL_TRUE;
    GL_CHECK(glGetProgramiv(shaders->program, GL_LINK_STATUS, &programSuccess),
      status, log);

    if (programSuccess != GL_TRUE)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
       "Unable to link OpenGL program\n");

      GLint maxLength = 0;

      writeLog(log, stdout, DEBUG, "",
        "  Querying log length of OpenGL program ...\n");
      GL_CHECK(glGetProgramiv(shaders->program, GL_INFO_LOG_LENGTH,
        &maxLength), status, log);
      writeLog(log, stdout, DEBUG, "", "  Log length of OpenGL program is %d\n",
        maxLength);

      if (maxLength > 0)
      {
        char message[maxLength];

        writeLog(log, stdout, DEBUG, "",
          "  Querying log info of OpenGL program ...\n");
        GL_CHECK(glGetProgramInfoLog(shaders->program, maxLength, &maxLength,
          message), status, log);
        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
          "Log info of OpenGL program found:\n");

        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
          "%s\n%s%s\n", BAR, &(message[0]), BAR);
      }

      status = false;
      break;
    }
  } while (false);

  return status;
}

bool loadProgram(Context* context, Shaders* shaders, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, INFO, "", "  Creating OpenGL Program ...\n");
    GL_CHECK(shaders->program = glCreateProgram(), status, log);
    writeLog(log, stdout, INFO, "", "  OpenGL Program %d created\n",
      shaders->program);

    writeLog(log, stdout, DEBUG, "", "  Building vertex shader file ...\n");
    if (!buildVertexShaderFile(shaders, log))
    {
      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Vertex shader file built\n");

    writeLog(log, stdout, DEBUG, "", "  Building fragment shader file ...\n");
    if (!buildFragmentShaderFile(shaders, log))
    {
      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Fragment shader file built\n");

    writeLog(log, stdout, DEBUG, "", "  Loading vertex shader ...\n");
    if (!loadVertexShader(shaders, log))
    {
      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Vertex shader loaded\n");

    writeLog(log, stdout, DEBUG, "", "  Loading fragment shader ...\n");
    if (!loadFragmentShader(shaders, log))
    {
      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Fragment shader loaded\n");

    writeLog(log, stdout, DEBUG, "",
      "  Attaching vertex shader to OpenGL program ...\n");
    GL_CHECK(glAttachShader(shaders->program, shaders->vertex_shader), status,
      log);
    writeLog(log, stdout, DEBUG, "", "  Vertex shader attached\n");

    writeLog(log, stdout, DEBUG, "",
      "  Attaching fragment shader to OpenGL program ...\n");
    GL_CHECK(glAttachShader(shaders->program, shaders->fragment_shader),
      status, log);
    writeLog(log, stdout, DEBUG, "", "  Fragment shader attached\n");

    writeLog(log, stdout, DEBUG, "", "  Linking OpenGL program ...\n");
    GL_CHECK(glLinkProgram(shaders->program), status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL program probably linked\n");

    if (!checkLogProgram(shaders, log))
    {
      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  OpenGL program linked\n");

    writeLog(log, stdout, DEBUG, "",
      "  Checking OpenGL program execution ...\n");
    GL_CHECK(glValidateProgram(shaders->program), status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL program execution checked\n");

    writeLog(log, stdout, DEBUG, "",
      "  Installing OpenGL program as part of current rendering state...\n");
    GL_CHECK(glUseProgram(shaders->program), status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL program installed\n");

    writeLog(log, stdout, DEBUG, "", "  Specifying viewport ...\n");
    GL_CHECK(glViewport(0, 0, context->window_attribs.width,
      context->window_attribs.height), status, log);
    writeLog(log, stdout, DEBUG, "", "  Viewport specified\n");

    writeLog(log, stdout, DEBUG, "",
      "  Detaching vertex shader to OpenGL program ...\n");
    GL_CHECK(glDetachShader(shaders->program, shaders->vertex_shader), status,
      log);
    writeLog(log, stdout, DEBUG, "", "  Vertex shader detached\n");

    writeLog(log, stdout, DEBUG, "",
      "  Detaching fragment shader to OpenGL program ...\n");
    GL_CHECK(glDetachShader(shaders->program, shaders->fragment_shader),
      status, log);
    writeLog(log, stdout, DEBUG, "", "  Fragment shader detached\n");
  } while (false);

  return status;
}

bool freeProgram(Shaders* shaders, Log* log)
{
  bool status = true;

  if (shaders->fshaderdir)
  {
    writeLog(log, stdout, DEBUG, "",
      "Freeing fragment shader directory path ...\n");
    free(shaders->fshaderdir);
    shaders->fshaderdir = NULL;
    writeLog(log, stdout, DEBUG, "", "Fragment shader directory path freed\n");
  }

  if (shaders->fshaderpath)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing fragment shader path ...\n");
    free(shaders->fshaderpath);
    shaders->fshaderpath = NULL;
    writeLog(log, stdout, DEBUG, "", "Fragment shader path freed\n");
  }

  if (shaders->vshaderdir)
  {
    writeLog(log, stdout, DEBUG, "",
      "Freeing vertex shader directory path ...\n");
    free(shaders->vshaderdir);
    shaders->vshaderdir = NULL;
    writeLog(log, stdout, DEBUG, "", "Vertex shader directory path freed\n");
  }

  if (shaders->vshaderpath)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing vertex shader path ...\n");
    free(shaders->vshaderpath);
    shaders->vshaderpath = NULL;
    writeLog(log, stdout, DEBUG, "", "Vertex shader path freed\n");
  }

  if (shaders->vertex_file)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing vertex file ...\n");
    free(shaders->vertex_file);
    shaders->vertex_file = NULL;
    writeLog(log, stdout, DEBUG, "", "Vertex file freed\n");
  }

  if (shaders->fragment_file)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing fragment file ...\n");
    free(shaders->fragment_file);
    shaders->fragment_file = NULL;
    writeLog(log, stdout, DEBUG, "", "Fragment file freed\n");
  }

  do
  {
    if (shaders->vertex_shader)
    {
      writeLog(log, stdout, DEBUG, "", "Deleting vertex shader ...\n");
      GL_CHECK(glDeleteShader(shaders->vertex_shader), status, log);
      shaders->vertex_shader = 0;
      writeLog(log, stdout, DEBUG, "", "Vertex shader deleted\n");
    }
  } while (false);

  do
  {
    if (shaders->fragment_shader)
    {
      writeLog(log, stdout, DEBUG, "", "Deleting fragment shader ...\n");
      GL_CHECK(glDeleteShader(shaders->fragment_shader), status, log);
      shaders->fragment_shader = 0;
      writeLog(log, stdout, DEBUG, "", "Fragment shader deleted\n");
    }
  } while (false);

  do
  {
    if (shaders->program)
    {
      writeLog(log, stdout, DEBUG, "", "Deleting OpenGL program ...\n");
      GL_CHECK(glDeleteProgram(shaders->program), status, log);
      shaders->program = 0;
      writeLog(log, stdout, DEBUG, "", "OpenGL program deleted\n");
    }
  } while (false);

  return status;
}
