#include "texture.h"

bool loadPng(PNG* png, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    png_uint_32 w, h;
    int bit_depth;
    int color_type;

    if (!png->path || (roadmap->id == NO_PNG_FILENAME_RM))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "PNG filename is null\n");

      status = false;
      break;
    }

    LOG(verbose, printf("  Opening PNG file \"%s\" ...\n", png->path));
    if (roadmap->id != FOPEN_PNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "rb");
    }

    if (!png->file)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to open \"%s\"\n", png->path);

      status = false;
      break;
    }
    LOG(verbose, printf("  PNG file opened\n"));

    LOG(verbose, printf("  Creating structure for reading PNG file ...\n"));
    if (roadmap->id != PNGCREATEREADSTRUCT_FAILED_RM)
    {
      png->ptr =
        png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    }

    if (!png->ptr)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "png_create_read_struct() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Structure for reading PNG file created\n"));

    LOG(verbose, printf("  Creating PNG info structure ...\n"));
    if (roadmap->id != PNGCREATEREADINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "png_create_info_struct() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  PNG info structure created\n"));

    LOG(verbose, printf("  Searching libPNG error ...\n"));
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (roadmap->id == PNG_READJMPBUF_FAILED_RM))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "Routine problem: libPNG encountered an error\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  No error found\n"));

    LOG(verbose, printf("  Initializing PNG input/output ...\n"));
    png_init_io(png->ptr, png->file);
    LOG(verbose, printf("  PNG input/output initialized\n"));

    LOG(verbose, printf("  Reading PNG info ...\n"));
    png_read_info(png->ptr, png->info);
    LOG(verbose, printf("  PNG info read\n"));

    LOG(verbose, printf("  Querying PNG_IHDR chunk information from PNG info \
structure ...\n"));
    png_get_IHDR(
      png->ptr, png->info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
    LOG(verbose, printf("  PNG_IHDR chunk information found\n"));

    if (roadmap->id == BAD_PNG_DIMENSIONS_RM)
    {
      w = 15;
    }

    LOG(verbose, printf("  Testing PNG images dimensions ...\n"));
    if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "PNG images with dimensions that \
are not power of two or smaller than 8 failed to load in OpenGL\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Valid PNG images dimensions\n"));

    LOG(verbose, printf("  Updating PNG info structure ...\n"));
    png_read_update_info(png->ptr, png->info);
    LOG(verbose, printf("  PNG info structure updated\n"));

    LOG(verbose, printf("  Querying number of bytes for a row ...\n"));
    int rowbytes = png_get_rowbytes(png->ptr, png->info);
    rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes
    LOG(verbose, printf("  Number of bytes for a row is %d\n", rowbytes));

    LOG(verbose, printf("  Allocating memory for data ...\n"));
    if (roadmap->id != PNG_DATA_MALLOC_FAILED_RM)
    {
      png->data = malloc(rowbytes * h * sizeof(png_byte) + 15);
    }

    if (!png->data)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "data malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Memory allocated successfully\n"));

    LOG(verbose, printf("  Allocating memory for read_row_pointers ...\n"));
    if (roadmap->id != PNG_READROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->read_row_pointers = malloc(h * sizeof(png_bytep));
    }

    if (!png->read_row_pointers)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "read_row_pointers malloc() \
failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Memory allocated successfully\n"));

    for(png_uint_32 i = 0; i < h; ++i)
    {
      LOG(verbose, printf("  Setting individual read_row_pointers to point \
at the correct offsets of data ... %d/%d\n", i, h));
      png->read_row_pointers[h - 1 - i] = png->data + i * rowbytes;
    }
    LOG(verbose, printf("  Setting individual read_row_pointers to point at \
the correct offsets of data ... %d/%d\n", h, h));
    LOG(verbose, printf("  Individual read_row_pointers set\n"));

    LOG(verbose, printf("  Reading PNG image into memory ...\n"));
    png_read_image(png->ptr, png->read_row_pointers);
    LOG(verbose, printf("  PNG image read into memory\n"));

    LOG(verbose, printf("  Finishing PNG reading ...\n"));
    png_read_end(png->ptr, NULL);
    LOG(verbose, printf("  PNG reading finished\n"));

    LOG(verbose, printf("  Generating OpenGL texture ...\n"));
    GL_CHECK(glGenTextures(1, &(png->texture)), status);
    LOG(verbose, printf("  OpenGL texture is %d\n", png->texture));

    LOG(verbose, printf("  Binding OpenGL texture ...\n"));
    GL_CHECK(glBindTexture(GL_TEXTURE_2D, png->texture), status);
    LOG(verbose, printf("  OpenGL texture binded\n"));

    GLenum texture_format =
      (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;

    LOG(verbose, printf("  Specifying 2D OpenGL texture ...\n"));
    GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h,
      0, texture_format, GL_UNSIGNED_BYTE, png->data), status);
    LOG(verbose, printf("  2D OpenGL texture specified\n"));

    LOG(verbose, printf("  Disabling OpenGL Texture repetition ...\n"));
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
      GL_CLAMP_TO_BORDER), status);
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
      GL_CLAMP_TO_BORDER), status);
    LOG(verbose, printf("  OpenGL texture repetition disabled\n"));

    LOG(verbose, printf("  Specifying texture element value to the nearest \
texture coordinates ...\n"));
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST), status);
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST), status);
    LOG(verbose, printf("  Texture element value specified ...\n"));
  } while (false);

  return status;
}

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

