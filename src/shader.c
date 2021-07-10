#include "shader.h"

bool readFile(char** filepath, char** buffer, bool verbose)
{
  long length;

  VERB(verbose, printf("    Opening \"%s\" ...\n", *filepath));
  FILE* f = fopen(*filepath, "r");

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
    *buffer = malloc(length + 1);
    if (*buffer)
    {
      VERB(verbose, printf("    Memory for reading file buffer allocated\n"));

      VERB(verbose, printf("    Reading file into buffer ...\n"))
      fread(*buffer, 1, length, f);
      VERB(verbose, printf("    Buffer filled\n"))

    } else {
      fprintf(stderr, "Buffer malloc() failed\n");
      return false;
    }

    VERB(verbose, printf("    Closing \"%s\" ...\n", *filepath));
    fclose(f);
    VERB(verbose, printf("    \"%s\" closed\n", *filepath));

    (*buffer)[length] = '\0'; // fread does not 0 terminate strings
  } else {
    fprintf(stderr, "Failed to read inside \"%s\": %s\n", *filepath,
      strerror(errno));
    return false;
  }

  return true;
}

bool readVertexShaderFile(Context* context, Shaders* shaders, bool verbose)
{
  if (!readFile(&(shaders->vshaderpath), &(shaders->vertex_file), verbose))
  {
    fprintf(stderr, "Failed to read in vertex shader file\n");

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(context->program));
    context->program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  return true;
}

bool readFragmentShaderFile(Context* context, Shaders* shaders, bool verbose)
{
  if (!readFile(&(shaders->fshaderpath), &(shaders->fragment_file), verbose))
  {
    fprintf(stderr, "Failed to read in fragment shader file\n");

    freeShaders(shaders, verbose);

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(context->program));
    context->program = 0;

    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  return true;
}

