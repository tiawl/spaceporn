#include "uniform.h"

static const char* modes[] =
{
  "NO_MODE", "ANIM_MOTION_MODE", "ANIM_MODE", "MOTION_MODE", "BGGEN_MODE",
  "SLIDE_MODE"
};

bool updateFloatUniforms(GLint uniformId, UniformValues* values, Log* log)
{
  bool status = true;

  do
  {
    if ((values->mode == SLIDE_MODE) || (values-> seed < 0.))
    {
      writeLog(log, stdout, INFO, "",
        "    Generating random number to seed GPU hash function ...\n");
      values->seed = rand();
      writeLog(log, stdout, INFO, "", "    Seed is %f\n", values->seed);

#if DEV
      printf("Seed is %f\n", values->seed);
#endif
    }

    struct timeval now;
    gettimeofday(&now, NULL);
    values->time = timediff(&(values->start), &now);

    GLfloat fflags[UNIFORM_FLOATS] =
    {
      values->width, values->height, values->seed, values->time / 50.,
      values->pixels, values->zoom, values->mode
    };

    writeLog(log, stdout, INFO, "",
      "    New fflags values: [%d, %d, %f, %f, %d, %f, %s]\n",
      values->width, values->height, fflags[2], fflags[3], values->pixels,
      values->zoom, modes[values->mode]);

    writeLog(log, stdout, DEBUG, "",
      "    Specifying value of fflags in current program ...\n");
    GL_CHECK(glUniform1fv(uniformId, UNIFORM_FLOATS, fflags), status, log);
    writeLog(log, stdout, DEBUG, "",
      "    Value of fflags specified in current program\n");
  } while (false);

  return status;
}

bool updateBoolUniforms(GLint uniformId, UniformValues* values, Log* log)
{
  bool status = true;

  do
  {
    GLint bflags[UNIFORM_BOOLEANS] =
    {
      values->palettes
    };

    writeLog(log, stdout, INFO, "", "    New bflags values: [%s]\n",
      values->palettes ? "true" : "false");

    writeLog(log, stdout, DEBUG, "",
      "    Specifying value of bflags in current program ...\n");
    GL_CHECK(glUniform1iv(uniformId, UNIFORM_BOOLEANS, bflags), status, log);
    writeLog(log, stdout, DEBUG, "",
      "    Value of bflags specified in current program\n");
  } while (false);

  return status;
}

bool getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, Log* log)
{
  bool status = true;

  do
  {
    for (int i = 0; i < UNIFORM_COUNT; i++)
    {
      writeLog(log, stdout, DEBUG, "", "  Querying uniform location of %s\n",
        uniforms[i].name);
      GL_CHECK(uniformIds[i] =
        glGetUniformLocation(*program, uniforms[i].name), status, log);
      writeLog(log, stdout, DEBUG, "", "  %s uniform located\n",
        uniforms[i].name);
    }
  } while (false);

  return status;
}

void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, Log* log)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    writeLog(log, stdout, DEBUG, "", "  Updating %s...\n", uniforms[i].name);
    uniforms[i].update(uniformIds[i], values, log);
    writeLog(log, stdout, DEBUG, "", "  %s updated\n", uniforms[i].name);
  }
}
