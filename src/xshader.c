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

void updateFloatUniforms(GLint uniformId, UniformValues* values)
{
  values->time = ((double)(clock() - values->clock)) / CLOCKS_PER_SEC;
  GLfloat ffloats[UNIFORM_FLOATS] =
  {
    values->width, values->height, values->xseed, values->yseed,
    values->time, values->pixels
  };
  GL_CHECK(glUniform1fv(uniformId, UNIFORM_FLOATS, ffloats));
}

void updateBoolUniforms(GLint uniformId, UniformValues* values)
{
  GL_CHECK(glUniform3i(uniformId, values->animations, values->motion,
    values->palettes));
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

    VERB(verbose, printf("  Deleting current OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  Current OpenGL program deleted\n"));

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

    VERB(verbose, printf("  Deleting current OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  Current OpenGL program deleted\n"));

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

    VERB(verbose, printf("  Deleting current OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  Current OpenGL program deleted\n"));

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

    VERB(verbose, printf("  Deleting current OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  Current OpenGL program deleted\n"));

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

    VERB(verbose, printf("  Deleting current OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    VERB(verbose, printf("  Current OpenGL program deleted\n"));


    return false;
  }
  VERB(verbose, printf("  OpenGL program linked\n"));

  VERB(verbose, printf("  Checking current OpenGL program execution ...\n"));
  GL_CHECK(glValidateProgram(*program));
  VERB(verbose, printf("  Current OpenGL program execution checked\n"));

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
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    GL_CHECK(uniformIds[i] = glGetUniformLocation(*program, uniforms[i].name));
  }
}

void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    uniforms[i].update(uniformIds[i], values);
  }
}

void initVertices(GLuint* vertexbuffer, GLuint* vertexarray)
{
  GL_CHECK(glGenVertexArrays(1, vertexarray));
  GL_CHECK(glBindVertexArray(*vertexarray));

  static const GLfloat g_vertex_buffer_data[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    1.0f, 1.0f
  };

  GL_CHECK(glGenBuffers(1, vertexbuffer));
  GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, *vertexbuffer));
  GL_CHECK(glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data),
               g_vertex_buffer_data, GL_STATIC_DRAW));

  GL_CHECK(glEnableVertexAttribArray(0));
  GL_CHECK(glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0));
}

void drawScreen()
{
  GL_CHECK(glClearColor(0.0, 0.0, 0.0, 0.0));
  GL_CHECK(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT));

  GL_CHECK(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4));
}

void cleanup(png_structp* parser, png_infop* info, png_bytep** row_pointers,
  uint8_t** data, FILE** file, char const * const filename)
{
  if(*parser)
  {
    png_destroy_read_struct(parser, *info ? info : 0, 0);
  }

  if(*row_pointers)
  {
    free(*row_pointers);
  }

  if(*data)
  {
    free(*data);
  }

  if(*file)
  {
    fclose(*file);
  }
}

bool loadPng(GLuint* texture, char const* const filename)
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
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load PNG file\n");
    return false;
  }

  file = fopen(filename, "rb");
  if (!file)
  {
    fprintf(stderr, "Failed to open \"%s\"\n", filename);
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    return false;
  }

  parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
  if (!parser)
  {
    fprintf(stderr, "png_create_read_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }

  info = png_create_info_struct(parser);
  if (!info)
  {
    fprintf(stderr, "png_create_info_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }

  if (setjmp(png_jmpbuf(parser)))
  {
    fprintf(stderr, "png_jmpbuf() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }

  png_init_io(parser, file);
  png_read_info(parser, info);
  png_get_IHDR(parser, info, &w, &h, &bit_depth, &color_type, 0, 0, 0);

  if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
  {
    fprintf(stderr, "PNG images with dimensions that are not power of two or smaller \
than 8 failed to load in OpenGL\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }

  if (png_get_valid(parser, info, PNG_INFO_tRNS) ||
    (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) ||
    color_type == PNG_COLOR_TYPE_PALETTE)
  {
    png_set_expand(parser);
  }

  if (bit_depth == 16)
  {
    png_set_strip_16(parser);
  }

  if (color_type == PNG_COLOR_TYPE_GRAY ||
    color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
  {
    png_set_gray_to_rgb(parser);
  }
  png_read_update_info(parser, info);

  int rowbytes = png_get_rowbytes(parser, info);
  rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes

  data = malloc(rowbytes * h * sizeof(png_byte) + 15);
  if (!data)
  {
    fprintf(stderr, "data malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }

  row_pointers = malloc(h * sizeof(png_bytep));
  if (!row_pointers)
  {
    fprintf(stderr, "row_pointers malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    fprintf(stderr, "Failed to load \"%s\"\n", filename);
    return false;
  }

  // set the individual row_pointers to point at the correct offsets of data
  for(png_uint_32 i = 0; i < h; ++i)
  {
    row_pointers[h - 1 - i] = data + i * rowbytes;
  }

  png_read_image(parser, row_pointers);

  GL_CHECK(glGenTextures(1, texture));
  GL_CHECK(glBindTexture(GL_TEXTURE_2D, *texture));
  GLenum texture_format =
    (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;
  GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h,
    0, texture_format, GL_UNSIGNED_BYTE, data));

  GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
    GL_CLAMP_TO_BORDER));
  GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
    GL_CLAMP_TO_BORDER));
  GL_CHECK(glTexParameteri(
    GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST));
  GL_CHECK(glTexParameteri(
    GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST));

  cleanup(&parser, &info, &row_pointers, &data, &file, filename);
  return true;
}
