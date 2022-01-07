#include "uniform.h"

bool updateFloatUniforms(GLint uniformId, UniformValues* values, bool verbose)
{
  bool status = true;

  do
  {
    if ((values->slide > 0) || (!values->precomputed && (values-> seed < 0.)))
    {
      LOG(verbose, printf("    Generating random number to seed GPU hash() \
...\n"));
      values->seed = rand();
      LOG(verbose, printf("    Seed is %f\n", values->seed));

#if DEBUG
      printf("Seed is %f\n", values->seed);
#endif
    }

    struct timeval now;
    gettimeofday(&now, NULL);
    values->time = timediff(&(values->start), &now);

    GLfloat fflags[UNIFORM_FLOATS] =
    {
      values->width, values->height, values->seed, values->time, values->pixels,
      values->zoom
    };

    LOG(verbose, printf("    New fflags values: [%d, %d, %f, %f, %d, %f]\n",
      values->width, values->height, fflags[2], fflags[3], values->pixels,
      values->zoom));

    LOG(verbose, printf("    Specifying value of fflags in current program \
...\n"));
    GL_CHECK(glUniform1fv(uniformId, UNIFORM_FLOATS, fflags), status);
    LOG(verbose, printf("    Value of fflags specified in current program\n"));
  } while (false);

  return status;
}

bool updateBoolUniforms(GLint uniformId, UniformValues* values, bool verbose)
{
  bool status = true;

  do
  {
    GLint bflags[UNIFORM_BOOLEANS] =
    {
      values->animations, values->motion, values->palettes, values->precomputed
    };

    LOG(verbose, printf("    New bflags values: [%s, %s, %s, %s]\n",
      values->animations ? "true" : "false", values->motion ? "true" : "false",
      values->palettes ? "true" : "false",
      values->precomputed ? "true" : "false" ));

    LOG(verbose, printf("    Specifying value of bflags in current program \
...\n"));
    GL_CHECK(glUniform1iv(uniformId, UNIFORM_BOOLEANS, bflags), status);
    LOG(verbose, printf("    Value of bflags specified in current program\n"));
  } while (false);

  return status;
}

bool getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, bool verbose)
{
  bool status = true;

  do
  {
    for (int i = 0; i < UNIFORM_COUNT; i++)
    {
      LOG(verbose, printf("  Querying uniform location of %s\n",
        uniforms[i].name));
      GL_CHECK(uniformIds[i] =
        glGetUniformLocation(*program, uniforms[i].name), status);
      LOG(verbose, printf("  %s uniform located\n", uniforms[i].name));
    }
  } while (false);

  return status;
}

void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, bool verbose)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    LOG(verbose, printf("  Updating %s...\n", uniforms[i].name));
    uniforms[i].update(uniformIds[i], values, verbose);
    LOG(verbose, printf("  %s updated\n", uniforms[i].name));
  }
}
