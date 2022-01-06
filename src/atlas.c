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
