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