bool generatePcgTexture(PNG* png, UniformValues* values, int* width,
  int* height, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    uvec4 u;
    LOG(verbose, printf("    Computing PCG texture dimensions ...\n"));
    *width = 5;
    *height = 3;

//     if (values->width >= values->height)
//     {
//       *width = values->pixels * 5 *
//         ((int) round(((double) values->width) /
//           ((double) values->height)));
//       *height = values->pixels * 5;
//     } else {
//       *width = values->pixels * 5;
//       *height = values->pixels * 5 *
//         ((int) round(((double) values->height) /
//           ((double) values->width)));
//     }
    LOG(verbose, printf("    PCG texture dimensions are: %dx%d\n", *width,
      *height));

    LOG(verbose, printf("    Allocating memory for write_row_pointers ...\n"));
    if (roadmap->id != PNG_WRITEROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->write_row_pointers =
        (png_byte**) malloc(sizeof(png_byte*) * (*height));
    }

    if (!png->write_row_pointers)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "write_row_pointers malloc() \
failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Memory allocated successfully\n"));

    LOG(verbose, printf("    Allocating memory for each write_row_pointer \
...\n"));
    for (int i = 0; i < *height; i++)
    {
      LOG(verbose, printf("      Allocating memory for \
write_row_pointers[%d] ...\n", i));
      if (roadmap->id != PNG_WRITEROWPOINTER_MALLOC_FAILED_RM)
      {
        png->write_row_pointers[i] = (png_byte*) malloc(4 * (*width));
      }

      if (!png->write_row_pointers[i])
      {
        LOG(verbose, printf("      "));
        fprintf((verbose ? stdout : stderr), "write_row_pointers[%d] \
malloc() failed\n", i);

        status = false;
        break;
      }
      LOG(verbose, printf("      Memory allocated successfully\n"));
    }
    LOG(verbose, printf("    Memory allocated successfully\n"));

    if (!status)
    {
      break;
    }

    LOG(verbose, printf("    Computing PCG texture ... 0/%d\n",
      (*width) * (*height)));
    for (int y = 0; y < *height; y++)
    {
      for (int x = 0; x < (*width) * 4; x += 4)
      {
        u.x = x / 4;
        u.y = y;
        u.z = 0;
        u.w = 0;
        pcg4d(&u);
        png->write_row_pointers[(*height) - 1 - y][x] =
          (png_byte) round((((double) u.x) / (double) UINT_MAX) * 255.);
        png->write_row_pointers[(*height) - 1 - y][x + 1] =
          (png_byte) round((((double) u.y) / (double) UINT_MAX) * 255.);
        png->write_row_pointers[(*height) - 1 - y][x + 2] =
          (png_byte) round((((double) u.z) / (double) UINT_MAX) * 255.);
        png->write_row_pointers[(*height) - 1 - y][x + 3] =
          (png_byte) round((((double) u.w) / (double) UINT_MAX) * 255.);
        LOG(verbose, printf("    Computing PCG texture ... %d/%d\n",
          (x / 4) + 1 + (y * (*width)),(*width) * (*height)));
      }
    }
    LOG(verbose, printf("    PCG texture computed successfully\n"));
  } while (false);

  return status;
}

