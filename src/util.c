#include "util.h"

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
