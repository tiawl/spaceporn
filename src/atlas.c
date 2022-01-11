#include "atlas.h"

void generatePcgTexture(Atlas* atlas, int offset)
{
  uvec4 u;

  for (int y = 0; y < atlas->height; y++)
  {
    for (int x = 0; x < atlas->width * 4; x += 4)
    {
      u.x = x / 4;
      u.y = y;
      u.z = atlas->seed[0] + offset;
      u.w = atlas->seed[1];
      pcg4d(&u);
      atlas->texels[(atlas->pcg_depth - 1 - offset) * atlas->height
        + atlas->height - 1 - y][x] =
          (GLubyte) round((((double) u.x) / (double) UINT_MAX) * 255.);
      atlas->texels[(atlas->pcg_depth - 1 - offset) * atlas->height
        + atlas->height - 1 - y][x + 1] =
          (GLubyte) round((((double) u.y) / (double) UINT_MAX) * 255.);
      atlas->texels[(atlas->pcg_depth - 1 - offset) * atlas->height
        + atlas->height - 1 - y][x + 2] =
          (GLubyte) round((((double) u.z) / (double) UINT_MAX) * 255.);
      atlas->texels[(atlas->pcg_depth - 1 - offset) * atlas->height
        + atlas->height - 1 - y][x + 3] =
          (GLubyte) round((((double) u.w) / (double) UINT_MAX) * 255.);
    }
  }
}

bool readAtlas(Atlas* atlas, PNG* png, Log* log)
{
  bool status = true;

  do
  {
    png_uint_32 w, h;
    int bit_depth;
    int color_type;

    writeLog(log, stdout, "", "    Checking PNG filename ...\n");
    if (!png->path || (log->roadmap.id == NO_ATLASPNG_FILENAME_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "PNG filename is null\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    PNG filename is not null ...\n");

    writeLog(log, stdout, "", "    Opening PNG file \"%s\" ...\n", png->path);
    if (log->roadmap.id != FOPEN_ATLASPNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "rb");
    }

    if (!png->file)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "Failed to open \"%s\"\n", png->path);

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    PNG file opened\n");

    writeLog(log, stdout, "",
      "    Creating structure for reading PNG file ...\n");
    if (log->roadmap.id != ATLASPNGCREATEREADSTRUCT_FAILED_RM)
    {
      png->ptr =
        png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    }

    if (!png->ptr)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "png_create_read_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    Structure for reading PNG file created\n");

    writeLog(log, stdout, "", "    Creating PNG info structure ...\n");
    if (log->roadmap.id != ATLASPNGCREATEREADINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "png_create_info_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    PNG info structure created\n");

    writeLog(log, stdout, "", "    Searching libPNG error ...\n");
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (log->roadmap.id == ATLASPNG_READJMPBUF_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "Routine problem: libPNG encountered an error\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    No error found\n");

    writeLog(log, stdout, "", "    Initializing PNG input/output ...\n");
    png_init_io(png->ptr, png->file);
    writeLog(log, stdout, "", "    PNG input/output initialized\n");

    writeLog(log, stdout, "", "    Reading PNG info ...\n");
    png_read_info(png->ptr, png->info);
    writeLog(log, stdout, "", "    PNG info read\n");

    writeLog(log, stdout, "",
      "    Querying PNG_IHDR chunk information from PNG info structure ...\n");
    png_get_IHDR(
      png->ptr, png->info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
    writeLog(log, stdout, "", "    PNG_IHDR chunk information found\n");

    writeLog(log, stdout, "", "    Updating PNG info structure ...\n");
    png_read_update_info(png->ptr, png->info);
    writeLog(log, stdout, "", "    PNG info structure updated\n");

    writeLog(log, stdout, "", "    Querying number of bytes for a row ...\n");
    int rowbytes = png_get_rowbytes(png->ptr, png->info);
    rowbytes += 3 - ((rowbytes-1) % 4);
    writeLog(log, stdout, "", "    Number of bytes for a row is %d\n",
      rowbytes);

    writeLog(log, stdout, "", "    Allocating memory for data ...\n");
    if (log->roadmap.id != ATLASPNG_DATA_MALLOC_FAILED_RM)
    {
      png->data = malloc(rowbytes * h * sizeof(png_byte) + 15);
    }

    if (!png->data)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "data malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    Memory allocated successfully\n");

    writeLog(log, stdout, "", "    Allocating memory for row_pointers ...\n");
    if (log->roadmap.id != ATLASPNG_READROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->row_pointers = malloc(h * sizeof(png_bytep));
    }

    if (!png->row_pointers)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "row_pointers malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    Memory allocated successfully\n");

    for (png_uint_32 i = 0; i < h; ++i)
    {
      writeLog(log, stdout, "", "    Setting individual %s %d/%d\n",
        "row_pointers to point at the correct offsets of data ...", i, h);
      png->row_pointers[h - 1 - i] = png->data + i * rowbytes;
    }
    writeLog(log, stdout, "", "    Setting individual %s %d/%d\n",
      "row_pointers to point at the correct offsets of data ...", h, h);
    writeLog(log, stdout, "", "    Individual row_pointers set\n");

    writeLog(log, stdout, "", "    Reading PNG image into memory ...\n");
    png_read_image(png->ptr, png->row_pointers);
    writeLog(log, stdout, "", "    PNG image read into memory\n");

    writeLog(log, stdout, "", "    Finishing PNG reading ...\n");
    png_read_end(png->ptr, NULL);
    writeLog(log, stdout, "", "    PNG reading finished\n");
  } while (false);

  return status;
}

