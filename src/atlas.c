#include "atlas.h"

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
        (png_byte**) malloc(sizeof(png_byte*) * (atlas->height));
    }

    if (!atlas->texels)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "Texels malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Memory allocated successfully\n"));

    LOG(verbose, printf("    Allocating memory for each texels row ...\n"));
    for (int i = 0; i < atlas->height; i++)
    {
      atlas->texels[i] = NULL;

      LOG(verbose, printf("      Allocating memory for texels[%d] \
...\n", i));
      if (roadmap->id != ATLASTEXELROW_MALLOC_FAILED_RM)
      {
        atlas->texels[i] = (png_byte*) malloc(4 * atlas->width);
      }

      if (!atlas->texels[i])
      {
        LOG(verbose, printf("      "));
        fprintf((verbose ? stdout : stderr), "texels[%d] malloc() failed\n", i);

        atlas->height = i;
        status = false;
        break;
      }
      LOG(verbose, printf("      Memory allocated successfully\n"));
    }

    if (!status)
    {
      LOG(verbose, printf("    Failed to allocate memory\n"));
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
        atlas->texels[atlas->height - 1 - y][x] =
          (GLubyte) ceil((((double) u.x) / (double) UINT_MAX) * 256.);
        atlas->texels[atlas->height - 1 - y][x + 1] =
          (GLubyte) ceil((((double) u.y) / (double) UINT_MAX) * 256.);
        atlas->texels[atlas->height - 1 - y][x + 2] =
          (GLubyte) ceil((((double) u.z) / (double) UINT_MAX) * 256.);
        atlas->texels[atlas->height - 1 - y][x + 3] =
          (GLubyte) ceil((((double) u.w) / (double) UINT_MAX) * 256.);
        LOG(verbose, printf("    Computing PCG texture ... %d/%d\n",
          (x / 4) + 1 + (y * atlas->width), atlas->width * atlas->height));
      }
    }
    LOG(verbose, printf("    PCG texture computed successfully\n"));
  } while (false);

  return status;
}

bool readAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap)
{
  bool status = true;

  do
  {
    png_uint_32 w, h;
    int bit_depth;
    int color_type;

    LOG(verbose, printf("    Checking PNG filename ...\n"));
    if (!png->path || (roadmap->id == NO_ATLASPNG_FILENAME_RM))
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "PNG filename is null\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    PNG filename is not null ...\n"));

    LOG(verbose, printf("    Opening PNG file \"%s\" ...\n", png->path));
    if (roadmap->id != FOPEN_ATLASPNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "rb");
    }

    if (!png->file)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "Failed to open \"%s\"\n", png->path);

      status = false;
      break;
    }
    LOG(verbose, printf("    PNG file opened\n"));

    LOG(verbose, printf("    Creating structure for reading PNG file ...\n"));
    if (roadmap->id != ATLASPNGCREATEREADSTRUCT_FAILED_RM)
    {
      png->ptr =
        png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    }

    if (!png->ptr)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "png_create_read_struct() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Structure for reading PNG file created\n"));

    LOG(verbose, printf("    Creating PNG info structure ...\n"));
    if (roadmap->id != ATLASPNGCREATEREADINFOSTRUCT_FAILED_RM)
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
      (roadmap->id == ATLASPNG_READJMPBUF_FAILED_RM))
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

    LOG(verbose, printf("    Reading PNG info ...\n"));
    png_read_info(png->ptr, png->info);
    LOG(verbose, printf("    PNG info read\n"));

    LOG(verbose, printf("    Querying PNG_IHDR chunk information from PNG info \
structure ...\n"));
    png_get_IHDR(
      png->ptr, png->info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
    LOG(verbose, printf("    PNG_IHDR chunk information found\n"));

    LOG(verbose, printf("    Updating PNG info structure ...\n"));
    png_read_update_info(png->ptr, png->info);
    LOG(verbose, printf("    PNG info structure updated\n"));

    LOG(verbose, printf("    Querying number of bytes for a row ...\n"));
    int rowbytes = png_get_rowbytes(png->ptr, png->info);
    rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes
    LOG(verbose, printf("    Number of bytes for a row is %d\n", rowbytes));

    LOG(verbose, printf("    Allocating memory for data ...\n"));
    if (roadmap->id != ATLASPNG_DATA_MALLOC_FAILED_RM)
    {
      png->data = malloc(rowbytes * h * sizeof(png_byte) + 15);
    }

    if (!png->data)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "data malloc() failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Memory allocated successfully\n"));

    LOG(verbose, printf("    Allocating memory for row_pointers ...\n"));
    if (roadmap->id != ATLASPNG_READROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->row_pointers = malloc(h * sizeof(png_bytep));
    }

    if (!png->row_pointers)
    {
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "row_pointers malloc() \
failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("    Memory allocated successfully\n"));

    for(png_uint_32 i = 0; i < h; ++i)
    {
      LOG(verbose, printf("    Setting individual row_pointers to point \
at the correct offsets of data ... %d/%d\n", i, h));
      png->row_pointers[h - 1 - i] = png->data + i * rowbytes;
    }
    LOG(verbose, printf("    Setting individual row_pointers to point at \
the correct offsets of data ... %d/%d\n", h, h));
    LOG(verbose, printf("    Individual row_pointers set\n"));

    LOG(verbose, printf("    Reading PNG image into memory ...\n"));
    png_read_image(png->ptr, png->row_pointers);
    LOG(verbose, printf("    PNG image read into memory\n"));

    LOG(verbose, printf("    Finishing PNG reading ...\n"));
    png_read_end(png->ptr, NULL);
    LOG(verbose, printf("    PNG reading finished\n"));
  } while (false);

  return status;
}

