#include "config.h"

void CheckOpenGLError(const char* stmt, const char* fname, int line)
{
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    printf("OpenGL error %08x, at %s:%i - for %s\n", error, fname, line, stmt);
    abort();
  }
}

void incr_time(GLint uniformId, UniformValues* values)
{
  values->time = ((double)(clock() - values->clock)) / CLOCKS_PER_SEC;
  GL_CHECK(glUniform1f(uniformId, values->time));
}

void get_resolution(GLint uniformId, UniformValues* values)
{
  GL_CHECK(glUniform2f(uniformId, values->width, values->height));
}

void get_texture(GLint uniformId, UniformValues* values)
{
  GL_CHECK(glActiveTexture(GL_TEXTURE0));
  GL_CHECK(glBindTexture(GL_TEXTURE_2D, values->tex.id));
  GL_CHECK(glUniform1i(uniformId, 0));
}
