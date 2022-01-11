#include "util.h"

void writeLog(Log* log, FILE* stream, const char* stdoutstr,
  const char* str, ...)
{
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

    if (!log->file)
    {
      if (!log->buffer)
      {
        log->buffer =
          malloc(sizeof(char) * (expanded_len + stdoutstr_len));

        if (!log->buffer)
        {
          fprintf(stderr,
            "Failed to allocate memory in writeLog function to log buffer\n");
          break;
        }

        strcpy(log->buffer, stdoutstr);
      } else {
        log->buffer = realloc(log->buffer, sizeof(char) *
          (strlen(log->buffer) + expanded_len + stdoutstr_len));

        if (!log->buffer)
        {
          fprintf(stderr,
            "Failed to reallocate memory in writeLog function to log buffer\n");
          break;
        }

        strncat(log->buffer, stdoutstr, stdoutstr_len);
      }

      strncat(log->buffer, expanded_str, expanded_len);
    } else {
      fputs(stdoutstr, log->file);
      fputs(expanded_str, log->file);
    }

    if (log->verbose)
    {
      fputs(stdoutstr, stdout);
    }

    if (log->verbose || (stream == stderr))
    {
      fputs(expanded_str, stream);
    }

    free(expanded_str);
  } while (false);

  va_end(args);
}

void freeLog(Log* log)
{
  if (log->path)
  {
    writeLog(log, stdout, "", "Freeing log path ...\n");
    free(log->path);
    log->path = NULL;
    writeLog(log, stdout, "", "Log path freed\n");
  }

  if (log->buffer)
  {
    writeLog(log, stdout, "", "Freeing log buffer ...\nLog buffer freed\n");
    free(log->buffer);
    log->buffer = NULL;
  }

  if (log->file)
  {
    writeLog(log, stdout, "", "Closing log file ...\nLog file closed\n");
    fclose(log->file);
    log->file = NULL;
  }
}

bool initLog(Log* log)
{
  bool status = true;
  do
  {
    writeLog(log, stdout, "",
      "  Opening log file \"%s\" ...\n  Log file opened ...\n", log->path);
    if (log->roadmap.id != FOPEN_LOG_FAILED_RM)
    {
      log->file = fopen(log->path, "wb");
    }

    if (!log->file)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to open \"%s\"\n", log->path);

      status = false;
      break;
    }

    if (log->buffer)
    {
      fputs(log->buffer, log->file);
      free(log->buffer);
      log->buffer = NULL;
    }
  } while (false);

  return status;
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
