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
          malloc(sizeof(char) * (DATE_LENGTH + expanded_len + stdoutstr_len));

        if (!log->buffer)
        {
          fprintf(stderr,
            "Failed to allocate memory in writeLog function to log buffer\n");
          break;
        }

        strcpy(log->buffer, log->date);
      } else {
        log->buffer = realloc(log->buffer, sizeof(char) *
          (strlen(log->buffer) + DATE_LENGTH + expanded_len + stdoutstr_len));

        if (!log->buffer)
        {
          fprintf(stderr,
            "Failed to reallocate memory in writeLog function to log buffer\n");
          break;
        }

        strncat(log->buffer, log->date, DATE_LENGTH);
      }

      strncat(log->buffer, stdoutstr, stdoutstr_len);
      strncat(log->buffer, expanded_str, expanded_len);
    } else {
      fputs(log->date, log->file);
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
  } while (false);

  if (expanded_str)
  {
    free(expanded_str);
  }

  va_end(args);
}

void freeLog(Log* log)
{
  if (log->path)
  {
    writeLog(log, stdout, "", "Freeing log path ...\n");
    writeLog(log, stdout, "", "Log path freed\n");
  }

  if (log->buffer)
  {
    writeLog(log, stdout, "", "Freeing log buffer ...\n");
    writeLog(log, stdout, "", "Log buffer freed\n");
  }

  if (log->file)
  {
    writeLog(log, stdout, "", "Closing log file ...\n");
    writeLog(log, stdout, "", "Log file closed\n");
  }

  if (log->path)
  {
    free(log->path);
    log->path = NULL;
  }

  if (log->buffer)
  {
    free(log->buffer);
    log->buffer = NULL;
  }

  if (log->file)
  {
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
      "  Opening log file \"%s\" ...\n", log->path);
    if (log->roadmap.id != FOPEN_LOG_FAILED_RM)
    {
      log->file = fopen(log->path, "ab");
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
    writeLog(log, stdout, "", "  Log file opened ...\n");
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
