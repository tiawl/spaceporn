#include "xshader.h"

void CheckOpenGLError(const char* stmt, const char* fname, int line)
{
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    fprintf(stderr, "OpenGL error %08x, at %s:%i - for %s\n", error, fname,
      line, stmt);
    abort();
  }
}

/************************************************************************
                          Uniforms functions
*************************************************************************/

void updateFloatUniforms(GLint uniformId, UniformValues* values, bool verbose)
{
  values->time = ((double)(clock() - values->clock)) / CLOCKS_PER_SEC;
  GLfloat fflags[UNIFORM_FLOATS] =
  {
    values->width, values->height, values->xseed, values->yseed,
    values->time, values->pixels
  };

  VERB(verbose, printf("    New fflags values: [%d, %d, %f, %f, %f, %d]\n",
    values->width, values->height, fflags[2], fflags[3], fflags[4],
    values->pixels));

  VERB(verbose, printf("    Specifying value of fflags in current program \
...\n"));
  GL_CHECK(glUniform1fv(uniformId, UNIFORM_FLOATS, fflags));
  VERB(verbose, printf("    Value of fflags specified in current program\n"));
}

void updateBoolUniforms(GLint uniformId, UniformValues* values, bool verbose)
{
  VERB(verbose, printf("    New bflags values: [%s, %s, %s]\n",
    values->animations ? "true" : "false", values->motion ? "true" : "false",
    values->palettes ? "true" : "false"));

  VERB(verbose, printf("    Specifying value of bflags in current program \
...\n"));
  GL_CHECK(glUniform3i(uniformId, values->animations, values->motion,
    values->palettes));
  VERB(verbose, printf("    Value of bflags specified in current program\n"));
}

/**************************************************************************/