void checkingLogShader(GLuint* shader, GLenum shaderType, bool verbose)
{
  GLint shaderCompiled = GL_FALSE;
  GL_CHECK(glGetShaderiv(*shader, GL_COMPILE_STATUS, &shaderCompiled));
  if (shaderCompiled != GL_TRUE)
  {
    fprintf(stderr, "Unable to compile %s shader\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex");

    GLint maxLength = 0;

    VERB(verbose, printf("    Querying log length of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &maxLength));
    VERB(verbose, printf("    Log length of %s shader is %d\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex", maxLength));

    char message[maxLength];

    VERB(verbose, printf("    Querying log info of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glGetShaderInfoLog(*shader, maxLength, &maxLength, message));
    VERB(verbose, printf("    Log info of %s shader found\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

    fprintf(stderr, "%s\n", &(message[0]));

    VERB(verbose, printf("    Deleting %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glDeleteShader(*shader));
    *shader = 0;
    VERB(verbose, printf("    %s shader deleted\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));
  } else {
    VERB(verbose, printf("    %s shader compiled\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));
  }
}

GLuint loadShader(const char* shaderSource, GLenum shaderType, bool verbose)
{
  GLuint shader;

  VERB(verbose, printf("    Creating %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(shader = glCreateShader(shaderType));
  VERB(verbose, printf("    %s shader %d created\n",
    shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex", shader));

  VERB(verbose, printf("    Setting source code in %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(glShaderSource(shader, 1, (const GLchar**)&shaderSource, NULL));
  VERB(verbose, printf("    Source code in %s shader set\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

  VERB(verbose, printf("    Compiling %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(glCompileShader(shader));

  VERB(verbose, printf("    Checking compile status of %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  checkingLogShader(&shader, shaderType, verbose);

  return shader;
}

bool loadVertexShader(Context* context, Shaders* shaders, bool verbose)
{
  shaders->vertex_shader =
    loadShader(shaders->vertex_file, GL_VERTEX_SHADER, verbose);
  if (shaders->vertex_shader == 0)
  {
    fprintf(stderr, "Failed to load vertex shader\n");

    freeShaders(shaders, verbose);

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(context->program));
    context->program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  return true;
}

bool loadFragmentShader(Context* context, Shaders* shaders, bool verbose)
{
  shaders->fragment_shader =
    loadShader(shaders->fragment_file, GL_FRAGMENT_SHADER, verbose);
  if (shaders->fragment_shader == 0)
  {
    fprintf(stderr, "Failed to load fragment shader\n");

    freeShaders(shaders, verbose);
    shaders->vertex_shader = 0;

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(context->program));
    context->program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  return true;
}

void freeShaders(Shaders* shaders, bool verbose)
{
  if (!shaders->vertex_file)
  {
    VERB(verbose, printf("  Freeing vertex file ...\n"));
    free(shaders->vertex_file);
    VERB(verbose, printf("  Vertex file freed\n"));
  }

  if (!shaders->fragment_file)
  {
    VERB(verbose, printf("  Freeing fragment file ...\n"));
    free(shaders->fragment_file);
    VERB(verbose, printf("  Fragment file freed\n"));
  }

  if (!shaders->vertex_shader)
  {
    VERB(verbose, printf("  Deleting vertex shader ...\n"));
    GL_CHECK(glDeleteShader(shaders->vertex_shader));
    VERB(verbose, printf("  Vertex shader deleted\n"));
  }

  if (!shaders->fragment_shader)
  {
    VERB(verbose, printf("  Deleting fragment shader ...\n"));
    GL_CHECK(glDeleteShader(shaders->fragment_shader));
    VERB(verbose, printf("  Fragment shader deleted\n"));
  }
}

bool checkingLogProgram(Context* context, Shaders* shaders, bool verbose)
{
  GLint programSuccess = GL_TRUE;
  GL_CHECK(glGetProgramiv(context->program, GL_LINK_STATUS, &programSuccess));
  if (programSuccess != GL_TRUE)
  {
    fprintf(stderr, "Unable to link OpenGL program \n");

    GLint maxLength = 0;

    VERB(verbose, printf("  Querying log length of OpenGL program ...\n"));
    GL_CHECK(glGetProgramiv(context->program, GL_INFO_LOG_LENGTH,
      &maxLength));
    VERB(verbose, printf("  Log length of OpenGL program is %d\n",
      maxLength));

    char message[maxLength];

    VERB(verbose, printf("  Querying log info of OpenGL program ...\n"));
    GL_CHECK(glGetShaderInfoLog(context->program, maxLength, &maxLength,
      message));
    VERB(verbose, printf("  Log info of OpenGL program found\n"));

    fprintf(stderr, "%s\n", &(message[0]));

    freeShaders(shaders, verbose);
    shaders->vertex_shader = 0;
    shaders->fragment_shader = 0;

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(context->program));
    context->program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  return true;
}

bool loadProgram(Context* context, Shaders* shaders, bool verbose)
{
  VERB(verbose, printf("  Creating OpenGL Program ...\n"));
  GL_CHECK(context->program = glCreateProgram());
  VERB(verbose, printf("  OpenGL Program %d created\n", context->program));

  VERB(verbose, printf("  Reading in vertex shader file ...\n"));
  if (!readVertexShaderFile(context, shaders, verbose))
  {
    return false;
  }
  VERB(verbose, printf("  Vertex shader file read\n"));

  VERB(verbose, printf("  Reading in fragment shader file ...\n"));
  if (!readFragmentShaderFile(context, shaders, verbose))
  {
    return false;
  }
  VERB(verbose, printf("  Fragment shader file read\n"));

  VERB(verbose, printf("  Loading vertex shader ...\n"));
  if (!loadVertexShader(context, shaders, verbose))
  {
    return false;
  }
  VERB(verbose, printf("  Vertex shader loaded\n"));

  VERB(verbose, printf("  Loading fragment shader ...\n"));
  if (!loadFragmentShader(context, shaders, verbose))
  {
    return false;
  }
  VERB(verbose, printf("  Fragment shader loaded\n"));

  VERB(verbose, printf("  Attaching vertex shader to OpenGL program ...\n"));
  GL_CHECK(glAttachShader(context->program, shaders->vertex_shader));
  VERB(verbose, printf("  Vertex shader attached\n"));

  VERB(verbose, printf("  Attaching fragment shader to OpenGL program \
...\n"));
  GL_CHECK(glAttachShader(context->program, shaders->fragment_shader));
  VERB(verbose, printf("  Fragment shader attached\n"));

  VERB(verbose, printf("  Linking OpenGL program ...\n"));
  GL_CHECK(glLinkProgram(context->program));

  VERB(verbose, printf("  Checking linking status of OpenGL program ...\n"));
  if (!checkingLogProgram(context, shaders, verbose))
  {
    return false;
  }
  VERB(verbose, printf("  OpenGL program linked\n"));

  VERB(verbose, printf("  Checking OpenGL program execution ...\n"));
  GL_CHECK(glValidateProgram(context->program));
  VERB(verbose, printf("  OpenGL program execution checked\n"));

  VERB(verbose, printf("  Installing OpenGL program as part of current \
rendering state...\n"));
  GL_CHECK(glUseProgram(context->program));
  VERB(verbose, printf("  OpenGL program installed\n"));

  VERB(verbose, printf("  Specifying viewport ...\n"));
  GL_CHECK(glViewport(0, 0, context->window_attribs.width,
    context->window_attribs.height));
  VERB(verbose, printf("  Viewport specified\n"));

  VERB(verbose, printf("  Detaching vertex shader to OpenGL program ...\n"));
  GL_CHECK(glDetachShader(context->program, shaders->vertex_shader));
  VERB(verbose, printf("  Vertex shader detached\n"));

  VERB(verbose, printf("  Detaching fragment shader to OpenGL program \
...\n"));
  GL_CHECK(glDetachShader(context->program, shaders->fragment_shader));
  VERB(verbose, printf("  Fragment shader detached\n"));

  freeShaders(shaders, verbose);

  return true;
}
