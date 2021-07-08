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

  GLint shaderCompiled = GL_FALSE;

  VERB(verbose, printf("    Checking compile status of %s shader ...\n",
    shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
  GL_CHECK(glGetShaderiv(shader, GL_COMPILE_STATUS, &shaderCompiled));
  if (shaderCompiled != GL_TRUE)
  {
    fprintf(stderr, "Unable to compile %s shader\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex");

    GLint maxLength = 0;

    VERB(verbose, printf("    Querying log length of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &maxLength));
    VERB(verbose, printf("    Log length of %s shader is %d\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex", maxLength));

    char message[maxLength];

    VERB(verbose, printf("    Querying log info of %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glGetShaderInfoLog(shader, maxLength, &maxLength, message));
    VERB(verbose, printf("    Log info of %s shader found\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));

    fprintf(stderr, "%s\n", &(message[0]));

    VERB(verbose, printf("    Deleting %s shader ...\n",
      shaderType == GL_FRAGMENT_SHADER ? "fragment" : "vertex"));
    GL_CHECK(glDeleteShader(shader));
    shader = 0;
    VERB(verbose, printf("    %s shader deleted\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));
  } else {
    VERB(verbose, printf("    %s shader compiled\n",
      shaderType == GL_FRAGMENT_SHADER ? "Fragment" : "Vertex"));
  }

  return shader;
}

bool loadProgram(GLuint* program, GLuint* vertex_shader,
  char** vshaderpath, GLuint* fragment_shader, char** fshaderpath,
  bool verbose)
{
  VERB(verbose, printf("  Creating OpenGL Program ...\n"));
  GL_CHECK(*program = glCreateProgram());
  VERB(verbose, printf("  OpenGL Program %d created\n", *program));

  VERB(verbose, printf("  Reading in vertex shader file ...\n"));
  char* vertex_file = 0;
  if (!readFile(vshaderpath, &vertex_file, verbose))
  {
    fprintf(stderr, "Failed to read in vertex shader file\n");

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  VERB(verbose, printf("  Vertex shader file read\n"));

  VERB(verbose, printf("  Reading in fragment shader file ...\n"));
  char* fragment_file = 0;
  if (!readFile(fshaderpath, &fragment_file, verbose))
  {
    fprintf(stderr, "Failed to read in fragment shader file\n");

    VERB(verbose, printf("  Freeing vertex file ...\n"));
    free(vertex_file);
    VERB(verbose, printf("  Vertex file freed\n"));

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  VERB(verbose, printf("  Fragment shader file read\n"));

  VERB(verbose, printf("  Loading vertex shader ...\n"));
  *vertex_shader = loadShader(vertex_file, GL_VERTEX_SHADER, verbose);
  if (*vertex_shader == 0)
  {
    fprintf(stderr, "Failed to load vertex shader\n");

    VERB(verbose, printf("  Freeing vertex file ...\n"));
    free(vertex_file);
    VERB(verbose, printf("  Vertex file freed\n"));

    VERB(verbose, printf("  Freeing fragment file ...\n"));
    free(fragment_file);
    VERB(verbose, printf("  Fragment file freed\n"));

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  VERB(verbose, printf("  Vertex shader loaded\n"));

  VERB(verbose, printf("  Loading fragment shader ...\n"));
  *fragment_shader = loadShader(fragment_file, GL_FRAGMENT_SHADER, verbose);
  if (*fragment_shader == 0)
  {
    fprintf(stderr, "Failed to load fragment shader\n");

    VERB(verbose, printf("  Freeing vertex file ...\n"));
    free(vertex_file);
    VERB(verbose, printf("  Vertex file freed\n"));

    VERB(verbose, printf("  Freeing fragment file ...\n"));
    free(fragment_file);
    VERB(verbose, printf("  Fragment file freed\n"));

    VERB(verbose, printf("  Deleting vertex shader ...\n"));
    GL_CHECK(glDeleteShader(*vertex_shader));
    *vertex_shader = 0;
    VERB(verbose, printf("  Vertex shader deleted\n"));

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }
  VERB(verbose, printf("  Fragment shader loaded\n"));

  VERB(verbose, printf("  Attaching vertex shader to OpenGL program ...\n"));
  GL_CHECK(glAttachShader(*program, *vertex_shader));
  VERB(verbose, printf("  Vertex shader attached\n"));

  VERB(verbose, printf("  Attaching fragment shader to OpenGL program \
...\n"));
  GL_CHECK(glAttachShader(*program, *fragment_shader));
  VERB(verbose, printf("  Fragment shader attached\n"));

  VERB(verbose, printf("  Linking OpenGL program ...\n"));
  GL_CHECK(glLinkProgram(*program));

  VERB(verbose, printf("  Checking linking status of OpenGL program ...\n"));
  GLint programSuccess = GL_TRUE;
  GL_CHECK(glGetProgramiv(*program, GL_LINK_STATUS, &programSuccess));
  if (programSuccess != GL_TRUE)
  {
    fprintf(stderr, "Unable to link OpenGL program \n");

    GLint maxLength = 0;

    VERB(verbose, printf("  Querying log length of OpenGL program ...\n"));
    GL_CHECK(glGetProgramiv(*program, GL_INFO_LOG_LENGTH, &maxLength));
    VERB(verbose, printf("  Log length of OpenGL program is %d\n",
      maxLength));

    char message[maxLength];

    VERB(verbose, printf("  Querying log info of OpenGL program ...\n"));
    GL_CHECK(glGetShaderInfoLog(*program, maxLength, &maxLength, message));
    VERB(verbose, printf("  Log info of OpenGL program found\n"));

    fprintf(stderr, "%s\n", &(message[0]));

    VERB(verbose, printf("  Freeing vertex file ...\n"));
    free(vertex_file);
    VERB(verbose, printf("  Vertex file freed\n"));

    VERB(verbose, printf("  Freeing fragment file ...\n"));
    free(fragment_file);
    VERB(verbose, printf("  Fragment file freed\n"));

    VERB(verbose, printf("  Deleting vertex shader ...\n"));
    GL_CHECK(glDeleteShader(*vertex_shader));
    *vertex_shader = 0;
    VERB(verbose, printf("  Vertex shader deleted\n"));

    VERB(verbose, printf("  Deleting fragment shader ...\n"));
    GL_CHECK(glDeleteShader(*fragment_shader));
    *fragment_shader = 0;
    VERB(verbose, printf("  Fragment shader deleted\n"));

    VERB(verbose, printf("  Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  OpenGL program deleted\n"));

    return false;
  }

  VERB(verbose, printf("  OpenGL program linked\n"));

  VERB(verbose, printf("  Checking OpenGL program execution ...\n"));
  GL_CHECK(glValidateProgram(*program));
  VERB(verbose, printf("  OpenGL program execution checked\n"));

  VERB(verbose, printf("  Detaching vertex shader to OpenGL program ...\n"));
  GL_CHECK(glDetachShader(*program, *vertex_shader));
  VERB(verbose, printf("  Vertex shader detached\n"));

  VERB(verbose, printf("  Detaching fragment shader to OpenGL program \
...\n"));
  GL_CHECK(glDetachShader(*program, *fragment_shader));
  VERB(verbose, printf("  Fragment shader detached\n"));

  VERB(verbose, printf("  Deleting vertex shader ...\n"));
  GL_CHECK(glDeleteShader(*vertex_shader));
  VERB(verbose, printf("  Vertex shader deleted\n"));

  VERB(verbose, printf("  Deleting fragment shader ...\n"));
  GL_CHECK(glDeleteShader(*fragment_shader));
  VERB(verbose, printf("  Fragment shader deleted\n"));

  return true;
}