bool initPaths(char** fshaderpath, char** vshaderpath, char** texturepath,
  bool verbose)
{
  VERB(verbose, printf("  Computing length of home directory path ...\n"));
  const size_t len1 = strlen(HOME_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", HOME_DIR, len1));

  VERB(verbose, printf("  Computing username length ...\n"));
  const size_t len2 = strlen(getenv("USERNAME"));
  VERB(verbose, printf("  Length of \"%s\" is %lu\n",
    getenv("USERNAME"), len2));

  VERB(verbose, printf("  Computing length of binary directory path ...\n"));
  const size_t len3 = strlen(BIN_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", BIN_DIR, len3));

  VERB(verbose, printf("  Computing length of shaders directory path ...\n"));
  const size_t len4 = strlen(SHADERS_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", SHADERS_DIR, len4));

  VERB(verbose, printf("  Computing length of textures directory path ...\n"));
  const size_t len5 = strlen(TEXTURES_DIR);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURES_DIR, len5));

  VERB(verbose, printf("  Computing length of fragment shader filename ...\n"));
  const size_t len6 = strlen(FSHADER_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", FSHADER_FILE, len6));

  VERB(verbose, printf("  Computing length of vertex shader filename ...\n"));
  const size_t len7 = strlen(VSHADER_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", VSHADER_FILE, len7));

  VERB(verbose, printf("  Computing length of texture filename ...\n"));
  const size_t len8 = strlen(TEXTURE_FILE);
  VERB(verbose, printf("  Length of \"%s\" is %lu\n", TEXTURE_FILE, len8));

  VERB(verbose, printf("  Allocating memory for fragment shader path ...\n"));
  *fshaderpath = malloc(len1 + len2 + len3 + len4 + len6 + 1);

  if (!*fshaderpath)
  {
    fprintf(stderr, "fshaderpath malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for fragment shader \
path ...\n"));

  VERB(verbose, printf("  Allocating memory for vertex shader path ...\n"));
  *vshaderpath = malloc(len1 + len2 + len3 + len4 + len7 + 1);

  if (!*vshaderpath)
  {
    fprintf(stderr, "vshaderpath malloc() failed\n");

    VERB(verbose, printf("  Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("  fshaderpath freed\n"));

    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for vertex shader \
path\n"));

  VERB(verbose, printf("  Allocating memory for texture path ...\n"));
  *texturepath = malloc(len1 + len2 + len3 + len5 + len8 + 1);

  if (!*texturepath)
  {
    fprintf(stderr, "texturepath malloc() failed\n");

    VERB(verbose, printf("  Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("  fshaderpath freed\n"));

    VERB(verbose, printf("  Freeing vshaderpath ...\n"));
    free(vshaderpath);
    VERB(verbose, printf("  vshaderpath freed\n"));

    return false;
  }
  VERB(verbose, printf("  Successfull allocated memory for texture path\n"));

  VERB(verbose, printf("  Building fragment shader path string ... 0/5\n"));
  memcpy(*fshaderpath, HOME_DIR, len1);
  VERB(verbose, printf("  Building fragment shader path string ... 1/5\n"));
  memcpy(*fshaderpath + len1, getenv("USERNAME"), len2);
  VERB(verbose, printf("  Building fragment shader path string ... 2/5\n"));
  memcpy(*fshaderpath + len1 + len2, BIN_DIR, len3);
  VERB(verbose, printf("  Building fragment shader path string ... 3/5\n"));
  memcpy(*fshaderpath + len1 + len2 + len3, SHADERS_DIR, len4);
  VERB(verbose, printf("  Building fragment shader path string ... 4/5\n"));
  memcpy(*fshaderpath + len1 + len2 + len3 + len4, FSHADER_FILE, len6 + 1);
  VERB(verbose, printf("  Building fragment shader path string ... 5/5\n"));
  VERB(verbose, printf("  Fragment shader path string built: %s\n",
    *fshaderpath));

  VERB(verbose, printf("  Building vertex shader path string ... 0/5\n"));
  memcpy(*vshaderpath, HOME_DIR, len1);
  VERB(verbose, printf("  Building vertex shader path string ... 1/5\n"));
  memcpy(*vshaderpath + len1, getenv("USERNAME"), len2);
  VERB(verbose, printf("  Building vertex shader path string ... 2/5\n"));
  memcpy(*vshaderpath + len1 + len2, BIN_DIR, len3);
  VERB(verbose, printf("  Building vertex shader path string ... 3/5\n"));
  memcpy(*vshaderpath + len1 + len2 + len3, SHADERS_DIR, len4);
  VERB(verbose, printf("  Building vertex shader path string ... 4/5\n"));
  memcpy(*vshaderpath + len1 + len2 + len3 + len4, VSHADER_FILE, len7 + 1);
  VERB(verbose, printf("  Building vertex shader path string ... 5/5\n"));
  VERB(verbose, printf("  Vertex shader path string built: %s\n",
    *vshaderpath));

  VERB(verbose, printf("  Building texture path string ... 0/5\n"));
  memcpy(*texturepath, HOME_DIR, len1);
  VERB(verbose, printf("  Building texture path string ... 1/5\n"));
  memcpy(*texturepath + len1, getenv("USERNAME"), len2);
  VERB(verbose, printf("  Building texture path string ... 2/5\n"));
  memcpy(*texturepath + len1 + len2, BIN_DIR, len3);
  VERB(verbose, printf("  Building texture path string ... 3/5\n"));
  memcpy(*texturepath + len1 + len2 + len3, TEXTURES_DIR, len5);
  VERB(verbose, printf("  Building texture path string ... 4/5\n"));
  memcpy(*texturepath + len1 + len2 + len3 + len5, TEXTURE_FILE, len8 + 1);
  VERB(verbose, printf("  Building texture path string ... 5/5\n"));
  VERB(verbose, printf("  Texture path string built: %s\n", *texturepath));

  return true;
}

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

void getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, bool verbose)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    VERB(verbose, printf("  Querying uniform location of %s\n",
      uniforms[i].name));
    GL_CHECK(uniformIds[i] =
      glGetUniformLocation(*program, uniforms[i].name));
    VERB(verbose, printf("  %s uniform located\n", uniforms[i].name));
  }
}

void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, bool verbose)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    VERB(verbose, printf("  Updating %s ... \n", uniforms[i].name));
    uniforms[i].update(uniformIds[i], values, verbose);
    VERB(verbose, printf("  %s updated\n", uniforms[i].name));
  }
}

void initVertices(GLuint* vertexbuffer, GLuint* vertexarray, bool verbose)
{
  VERB(verbose, printf("  Generating vertex array object ...\n"));
  GL_CHECK(glGenVertexArrays(1, vertexarray));
  VERB(verbose, printf("  Vertex array object generated is %d\n",
    *vertexarray));

  VERB(verbose, printf("  Binding vertex array object ...\n"));
  GL_CHECK(glBindVertexArray(*vertexarray));
  VERB(verbose, printf("  Vertex array object binded\n"));

  static const GLfloat g_vertex_buffer_data[] =
  {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    1.0f, 1.0f
  };

  VERB(verbose, printf("  Generating vertex buffer object ...\n"));
  GL_CHECK(glGenBuffers(1, vertexbuffer));
  VERB(verbose, printf("  Vertex buffer object generated is %d\n",
    *vertexbuffer));

  VERB(verbose, printf("  Binding vertex buffer object ...\n"));
  GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, *vertexbuffer));
  VERB(verbose, printf("  Vertex buffer object binded\n"));

  VERB(verbose, printf("  Initializing vertex buffer object's data store \
...\n"));
  GL_CHECK(glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data),
    g_vertex_buffer_data, GL_STATIC_DRAW));
  VERB(verbose, printf("  Vertex buffer object's data store initialized\n"));

  VERB(verbose, printf("  Enabling vertex attribute array ...\n"));
  GL_CHECK(glEnableVertexAttribArray(0));
  VERB(verbose, printf("  Vertex attribute array enabled\n"));

  VERB(verbose, printf("  Defining array of vertex attribute data ...\n"));
  GL_CHECK(glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0));
  VERB(verbose, printf("  Array of vertex attribute data defined\n"));
}

