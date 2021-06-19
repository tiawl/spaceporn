#include "util.h"

static const char* loglevels[] =
{
  "DEBUG", "INFO", "WARNING", "ERROR"
};

void writeLog(Log* log, FILE* stream, enum LogLevel loglevel,
  const char* stdoutstr, const char* str, ...)
{
  char* log_message = NULL;
  char* expanded_str = NULL;
  char* loglevel_str = NULL;

  va_list args;
  va_start(args, str);

  size_t loglevel_len = 3;
  size_t expanded_len = vsnprintf(NULL, 0, str, args) + 1;

  switch (loglevel)
  {
    case INFO:
      loglevel_len += 4;
      break;
    case DEBUG:
    case ERROR:
      loglevel_len += 5;
      break;
    case WARNING:
      loglevel_len += 7;
      break;
    default:
      break;
  }

  va_end(args);
  va_start(args, str);

  do
  {
    loglevel_str = malloc(sizeof(char) * loglevel_len);
    if (!loglevel_str)
    {
      fprintf(stderr,
        "Failed to allocate memory in writeLog function to loglevel_str\n");
      break;
    }

    snprintf(loglevel_str, loglevel_len, "[%s]", loglevels[loglevel]);

    expanded_str = malloc(sizeof(char) * expanded_len);
    if (!expanded_str)
    {
      fprintf(stderr,
        "Failed to allocate memory in writeLog function to expanded_str\n");
      break;
    }

    vsnprintf(expanded_str, expanded_len, str, args);

    if (loglevel >= LOGLEVEL)
    {
      log_message = malloc(sizeof(char)
        * (expanded_len + loglevel_len + MSG_LEN));
      if (!log_message)
      {
        fprintf(stderr,
          "Failed to allocate memory in writeLog function to log_message\n");
        break;
      }

      strcpy(log_message, "MESSAGE=");
      strncat(log_message, loglevel_str, loglevel_len);
      strncat(log_message, expanded_str, expanded_len);

      sd_journal_send(log_message, NULL);
    }

    if (log->verbose || (stream == stderr))
    {
      fputs(loglevel_str, stream);
    }

    if (log->verbose)
    {
      fputs(stdoutstr, stdout);
    }

    if (log->verbose || (stream == stderr))
    {
      fputs(expanded_str, stream);
    }
  } while (false);

  if (loglevel_str)
  {
    free(loglevel_str);
  }

  if (expanded_str)
  {
    free(expanded_str);
  }

  if (log_message)
  {
    free(log_message);
  }

  va_end(args);
}

bool checkOpenGLError(const char* stmt, const char* fname, int line, Log* log)
{
  bool status = true;
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    writeLog(log, (log->verbose ? stdout : stderr), ERROR, "",
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
