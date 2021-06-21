#include "xshader.h"

void CheckOpenGLError(const char* stmt, const char* fname, int line)
{
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    printf("OpenGL error %08x, at %s:%i - for %s\n", error, fname, line, stmt);
    abort();
  }
}

/************************************************************************
                          Uniforms functions
*************************************************************************/

void updateFloatUniforms(GLint uniformId, UniformValues* values)
{
  values->time = ((double)(clock() - values->clock)) / CLOCKS_PER_SEC;
  GLfloat ffloats[6] =
  {
    values->width, values->height, values->xseed, values->yseed, values->time,
    values->pixels
  };
  GL_CHECK(glUniform1fv(uniformId, 6, ffloats));
}

void updateBoolUniforms(GLint uniformId, UniformValues* values)
{
  GL_CHECK(glUniform3i(uniformId, values->animations, values->motion,
    values->palettes));
}

/**************************************************************************/

bool initPaths(char** fshaderpath, char** vshaderpath, char** texturepath)
{
  const size_t len1 = strlen(HOME_DIR);
  const size_t len2 = strlen(getenv("USERNAME"));
  const size_t len3 = strlen(BIN_DIR);
  const size_t len4 = strlen(SHADERS_DIR);
  const size_t len5 = strlen(TEXTURES_DIR);
  const size_t len6 = strlen(FSHADER_FILE);
  const size_t len7 = strlen(VSHADER_FILE);
  const size_t len8 = strlen(TEXTURE_FILE);
  *fshaderpath = malloc(len1 + len2 + len3 + len4 + len6 + 1);

  if (!*fshaderpath)
  {
    printf("fshaderpath malloc() failed\n");
    return false;
  }

  *vshaderpath = malloc(len1 + len2 + len3 + len4 + len7 + 1);

  if (!*vshaderpath)
  {
    printf("vshaderpath malloc() failed\n");
    free(fshaderpath);
    return false;
  }

  *texturepath = malloc(len1 + len2 + len3 + len5 + len8 + 1);

  if (!*texturepath)
  {
    printf("texturepath malloc() failed\n");
    free(fshaderpath);
    free(vshaderpath);
    return false;
  }

  memcpy(*fshaderpath, HOME_DIR, len1);
  memcpy(*fshaderpath + len1, getenv("USERNAME"), len2);
  memcpy(*fshaderpath + len1 + len2, BIN_DIR, len3);
  memcpy(*fshaderpath + len1 + len2 + len3, SHADERS_DIR, len4);
  memcpy(*fshaderpath + len1 + len2 + len3 + len4, FSHADER_FILE, len6 + 1);

  memcpy(*vshaderpath, HOME_DIR, len1);
  memcpy(*vshaderpath + len1, getenv("USERNAME"), len2);
  memcpy(*vshaderpath + len1 + len2, BIN_DIR, len3);
  memcpy(*vshaderpath + len1 + len2 + len3, SHADERS_DIR, len4);
  memcpy(*vshaderpath + len1 + len2 + len3 + len4, VSHADER_FILE, len7 + 1);

  memcpy(*texturepath, HOME_DIR, len1);
  memcpy(*texturepath + len1, getenv("USERNAME"), len2);
  memcpy(*texturepath + len1 + len2, BIN_DIR, len3);
  memcpy(*texturepath + len1 + len2 + len3, TEXTURES_DIR, len5);
  memcpy(*texturepath + len1 + len2 + len3 + len5, TEXTURE_FILE, len8 + 1);

  return true;
}

bool readFile(char** filepath, char** buffer)
{
  long length;
  FILE* f = fopen(*filepath, "r");

  if (f)
  {
    fseek(f, 0, SEEK_END);
    length = ftell(f);
    fseek(f, 0, SEEK_SET);
    *buffer = malloc(length + 1);
    if (*buffer)
    {
      fread(*buffer, 1, length, f);
    } else {
      printf("buffer malloc() failed\n");
      return false;
    }
    fclose(f);
    (*buffer)[length] = '\0'; // fread does not 0 terminate strings
  } else {
    printf("Failed to read inside %s: %s\n", *filepath, strerror(errno));
    return false;
  }

  return true;
}