bool writePng(Atlas* atlas, PNG* png, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "    Opening PNG file \"%s\" ...\n", png->path);
    if (log->roadmap.id != FOPEN_NEW_PNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "wb");
    }

    if (!png->file)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "Failed to open \"%s\"\n", png->path);

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    PNG file opened\n");

    writeLog(log, stdout, "",
      "    Creating structure for writing PNG file ...\n");
    if (log->roadmap.id != PNGCREATEWRITESTRUCT_FAILED_RM)
    {
      png->ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL,
        NULL);
    }

    if (!png->ptr)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "png_create_write_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    Structure for writing PNG file created\n");

    writeLog(log, stdout, "", "    Creating PNG info structure ...\n");
    if (log->roadmap.id != PNGCREATEWRITEINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "png_create_info_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    PNG info structure created\n");

    writeLog(log, stdout, "", "    Searching libPNG error ...\n");
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (log->roadmap.id == PNG_WRITEJMPBUF_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "    ",
        "Routine problem: libPNG encountered an error\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "    No error found\n");

    writeLog(log, stdout, "", "    Initializing PNG input/output ...\n");
    png_init_io(png->ptr, png->file);
    writeLog(log, stdout, "", "    PNG input/output initialized\n");

    writeLog(log, stdout, "", "    Building PNG_IHDR chunk information %s",
      "thanks to PNG info structure ...\n");
    png_set_IHDR(png->ptr, png->info, atlas->width,
      atlas->height * atlas->depth, 8, PNG_COLOR_TYPE_RGB_ALPHA,
      PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
      PNG_FILTER_TYPE_DEFAULT);
    writeLog(log, stdout, "", "    PNG_IHDR chunk information built\n");

    writeLog(log, stdout, "", "    Writing PNG info ...\n");
    png_write_info(png->ptr, png->info);
    writeLog(log, stdout, "", "    PNG info written\n");

    writeLog(log, stdout, "", "    Writing PNG image ...\n");
    png_write_image(png->ptr, atlas->texels);
    writeLog(log, stdout, "", "    PNG image written\n");

    writeLog(log, stdout, "", "    Finishing PNG writing ...\n");
    png_write_end(png->ptr, NULL);
    writeLog(log, stdout, "", "    PNG writing finished\n");
  } while (false);

  if (png->file)
  {
    writeLog(log, stdout, "", "    Closing PNG file ...\n");
    fclose(png->file);
    png->file = NULL;
    writeLog(log, stdout, "", "    PNG file closed\n");
  }

  if (png->ptr != NULL)
  {
    writeLog(log, stdout, "",
      "    Destroying PNG write struct and PNG info struct ...\n");
    png_destroy_write_struct(&(png->ptr), png->info ? &(png->info) : 0);
    png->ptr = 0;
    png->info = 0;
    writeLog(log, stdout, "",
      "    PNG write struct and PNG info struct destroyed\n");
  }

  return status;
}

