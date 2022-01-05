#include "util.h"

bool checkOpenGLError(const char* stmt, const char* fname, int line)
{
  bool status = true;
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    printf("OpenGL error %08x, at %s:%i - for %s\n", error, fname, line, stmt);
    status = false;
  }
  return status;
}

double timediff(struct timeval* start, struct timeval* end)
{
  return (end->tv_sec + end->tv_usec / 1000000.0)
    - (start->tv_sec + start->tv_usec / 1000000.0);
}
