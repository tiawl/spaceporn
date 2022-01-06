#include "atlas.h"

void pcg4d(uvec4* vector)
{
  vector->x = vector->x * 1664525u + 1013904223u;
  vector->y = vector->y * 1664525u + 1013904223u;
  vector->z = vector->z * 1664525u + 1013904223u;
  vector->w = vector->w * 1664525u + 1013904223u;

  vector->x += vector->y * vector->w;
  vector->y += vector->z * vector->x;
  vector->z += vector->x * vector->y;
  vector->w += vector->y * vector->z;

  vector->x ^= vector->x >> 16u;
  vector->y ^= vector->y >> 16u;
  vector->z ^= vector->z >> 16u;
  vector->w ^= vector->w >> 16u;

  vector->x += vector->y * vector->w;
  vector->y += vector->z * vector->x;
  vector->z += vector->x * vector->y;
  vector->w += vector->y * vector->z;
}

bool generatePcgTexture(Atlas* atlas, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    uvec4 u;

    LOG(verbose, printf("    Allocating memory for texels ...\n"));
    if (roadmap->id != ATLASTEXELS_MALLOC_FAILED_RM)
    {
      atlas->texels =
        (GLubyte*) malloc(sizeof(GLubyte) * atlas->width * atlas->height * 4);
    }

    if (!atlas->texels)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "Texels malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Memory allocated successfully\n"));

    LOG(verbose, printf("    Computing PCG texture ... 0/%d\n",
      atlas->width * atlas->height));
    for (int y = 0; y < atlas->height; y++)
    {
      for (int x = 0; x < atlas->width * 4; x += 4)
      {
        u.x = x / 4;
        u.y = y;
        u.z = 0;
        u.w = 0;
        pcg4d(&u);
        atlas->texels[atlas->width * y + x] =
          (GLubyte) ceil((((double) u.x) / (double) UINT_MAX) * 256.);
        atlas->texels[atlas->width * y + x + 1] =
          (GLubyte) ceil((((double) u.y) / (double) UINT_MAX) * 256.);
        atlas->texels[atlas->width * y + x + 2] =
          (GLubyte) ceil((((double) u.z) / (double) UINT_MAX) * 256.);
        atlas->texels[atlas->width * y + x + 3] =
          (GLubyte) ceil((((double) u.w) / (double) UINT_MAX) * 256.);
        LOG(verbose, printf("    Computing PCG texture ... %d/%d\n",
          (x / 4) + 1 + (y * atlas->width), atlas->width * atlas->height));
      }
    }
    LOG(verbose, printf("    PCG texture computed successfully\n"));
  } while (false);

  return status;
}

bool generateAtlas(Atlas* atlas, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Generating PCG texture ...\n"));
    if (!generatePcgTexture(atlas, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to generate PCG texture\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  PCG texture generated successfully\n"));
  } while (false);

  return status;
}

void freeAtlas(Atlas* atlas, bool verbose)
{
  if (atlas->texels)
  {
    LOG(verbose, printf("Freeing texels ...\n"));
    free(atlas->texels);
    atlas->texels = NULL;
    LOG(verbose, printf("Texels freed\n"));
  }
}

bool loadAtlas(Atlas* atlas, Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    for (int y = 0; y < atlas->height; y++)
    {
      for (int x = 0; x < atlas->width * 4; x += 4)
      {
        printf("%d, %d -> %u, %u, %u, %u\n", x / 4, y,
          atlas->texels[atlas->width * y + x],
          atlas->texels[atlas->width * y + x + 1],
          atlas->texels[atlas->width * y + x + 2],
          atlas->texels[atlas->width * y + x + 3]);
      }
    }
    if (roadmap->id == BAD_ATLAS_DIMENSIONS_RM)
    {
      atlas->width = 15;
    }

    LOG(verbose, printf("  Testing textures atlas dimensions ...\n"));
    if ((atlas->width & (atlas->width - 1)) ||
      (atlas->height & (atlas->height - 1)) || (atlas->width < 8) ||
      (atlas->height < 8))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Textures with dimensions that \
are not power of two or smaller than 8 failed to load in OpenGL\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Valid textures atlas dimensions\n"));

    LOG(verbose, printf("  Generating OpenGL texture ...\n"));
    GL_CHECK(glGenTextures(1, &(atlas->texture)), status);
    LOG(verbose, printf("  OpenGL texture is %d\n", atlas->texture));

    LOG(verbose, printf("  Activating OpenGL texture ...\n"));
    GL_CHECK(glActiveTexture(GL_TEXTURE0 + atlas->texture_unit), status);
    LOG(verbose, printf("  OpenGL texture activated\n"));

    LOG(verbose, printf("  Binding OpenGL textures array ...\n"));
    GL_CHECK(glBindTexture(GL_TEXTURE_2D_ARRAY, atlas->texture), status);
    LOG(verbose, printf("  OpenGL textures array binded\n"));

    LOG(verbose, printf("  Setting texture unit to use ...\n"));
    GL_CHECK(glUniform1i(glGetUniformLocation(shaders->program, "atlas"),
      atlas->texture_unit), status);
    LOG(verbose, printf("  Texture unit ready to use\n"));

    LOG(verbose, printf("  Specifying 2D textures array ...\n"));
    GL_CHECK(glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, atlas->width,
      atlas->height, atlas->depth, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0), status);
    LOG(verbose, printf("  2D textures array specified\n"));

    LOG(verbose, printf("  Specifying fallback for 2D textures array ...\n"));
    glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, 0, atlas->width,
      atlas->height, atlas->depth, GL_RGBA, GL_UNSIGNED_BYTE, atlas->texels);
    LOG(verbose, printf("  Fallback specified\n"));

    LOG(verbose, printf("  Enabling OpenGL textures repetition ...\n"));
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S,
      GL_REPEAT), status);
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T,
      GL_REPEAT), status);
    LOG(verbose, printf("  OpenGL textures repetition disabled\n"));

    LOG(verbose, printf("  Specifying textures element value to the nearest \
texture coordinates ...\n"));
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_NEAREST), status);
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER, GL_NEAREST), status);
    LOG(verbose, printf("  Textures element value specified ...\n"));
  } while (false);

  return status;
}
