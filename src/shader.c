#include "shader.h"

bool readFile(char** filepath, char** buffer, bool verbose,
  enum Roadmap roadmap)
{
  long length;

  VERB(verbose, printf("    Opening \"%s\" ...\n", *filepath));
  FILE* f = NULL;

  if (roadmap != FOPEN_FAILED_RM)
  {
    f = fopen(*filepath, "r");
  }

  if (f)
  {
    VERB(verbose, printf("    \"%s\" opened\n", *filepath));

    VERB(verbose, printf("    Setting file position of the stream to the end \
...\n"));
    fseek(f, 0, SEEK_END);
    VERB(verbose, printf("    Stream positionned\n"));

    VERB(verbose, printf("    Computing file position of the stream ...\n"));
    length = ftell(f);
    VERB(verbose, printf("    File position of the stream computed\n"));

    VERB(verbose, printf("    Setting file position of the stream to the \
beginning ...\n"));
    fseek(f, 0, SEEK_SET);
    VERB(verbose, printf("    Stream positionned\n"));

    VERB(verbose, printf("    Allocating memory for reading file buffer \
...\n"));
    if ((roadmap != BUFFER_MALLOC_FAILED_RM) &&
      (roadmap != SHADER_COMPILATION_FAILED_RM) &&
      (roadmap != LINKING_PROGRAM_FAILED_RM))
    {
      *buffer = malloc(length + 1);
    }

    if (*buffer)
    {
      VERB(verbose, printf("    Memory for reading file buffer allocated\n"));

      VERB(verbose, printf("    Reading file into buffer ...\n"))
      if ((roadmap != SHADER_COMPILATION_FAILED_RM) &&
        (roadmap != LINKING_PROGRAM_FAILED_RM))
      {
        fread(*buffer, 1, length, f);
      }
      VERB(verbose, printf("    Buffer filled with:\n\
------------------------------------------------------------------------------\
\n%s\n\
------------------------------------------------------------------------------\
\n", *buffer))

    } else {
      fprintf(stderr, "    Buffer malloc() failed\n");
      return false;
    }

    VERB(verbose, printf("    Closing \"%s\" ...\n", *filepath));
    fclose(f);
    VERB(verbose, printf("    \"%s\" closed\n", *filepath));

    if ((roadmap != SHADER_COMPILATION_FAILED_RM) &&
      (roadmap != LINKING_PROGRAM_FAILED_RM))
    {
      (*buffer)[length] = '\0'; // fread does not 0 terminate strings
    }

  } else {
    fprintf(stderr, "    Failed to read inside \"%s\": %s\n", *filepath,
      strerror(errno));
    return false;
  }

  return true;
}

bool readVertexShaderFile(Shaders* shaders, bool verbose,
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

  if (!readFile(&(shaders->vshaderpath), &(shaders->vertex_file), verbose,
    roadmap))
  {
    fprintf(stderr, "  Failed to read in vertex shader file\n");
    return false;
  }

  return true;
}

bool readFragmentShaderFile(Shaders* shaders, bool verbose,
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

  if (!readFile(&(shaders->fshaderpath), &(shaders->fragment_file), verbose,
    roadmap))
  {
    fprintf(stderr, "  Failed to read in fragment shader file\n");
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

  VERB(verbose, printf("  Reading in vertex shader file ...\n"));
  if (!readVertexShaderFile(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  Vertex shader file read\n"));

  VERB(verbose, printf("  Reading in fragment shader file ...\n"));
  if (!readFragmentShaderFile(shaders, verbose, roadmap))
  {
    return false;
  }
  VERB(verbose, printf("  Fragment shader file read\n"));

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
