#include "util.h"

void freeLog(Log* log)
{
  if (log->path)
  {
    LOG(verbose, printf("Freeing log path ...\n"));
    free(log->path);
    log->path = NULL;
    LOG(verbose, printf("Log path freed\n"));
  }

  if (log->buffer)
  {
    LOG(verbose, printf("Freeing log buffer ...\n"));
    free(log->buffer);
    log->buffer = NULL;
    LOG(verbose, printf("Log buffer freed\n"));
  }

  if (log->file)
  {
    LOG(verbose, printf("Closing log file ...\nLog file closed\n"));
    fclose(log->file);
    log->file = NULL;
  }
}

bool initLog(Log* log)
{
  bool status = true;
  do
  {
    LOG(verbose, printf("  Opening log file \"%s\" ...\n", log->path));
    if (log->roadmap.id != FOPEN_LOG_FAILED_RM)
    {
      log->file = fopen(log->path, "wb");
    }

    if (!log->file)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to open \"%s\"\n",
        log->path);

      status = false;
      break;
    }
    LOG(verbose, printf("  Log file opened ...\n"));

    if (log->buffer)
    {
      fprintf(log->file, log->buffer);
      free(log->buffer);
      log->buffer = NULL;
    }
  } while (false);

  return status
}

void writeLog(Log* log, FILE* stream, char* stdoutstr, const char* str, ...)
{
  char* expanded_str = NULL

  va_list args;
  va_start(args, str);

  size_t expanded_len = vsnprintf(NULL, 0, str, args) + 1;

  do
  {
    expanded_str = malloc(sizeof(char) * expanded_len);
    if (!expanded_str)
    {
      fprintf(stderr, "Failed to allocate memory in writeLog function \
to expanded_str\n");
      break;
    }

    vsnprintf(expanded_str, expanded_len, str, args);

    if (!log->file)
    {
      if (!log->buffer)
      {
        log->buffer =
          malloc(sizeof(char) * (expanded_len + strlen(stdoutstr)));

        if (!log->buffer)
        {
          fprintf(stderr, "Failed to allocate memory in writeLog function to \
log buffer\n");
          break;
        }
      } else {
        log->buffer = realloc(log->buffer, sizeof(char) *
          (strlen(log->buffer) + expanded_len + strlen(stdoutstr)));

        if (!log->buffer)
        {
          fprintf(stderr, "Failed to reallocate memory in writeLog function \
to log buffer\n");
          break;
        }
      }

      strcat(log->buffer, stdoutstr);
      strcat(log->buffer, expanded_str);
    } else {
      fprintf(log->file, stdoutstr);
      fprintf(log->file, expanded_str);
    }

    if (log->verbose)
    {
      fprintf(stdout, stdoutstr);
    }

    if (log->verbose || (stream == stderr))
    {
      fprintf(stream, expanded_str);
    }

    free(expanded_str);
  } while (false);

  va_end(args);
}

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