bool generateAtlas(Atlas* atlas, PNG* png, Log* log)
{
  bool status = true;

  do
  {
     if (log->roadmap.id == BAD_ATLASPNG_DIMENSIONS_RM)
    {
      atlas->width = 15;
    }

    writeLog(log, stdout, "", "  Testing textures atlas dimensions ...\n");
    if ((atlas->width & (atlas->width - 1)) || (atlas->width < 8) ||
      (atlas->height & (atlas->height - 1)) || (atlas->height < 8))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Textures with dimensions that are not power of two or smaller %s",
        "than 8 failed to load in OpenGL\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Valid textures atlas dimensions\n");

    writeLog(log, stdout, "", "  Allocating memory for texels ...\n");
    if (log->roadmap.id != ATLASTEXELS_MALLOC_FAILED_RM)
    {
      atlas->texels =
        (png_byte**) malloc(sizeof(png_byte*) * atlas->height * atlas->depth);
    }

    if (!atlas->texels)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Texels malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Memory allocated successfully\n");

    writeLog(log, stdout, "", "  Allocating memory for each texels row ...\n");
    for (int i = 0; i < atlas->height * atlas->depth; i++)
    {
      atlas->texels[i] = NULL;

      writeLog(log, stdout, "",
        "    Allocating memory for texels[%d] ...\n", i);
      if (log->roadmap.id != ATLASTEXELROW_MALLOC_FAILED_RM)
      {
        atlas->texels[i] = (png_byte*) malloc(4 * atlas->width);
      }

      if (!atlas->texels[i])
      {
        writeLog(log, (log->verbose ? stdout : stderr), "    ",
          "texels[%d] malloc() failed\n", i);

        atlas->height = i;
        atlas->depth = 1;
        status = false;
        break;
      }
      writeLog(log, stdout, "", "    Memory allocated successfully\n");
    }

    if (!status)
    {
      writeLog(log, stdout, "", "  Failed to allocate memory\n");
      break;
    }
    writeLog(log, stdout, "", "  Memory allocated successfully\n");

    writeLog(log, stdout, "", "  Generating PCG textures ...\n");
    for (int seed = 0; seed < atlas->pcg_depth; seed++)
    {
      writeLog(log, stdout, "", "    Generating PCG texture %d ...\n", seed);
      generatePcgTexture(atlas, seed);
      writeLog(log, stdout, "", "    PCG texture %d generated successfully\n",
        seed);
    }
    writeLog(log, stdout, "", "  PCG textures generated successfully\n");

    writeLog(log, stdout, "", "  Writing PNG textures atlas ...\n");
    if (!writePng(atlas, png, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to write PNG textures atlas\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  PNG textures atlas written\n");
  } while (false);

  return status;
}

void freeAtlas(Atlas* atlas, Log* log)
{
  if (atlas->texels != NULL)
  {
    for (int i = 0; i < atlas->height * atlas->depth; i++)
    {
      if (atlas->texels[i] != NULL)
      {
        writeLog(log, stdout, "", "  Freeing texels[%d] memory ...\n", i);
        free(atlas->texels[i]);
        atlas->texels[i] = NULL;
        writeLog(log, stdout, "", "  Memory freed successfully\n");
      }
    }

    writeLog(log, stdout, "", "  Freeing texels memory ...\n");
    free(atlas->texels);
    atlas->texels = NULL;
    writeLog(log, stdout, "", "  Memory freed successfully\n");
  }
}

bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "  Reading atlas PNG texture ...\n");
    if (!readAtlas(atlas, png, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Reading atlas PNG texture failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Atlas PNG texture read\n");

    writeLog(log, stdout, "", "  Generating OpenGL texture ...\n");
    GL_CHECK(glGenTextures(1, &(png->texture)), status, log);
    writeLog(log, stdout, "", "  OpenGL texture is %d\n", png->texture);

    writeLog(log, stdout, "", "  Activating OpenGL texture ...\n");
    GL_CHECK(glActiveTexture(GL_TEXTURE0 + png->texture_unit), status, log);
    writeLog(log, stdout, "", "  OpenGL texture activated\n");

    writeLog(log, stdout, "", "  Binding OpenGL textures array ...\n");
    GL_CHECK(glBindTexture(GL_TEXTURE_2D_ARRAY, png->texture), status, log);
    writeLog(log, stdout, "", "  OpenGL textures array binded\n");

    writeLog(log, stdout, "", "  Setting texture unit to use ...\n");
    GL_CHECK(glUniform1i(glGetUniformLocation(shaders->program, "atlas"),
      png->texture_unit), status, log);
    writeLog(log, stdout, "", "  Texture unit ready to use\n");

    writeLog(log, stdout, "", "  Specifying 2D textures array ...\n");
    GL_CHECK(glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, atlas->width,
      atlas->height, atlas->depth, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0),
        status, log);
    writeLog(log, stdout, "", "  2D textures array specified\n");

    writeLog(log, stdout, "",
      "  Specifying fallback for 2D textures array ...\n");
    glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, 0, atlas->width,
      atlas->height, atlas->depth, GL_RGBA, GL_UNSIGNED_BYTE, png->data);
    writeLog(log, stdout, "", "  Fallback specified\n");

    writeLog(log, stdout, "", "  Enabling OpenGL textures repetition ...\n");
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S,
      GL_REPEAT), status, log);
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T,
      GL_REPEAT), status, log);
    writeLog(log, stdout, "", "  OpenGL textures repetition disabled\n");

    writeLog(log, stdout, "", "  Specifying textures element value to %s",
      "the nearest texture coordinates ...\n");
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_NEAREST), status, log);
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER, GL_NEAREST), status, log);
    writeLog(log, stdout, "", "  Textures element value specified ...\n");
  } while (false);

  return status;
}