bool writePng(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap)
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
      LOG(verbose, printf("    "));
      fprintf((verbose ? stdout : stderr), "Failed to open \"%s\"\n",
        png->path);

      status = false;
      break;
    }
    LOG(verbose, printf("    PNG file opened\n"));

    LOG(verbose, printf("    Creating structure for writing PNG file ...\n"));
    if (roadmap->id != PNGCREATEWRITESTRUCT_FAILED_RM)
    {
      png->ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
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
    png_set_IHDR(png->ptr, png->info, atlas->width,
      atlas->height * atlas->depth, 8, PNG_COLOR_TYPE_RGB_ALPHA,
      PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
      PNG_FILTER_TYPE_DEFAULT);
    LOG(verbose, printf("    PNG_IHDR chunk information built\n"));

    LOG(verbose, printf("    Writing PNG info ...\n"));
    png_write_info(png->ptr, png->info);
    LOG(verbose, printf("    PNG info written\n"));

    LOG(verbose, printf("    Writing PNG image ...\n"));
    png_write_image(png->ptr, atlas->texels);
    LOG(verbose, printf("    PNG image written\n"));

    LOG(verbose, printf("    Finishing PNG writing ...\n"));
    png_write_end(png->ptr, NULL);
    LOG(verbose, printf("    PNG writing finished\n"));
  } while (false);

  if (png->file)
  {
    LOG(verbose, printf("    Closing PNG file ...\n"));
    fclose(png->file);
    png->file = NULL;
    LOG(verbose, printf("    PNG file closed\n"));
  }

  if (png->ptr != NULL)
  {
    LOG(verbose, printf("    Destroying PNG write struct and PNG info struct \
...\n"));
    png_destroy_write_struct(&(png->ptr), png->info ? &(png->info) : 0);
    png->ptr = 0;
    png->info = 0;
    LOG(verbose, printf("    PNG write struct and PNG info struct destroyed\n"));
  }

  return status;
}

bool generateAtlas(Atlas* atlas, PNG* png, bool verbose, Roadmap* roadmap)
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

    LOG(verbose, printf("  Writing PNG textures atlas ...\n"));
    if (!writePng(atlas, png, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "Failed to write PNG textures \
atlas\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  PNG textures atlas written\n"));
  } while (false);


  if (atlas->texels != NULL)
  {
    for (int i = 0; i < atlas->height; i++)
    {
      if (atlas->texels[i] != NULL)
      {
        LOG(verbose, printf("  Freeing memory for texels[%d] \
...\n", i));
        free(atlas->texels[i]);
        atlas->texels[i] = NULL;
        LOG(verbose, printf("  Memory freed successfully\n"));
      }
    }

    LOG(verbose, printf("  Freeing memory for texels ...\n"));
    free(atlas->texels);
    atlas->texels = NULL;
    LOG(verbose, printf("  Memory freed successfully\n"));
  }

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

bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, bool verbose,
  Roadmap* roadmap)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Reading atlas PNG texture ...\n"));
    if (!readAtlas(atlas, png, verbose, roadmap))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "Reading atlas PNG texture failed\n");

      status = false;
      break;
    }
    LOG(verbose, printf("  Atlas PNG texture read\n"));

    LOG(verbose, printf("  Generating OpenGL texture ...\n"));
    GL_CHECK(glGenTextures(1, &(png->texture)), status);
    LOG(verbose, printf("  OpenGL texture is %d\n", png->texture));

    LOG(verbose, printf("  Activating OpenGL texture ...\n"));
    GL_CHECK(glActiveTexture(GL_TEXTURE0 + png->texture_unit), status);
    LOG(verbose, printf("  OpenGL texture activated\n"));

    LOG(verbose, printf("  Binding OpenGL textures array ...\n"));
    GL_CHECK(glBindTexture(GL_TEXTURE_2D_ARRAY, png->texture), status);
    LOG(verbose, printf("  OpenGL textures array binded\n"));

    LOG(verbose, printf("  Setting texture unit to use ...\n"));
    GL_CHECK(glUniform1i(glGetUniformLocation(shaders->program, "atlas"),
      png->texture_unit), status);
    LOG(verbose, printf("  Texture unit ready to use\n"));

    LOG(verbose, printf("  Specifying 2D textures array ...\n"));
    GL_CHECK(glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, atlas->width,
      atlas->height, atlas->depth, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0), status);
    LOG(verbose, printf("  2D textures array specified\n"));

    LOG(verbose, printf("  Specifying fallback for 2D textures array ...\n"));
    glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, 0, atlas->width,
      atlas->height, atlas->depth, GL_RGBA, GL_UNSIGNED_BYTE, png->data);
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