void draw(bool verbose)
{
  VERB(verbose, printf("  Clearing depth buffer of the window and indicating \
buffers enabled for color writing ...\n"));
  GL_CHECK(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT));
  VERB(verbose, printf("  Depth buffer cleared and buffer enabled\n"));

  VERB(verbose, printf("  Clearing color buffer of the window to black color \
...\n"));
  GL_CHECK(glClearColor(0.0, 0.0, 0.0, 0.0));
  VERB(verbose, printf("  Color buffer cleared\n"));

  VERB(verbose, printf("  Rendering primitives ...\n"));
  GL_CHECK(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4));
  VERB(verbose, printf("  Primitives rendered\n"));
}

void cleanup(png_structp* parser, png_infop* info, png_bytep** row_pointers,
  uint8_t** data, FILE** file, char const * const filename, bool verbose)
{
  if(*parser)
  {
    VERB(verbose, printf("    Freeing information about PNG file ...\n"));
    png_destroy_read_struct(parser, *info ? info : 0, 0);
    VERB(verbose, printf("    Information freed\n"));
  }

  if(*row_pointers)
  {
    VERB(verbose, printf("    Freeing row_pointers ...\n"));
    free(*row_pointers);
    VERB(verbose, printf("    row_pointers freed\n"));
  }

  if(*data)
  {
    VERB(verbose, printf("    Freeing PNG data ...\n"));
    free(*data);
    VERB(verbose, printf("    PNG data freed\n"));
  }

  if(*file)
  {
    VERB(verbose, printf("    Closing PNG file ...\n"));
    fclose(*file);
    VERB(verbose, printf("    PNG file closed\n"));
  }
}

