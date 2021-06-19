#include "uniform.h"

static const char* modes[] =
{
  "NO_MODE", "ANIM_MOTION_MODE", "ANIM_MODE", "MOTION_MODE", "BGGEN_MODE",
  "SLIDE_MODE", "LOCKED"
};

static const char* colors[] =
{
  "BLACK_WHITE", "STATIC_MONO", "DYNAMIC_MONO", "COLORFUL"
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

    GLfloat float_flags[UNIFORM_FLOATS] =
    {
      values->width, values->height, values->seed, values->time / 50.,
      values->pixels, values->zoom, values->mode, values->color
    };

    writeLog(log, stdout, INFO, "",
      "    New float_flags values: [%d, %d, %f, %f, %d, %f, %s, %s]\n",
      values->width, values->height, float_flags[2], float_flags[3],
      values->pixels, values->zoom, modes[values->mode],
      colors[values->color]);

    writeLog(log, stdout, DEBUG, "",
      "    Specifying value of float_flags in current program ...\n");
    GL_CHECK(glUniform1fv(uniformId, UNIFORM_FLOATS, float_flags), status, log);
    writeLog(log, stdout, DEBUG, "",
      "    Value of float_flags specified in current program\n");
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
