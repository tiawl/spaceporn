#include "util.h"

void writeLog(Log* log, FILE* stream, const char* stdoutstr,
  const char* str, ...)
{
  char* log_message = NULL;
  char* expanded_str = NULL;

  va_list args;
  va_start(args, str);

  size_t expanded_len = vsnprintf(NULL, 0, str, args) + 1;
  size_t stdoutstr_len = strlen(stdoutstr);

  va_end(args);
  va_start(args, str);

  do
  {
    expanded_str = malloc(sizeof(char) * expanded_len);
    if (!expanded_str)
    {
      fprintf(stderr,
        "Failed to allocate memory in writeLog function to expanded_str\n");
      break;
    }

    vsnprintf(expanded_str, expanded_len, str, args);

    log_message =
      malloc(sizeof(char) * (expanded_len + stdoutstr_len + MSG_LEN));
    if (!log_message)
    {
      fprintf(stderr,
        "Failed to allocate memory in writeLog function to log_message\n");
      break;
    }

    strcpy(log_message, "MESSAGE=");
    strncat(log_message, stdoutstr, stdoutstr_len);
    strncat(log_message, expanded_str, expanded_len);

    sd_journal_send(log_message, NULL);

    if (log->verbose)
    {
      fputs(stdoutstr, stdout);
    }

    if (log->verbose || (stream == stderr))
    {
      fputs(expanded_str, stream);
    }
  } while (false);

  if (expanded_str)
  {
    free(expanded_str);
  }

  va_end(args);
}

bool checkOpenGLError(const char* stmt, const char* fname, int line, Log* log)
{
  bool status = true;
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    writeLog(log, (log->verbose ? stdout : stderr), "",
      "OpenGL error %08x, at %s:%i - for %s\n", error, fname, line, stmt);
    status = false;
  }
  return status;
}

double timediff(struct timeval* start, struct timeval* end)
{
  return (end->tv_sec + end->tv_usec / 1000000.0)
    - (start->tv_sec + start->tv_usec / 1000000.0);
}

int nextpow2(int n)
{
  unsigned count = 0;

  if (n && !(n & (n - 1)))
  {
    return n;
  }

  while (n != 0)
  {
    n >>= 1;
    count += 1;
  }

  return 1 << count;
}