bool writePng(PNG* png, UniformValues* values, int* width, int* height,
  bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("    Opening PNG file \"%s\" ...\n", png->path));
    if (roadmap->id != FOPEN_NEW_PNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "wb");
    }

    if (!png->file)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to open \"%s\"\n",
        png->path);

      status = false;
      break;
    }
    LOG(verbose, printf("    PNG file opened\n"));

    LOG(verbose, printf("    Creating structure for writing PNG file ...\n"));
    if (roadmap->id != PNGCREATEWRITESTRUCT_FAILED_RM)
    {
      png->ptr =
        png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    }

    if (!png->ptr)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "png_create_write_struct() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Structure for writing PNG file created\n"));

    LOG(verbose, printf("    Creating PNG info structure ...\n"));
    if (roadmap->id != PNGCREATEWRITEINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "png_create_info_struct() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    PNG info structure created\n"));

    LOG(verbose, printf("    Searching libPNG error ...\n"));
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (roadmap->id == PNG_WRITEJMPBUF_FAILED_RM))
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr),
        "Routine problem: libPNG encountered an error\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    No error found\n"));

    LOG(verbose, printf("    Initializing PNG input/output ...\n"));
    png_init_io(png->ptr, png->file);
    LOG(verbose, printf("    PNG input/output initialized\n"));

    LOG(verbose, printf("    Building PNG_IHDR chunk information thanks to \
PNG info structure ...\n"));
    png_set_IHDR(png->ptr, png->info, *width, *height,
      8, PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE,
      PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
    LOG(verbose, printf("    PNG_IHDR chunk information built\n"));

    LOG(verbose, printf("    Writing PNG info ...\n"));
    png_write_info(png->ptr, png->info);
    LOG(verbose, printf("    PNG info written\n"));

    LOG(verbose, printf("    Writing PNG image ...\n"));
    png_write_image(png->ptr, png->write_row_pointers);
    LOG(verbose, printf("    PNG image written\n"));

    LOG(verbose, printf("    Finishing PNG writing ...\n"));
    png_write_end(png->ptr, NULL);
    LOG(verbose, printf("    PNG writing finished\n"));
  } while (false);

  return status;
}

bool generateAtlas(PNG* png, UniformValues* values, bool verbose,
  Roadmap* roadmap)
{
  bool status = true;
  int width = 0;
  int height = 0;

  do
  {
    LOG(verbose, printf("  Generating PCG texture ...\n"));
    if (!generatePcgTexture(png, values, &width, &height, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to generate PCG texture\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  PCG texture generated successfully\n"));

    LOG(verbose, printf("  Writing PNG textures atlas ...\n"));
    if (!writePng(png, values, &width, &height, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to write PNG textures \
atlas\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  PNG textures atlas written\n"));

  } while (false);

  if (png->file)
  {
    LOG(verbose, printf("  Closing PNG file ...\n"));
    fclose(png->file);
    png->file = NULL;
    LOG(verbose, printf("  PNG file closed\n"));
  }

  if (png->ptr != NULL)
  {
    LOG(verbose, printf("  Destroying PNG write struct and PNG info struct \
...\n"));
    png_destroy_write_struct(&png->ptr, png->info ? &(png->info) : 0);
    png->ptr = 0;
    png->info = 0;
    LOG(verbose, printf("  PNG write struct and PNG info struct destroyed\n"));
  }

  for (int i = 0; i < height; i++)
  {
    if (png->write_row_pointers[i])
    {
      LOG(verbose, printf("  Freeing memory for write_row_pointers[%d] \
...\n", i));
      free(png->write_row_pointers[i]);
      png->write_row_pointers[i] = NULL;
      LOG(verbose, printf("  Memory freed successfully\n"));
    }
  }

  if (png->write_row_pointers)
  {
    LOG(verbose, printf("  Freeing memory for write_row_pointers ...\n"));
    free(png->write_row_pointers);
    png->write_row_pointers = NULL;
    LOG(verbose, printf("  Memory freed successfully\n"));
  }

  return status;
}

bool freePng(PNG* png, bool verbose)
{
  int status = true;

  if (png->ptr)
  {
    LOG(verbose, printf("  Destroying PNG read struct and PNG info struct \
...\n"));
    png_destroy_read_struct(&(png->ptr), png->info ? &(png->info) : 0, 0);
    png->ptr = 0;
    png->info = 0;
    LOG(verbose, printf("  PNG read struct and PNG info struct destroyed\n"));
  }

  if (png->read_row_pointers)
  {
    LOG(verbose, printf("  Freeing PNG read_row_pointers ...\n"));
    free(png->read_row_pointers);
    png->read_row_pointers = NULL;
    LOG(verbose, printf("  PNG read_row_pointers freed\n"));
  }

  if (png->data)
  {
    LOG(verbose, printf("  Freeing PNG data ...\n"));
    free(png->data);
    png->data = NULL;
    LOG(verbose, printf("  PNG data freed\n"));
  }

  if (png->file)
  {
    LOG(verbose, printf("  Closing PNG file ...\n"));
    fclose(png->file);
    png->file = NULL;
    LOG(verbose, printf("  PNG file closed\n"));
  }

  do
  {
    if (png->texture)
    {
      LOG(verbose, printf("  Deleting OpenGL texture ...\n"));
      GL_CHECK(glDeleteTextures(1, &(png->texture)), status);
      LOG(verbose, printf("  OpenGL texture deleted\n"));
    }
  } while (false);

  return status;
}

void freeTextures(Textures* textures, bool verbose)
{
  LOG(verbose, printf("Freeing bigstars PNG structure ...\n"));
  freePng(&(textures->bigstars), verbose);
  LOG(verbose, printf("bigstars PNG structure freed\n"));

  LOG(verbose, printf("Freeing atlas PNG structure ...\n"));
  freePng(&(textures->atlas), verbose);
  LOG(verbose, printf("atlas PNG structure freed\n"));
}
