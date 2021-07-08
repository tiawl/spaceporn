#include "uniform.h"

void updateFloatUniforms(GLint uniformId, UniformValues* values, bool verbose)
{
  values->time = ((double)(clock() - values->clock)) / CLOCKS_PER_SEC;
  GLfloat fflags[UNIFORM_FLOATS] =
  {
    values->width, values->height, values->xseed, values->yseed,
    values->time, values->pixels
  };

  VERB(verbose, printf("    New fflags values: [%d, %d, %f, %f, %f, %d]\n",
    values->width, values->height, fflags[2], fflags[3], fflags[4],
    values->pixels));

  VERB(verbose, printf("    Specifying value of fflags in current program \
...\n"));
  GL_CHECK(glUniform1fv(uniformId, UNIFORM_FLOATS, fflags));
  VERB(verbose, printf("    Value of fflags specified in current program\n"));
}

void updateBoolUniforms(GLint uniformId, UniformValues* values, bool verbose)
{
  VERB(verbose, printf("    New bflags values: [%s, %s, %s]\n",
    values->animations ? "true" : "false", values->motion ? "true" : "false",
    values->palettes ? "true" : "false"));

  VERB(verbose, printf("    Specifying value of bflags in current program \
...\n"));
  GL_CHECK(glUniform3i(uniformId, values->animations, values->motion,
    values->palettes));
  VERB(verbose, printf("    Value of bflags specified in current program\n"));
}

void getUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], GLuint* program, bool verbose)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    VERB(verbose, printf("  Querying uniform location of %s\n",
      uniforms[i].name));
    GL_CHECK(uniformIds[i] =
      glGetUniformLocation(*program, uniforms[i].name));
    VERB(verbose, printf("  %s uniform located\n", uniforms[i].name));
  }
}

void updateUniforms(const Uniform uniforms[UNIFORM_COUNT],
  GLuint uniformIds[UNIFORM_COUNT], UniformValues* values, bool verbose)
{
  for (int i = 0; i < UNIFORM_COUNT; i++)
  {
    VERB(verbose, printf("  Updating %s ... \n", uniforms[i].name));
    uniforms[i].update(uniformIds[i], values, verbose);
    VERB(verbose, printf("  %s updated\n", uniforms[i].name));
  }
}