bool loadPng(GLuint* texture, char const* const filename, bool verbose)
{
  FILE* file = 0;
  uint8_t* data = 0;
  png_structp parser = 0;
  png_infop info = 0;
  png_bytep* row_pointers = 0;

  png_uint_32 w, h;
  int bit_depth;
  int color_type;

  if (!filename)
  {
    fprintf(stderr, "One or more loadPng() pointers arguments are null\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load PNG file\n");
    return false;
  }

  VERB(verbose, printf("  Opening PNG file \"%s\"...\n", filename));
  file = fopen(filename, "rb");
  if (!file)
  {
    fprintf(stderr, "Failed to open \"%s\"\n", filename);
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  PNG file opened\n"));

  VERB(verbose, printf("  Creating structure for reading PNG file ...\n"));
  parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
  if (!parser)
  {
    fprintf(stderr, "png_create_read_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }
  VERB(verbose, printf("  Structure for reading PNG file created\n"));

  VERB(verbose, printf("  Creating PNG info structure ...\n"));
  info = png_create_info_struct(parser);
  if (!info)
  {
    fprintf(stderr, "png_create_info_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }
  VERB(verbose, printf("  PNG info structure created\n"));

  VERB(verbose, printf("  Searching libPNG error ...\n"));
  if (setjmp(png_jmpbuf(parser)))
  {
    fprintf(stderr, "Routine problem: libPNG encountered an error\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }
  VERB(verbose, printf("  No error found\n"));

  VERB(verbose, printf("  Initializing PNG input/output ...\n"));
  png_init_io(parser, file);
  VERB(verbose, printf("  PNG input/output initialized\n"));

  VERB(verbose, printf("  Reading PNG info ...\n"));
  png_read_info(parser, info);
  VERB(verbose, printf("  PNG info read\n"));

  VERB(verbose, printf("  Querying PNG_IHDR chunk information from PNG info \
structure ...\n"));
  png_get_IHDR(parser, info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
  VERB(verbose, printf("  PNG_IHDR chunk information found\n"));

  VERB(verbose, printf("  Testing PNG images dimensions ...\n"));
  if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
  {
    fprintf(stderr, "PNG images with dimensions that are not power of two \
or smaller than 8 failed to load in OpenGL\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }
  VERB(verbose, printf("  Valid PNG images dimensions\n"));

  VERB(verbose, printf("  Testing validity of chunk data ...\n"));
  if (png_get_valid(parser, info, PNG_INFO_tRNS) ||
    (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) ||
    color_type == PNG_COLOR_TYPE_PALETTE)
  {
    VERB(verbose, printf("  Valid chunk data\n"));

    VERB(verbose, printf("  Setting expansion transformation ...\n"));
    png_set_expand(parser);
    VERB(verbose, printf("  Expansion transformation set\n"));
  } else {
    VERB(verbose, printf("  Unvalid chunk data\n"));
  }

  if (bit_depth == 16)
  {
    VERB(verbose, printf("  Striping 16 bit PNG file to 8 bit depth ...\n"));
    png_set_strip_16(parser);
    VERB(verbose, printf("  16 bit PNG file to 8 bit depth modification \
done\n"));
  }

  if (color_type == PNG_COLOR_TYPE_GRAY ||
    color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
  {
    VERB(verbose, printf("  Expanding grayscale image to 24-bit RGB ...\n"));
    png_set_gray_to_rgb(parser);
    VERB(verbose, printf("  Grayscale image expanded\n"));
  }

  VERB(verbose, printf("  Updating PNG info structure ...\n"));
  png_read_update_info(parser, info);
  VERB(verbose, printf("  PNG info structure updated\n"));

  VERB(verbose, printf("  Querying number of bytes for a row ...\n"));
  int rowbytes = png_get_rowbytes(parser, info);
  rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes
  VERB(verbose, printf("  Number of bytes for a row is %d\n", rowbytes));

  VERB(verbose, printf("  Allocating memory for data ...\n"));
  data = malloc(rowbytes * h * sizeof(png_byte) + 15);
  if (!data)
  {
    fprintf(stderr, "data malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }
  VERB(verbose, printf("  Memory allocated for data\n"));

  VERB(verbose, printf("  Allocating memory for row_pointers ...\n"));
  row_pointers = malloc(h * sizeof(png_bytep));
  if (!row_pointers)
  {
    fprintf(stderr, "row_pointers malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }
  VERB(verbose, printf("  Memory allocated for row_pointers\n"));

  for(png_uint_32 i = 0; i < h; ++i)
  {
    VERB(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", i, h));
    row_pointers[h - 1 - i] = data + i * rowbytes;
  }
  VERB(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", h, h));
  VERB(verbose, printf("  Individual row_pointers set\n"));

  VERB(verbose, printf("  Reading PNG image into memory ...\n"));
  png_read_image(parser, row_pointers);
  VERB(verbose, printf("  PNG image read into memory\n"));

  VERB(verbose, printf("  Generating OpenGL texture ...\n"));
  GL_CHECK(glGenTextures(1, texture));
  VERB(verbose, printf("  OpenGL texture is %d\n", *texture));

  VERB(verbose, printf("  Binding OpenGL texture ...\n"));
  GL_CHECK(glBindTexture(GL_TEXTURE_2D, *texture));
  VERB(verbose, printf("  OpenGL texture binded\n"));

  GLenum texture_format =
    (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;

  VERB(verbose, printf("  Specifying 2D OpenGL texture ...\n"));
  GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h,
    0, texture_format, GL_UNSIGNED_BYTE, data));
  VERB(verbose, printf("  2D OpenGL texture specified\n"));

  VERB(verbose, printf("  Disabling OpenGL Texture repetition ...\n"));
  GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
    GL_CLAMP_TO_BORDER));
  GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
    GL_CLAMP_TO_BORDER));
  VERB(verbose, printf("  OpenGL texture repetition disabled\n"));

  VERB(verbose, printf("  Specifying texture element value to the nearest \
texture coordinates ...\n"));
  GL_CHECK(glTexParameteri(
    GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST));
  GL_CHECK(glTexParameteri(
    GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
  VERB(verbose, printf("  Texture element value specified ...\n"));

  cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
  return true;
}