GLuint loadShader(const char* shaderSource, GLenum shaderType)
{
  GLuint shader;
  GL_CHECK(shader = glCreateShader(shaderType));

  GL_CHECK(glShaderSource(shader, 1, (const GLchar**)&shaderSource, NULL));

  GL_CHECK(glCompileShader(shader));

  GLint shaderCompiled = GL_FALSE;
  GL_CHECK(glGetShaderiv(shader, GL_COMPILE_STATUS, &shaderCompiled));
  if (shaderCompiled != GL_TRUE)
  {
    GLint maxLength = 0;
    GL_CHECK(glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &maxLength));

    char message[maxLength];
    GL_CHECK(glGetShaderInfoLog(shader, maxLength, &maxLength, message));

    printf("%s\n", &(message[0]));

    GL_CHECK(glDeleteShader(shader));
    shader = 0;
  }

  return shader;
}

bool loadProgram(GLuint* program, GLuint* vertex_shader,
  char** vshaderpath, GLuint* fragment_shader, char** fshaderpath)
{
  GL_CHECK(*program = glCreateProgram());

  char* vertex_file = 0;
  if (!readFile(vshaderpath, &vertex_file))
  {
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    printf("Failed to read in vertex shader file\n");
    return false;
  }

  char* fragment_file = 0;
  if (!readFile(fshaderpath, &fragment_file))
  {
    free(vertex_file);
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    printf("Failed to read in fragment shader file\n");
    return false;
  }

  *vertex_shader = loadShader(vertex_file, GL_VERTEX_SHADER);
  if (*vertex_shader == 0)
  {
    free(vertex_file);
    free(fragment_file);
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    return false;
  }

  *fragment_shader = loadShader(fragment_file, GL_FRAGMENT_SHADER);
  if (*fragment_shader == 0)
  {
    free(vertex_file);
    free(fragment_file);
    GL_CHECK(glDeleteShader(*vertex_shader));
    *vertex_shader = 0;
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;
    return false;
  }

  GL_CHECK(glAttachShader(*program, *vertex_shader));
  GL_CHECK(glAttachShader(*program, *fragment_shader));

  GL_CHECK(glLinkProgram(*program));

  GLint programSuccess = GL_TRUE;
  GL_CHECK(glGetProgramiv(*program, GL_LINK_STATUS, &programSuccess));
  if (programSuccess != GL_TRUE)
  {
    GLint maxLength = 0;
    GL_CHECK(glGetProgramiv(*program, GL_INFO_LOG_LENGTH, &maxLength));

    char message[maxLength];
    GL_CHECK(glGetShaderInfoLog(*program, maxLength, &maxLength, message));

    printf("%s\n", &(message[0]));
    printf("\n\nUnable to link program %d\n", *program);

    free(vertex_file);
    free(fragment_file);
    GL_CHECK(glDeleteShader(*vertex_shader));
    *vertex_shader = 0;
    GL_CHECK(glDeleteShader(*fragment_shader));
    *fragment_shader = 0;
    GL_CHECK(glDeleteProgram(*program));
    *program = 0;

    return false;
  }

  GL_CHECK(glValidateProgram(*program));

  GL_CHECK(glDetachShader(*program, *vertex_shader));
  GL_CHECK(glDetachShader(*program, *fragment_shader));

  GL_CHECK(glDeleteShader(*vertex_shader));
  GL_CHECK(glDeleteShader(*fragment_shader));

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
    printf("One or more loadPng() pointers arguments are null\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load PNG file\n");
    return false;
  }

  file = fopen(filename, "rb");
  if (!file)
  {
    printf("Failed to open %s\n", filename);
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    return false;
  }

  parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
  if (!parser)
  {
    printf("png_create_read_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load %s\n", filename);
    return false;
  }

  info = png_create_info_struct(parser);
  if (!info)
  {
    printf("png_create_info_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load %s\n", filename);
    return false;
  }

  if (setjmp(png_jmpbuf(parser)))
  {
    printf("png_jmpbuf() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load %s\n", filename);
    return false;
  }

  png_init_io(parser, file);
  png_read_info(parser, info);
  png_get_IHDR(parser, info, &w, &h, &bit_depth, &color_type, 0, 0, 0);

  if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
  {
    printf("PNG images with dimensions that are not power of two or smaller \
than 8 failed to load in OpenGL\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load %s\n", filename);
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
    printf("data malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load %s\n", filename);
    return false;
  }

  row_pointers = malloc(h * sizeof(png_bytep));
  if (!row_pointers)
  {
    printf("row_pointers malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename);
    printf("Failed to load %s\n", filename);
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
