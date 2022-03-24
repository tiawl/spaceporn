#include "atlas.h"

void generatePcgTexture(Atlas* atlas, int offset)
{
  uvec4 u;

  for (unsigned y = 0; y < atlas->height; y++)
  {
    for (unsigned x = 0; x < atlas->width * 4; x += 4)
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
    int bit_depth;
    int color_type;

    writeLog(log, stdout, DEBUG, "", "    Checking PNG filename ...\n");
    if (!png->path || (log->roadmap.id == NO_ATLASPNG_FILENAME_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "PNG filename is null\n");
      atlas->height *= atlas->depth;

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    PNG filename is not null ...\n");

    writeLog(log, stdout, INFO, "", "    Opening PNG file \"%s\" ...\n",
      png->path);
    if (log->roadmap.id != FOPEN_ATLASPNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "rb");
    }

    if (!png->file)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Failed to open \"%s\"\n", png->path);
      atlas->height *= atlas->depth;

      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "", "    PNG file opened\n");

    writeLog(log, stdout, DEBUG, "",
      "    Creating structure for reading PNG file ...\n");
    if (log->roadmap.id != ATLASPNGCREATEREADSTRUCT_FAILED_RM)
    {
      png->ptr =
        png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    }

    if (!png->ptr)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "png_create_read_struct() failed\n");
      atlas->height *= atlas->depth;

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "",
      "    Structure for reading PNG file created\n");

    writeLog(log, stdout, DEBUG, "", "    Creating PNG info structure ...\n");
    if (log->roadmap.id != ATLASPNGCREATEREADINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "png_create_info_struct() failed\n");
      atlas->height *= atlas->depth;

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    PNG info structure created\n");

    writeLog(log, stdout, INFO, "", "    Searching libPNG error ...\n");
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (log->roadmap.id == ATLASPNG_READJMPBUF_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Routine problem: libPNG encountered an error\n");
      atlas->height *= atlas->depth;

      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "", "    No error found\n");

    writeLog(log, stdout, DEBUG, "", "    Initializing PNG input/output ...\n");
    png_init_io(png->ptr, png->file);
    writeLog(log, stdout, DEBUG, "", "    PNG input/output initialized\n");

    writeLog(log, stdout, DEBUG, "", "    Reading PNG info ...\n");
    png_read_info(png->ptr, png->info);
    writeLog(log, stdout, DEBUG, "", "    PNG info read\n");

    writeLog(log, stdout, DEBUG, "",
      "    Querying PNG_IHDR chunk information from PNG info structure ...\n");
    png_get_IHDR(png->ptr, png->info, &(atlas->width), &(atlas->height),
      &bit_depth, &color_type, 0, 0, 0);
    writeLog(log, stdout, DEBUG, "", "    PNG_IHDR chunk information found\n");

    writeLog(log, stdout, DEBUG, "", "    Updating PNG info structure ...\n");
    png_read_update_info(png->ptr, png->info);
    writeLog(log, stdout, DEBUG, "", "    PNG info structure updated\n");

    writeLog(log, stdout, INFO, "",
      "    Querying number of bytes for a row ...\n");
    int rowbytes = png_get_rowbytes(png->ptr, png->info);
    rowbytes += 3 - ((rowbytes - 1) % 4);
    writeLog(log, stdout, INFO, "", "    Number of bytes for a row is %d\n",
      rowbytes);

    writeLog(log, stdout, DEBUG, "", "    Allocating memory for data ...\n");
    if (log->roadmap.id != ATLASPNG_DATA_MALLOC_FAILED_RM)
    {
      png->data = malloc(rowbytes * atlas->height * sizeof(png_byte) + 15);
    }

    if (!png->data)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "data malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    Memory allocated successfully\n");

    writeLog(log, stdout, DEBUG, "",
      "    Allocating memory for row_pointers ...\n");
    if (log->roadmap.id != ATLASPNG_READROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->row_pointers = malloc(atlas->height * sizeof(png_bytep));
    }

    if (!png->row_pointers)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "row_pointers malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    Memory allocated successfully\n");

    for (png_uint_32 i = 0; i < atlas->height; ++i)
    {
      writeLog(log, stdout, DEBUG, "", "    Setting individual %s %d/%d\n",
        "row_pointers to point at the correct offsets of data ...",
          i, atlas->height);
      png->row_pointers[atlas->height - 1 - i] = png->data + i * rowbytes;
    }
    writeLog(log, stdout, DEBUG, "", "    Setting individual %s %d/%d\n",
      "row_pointers to point at the correct offsets of data ...",
        atlas->height, atlas->height);
    writeLog(log, stdout, DEBUG, "", "    Individual row_pointers set\n");

    writeLog(log, stdout, DEBUG, "", "    Reading PNG image into memory ...\n");
    png_read_image(png->ptr, png->row_pointers);
    writeLog(log, stdout, DEBUG, "", "    PNG image read into memory\n");

    writeLog(log, stdout, DEBUG, "", "    Finishing PNG reading ...\n");
    png_read_end(png->ptr, NULL);
    writeLog(log, stdout, DEBUG, "", "    PNG reading finished\n");
  } while (false);

  atlas->height /= atlas->depth;
  return status;
}

bool writePng(Atlas* atlas, PNG* png, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, INFO, "", "    Opening PNG file \"%s\" ...\n",
      png->path);
    if (log->roadmap.id != FOPEN_NEW_PNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "wb");
    }

    if (!png->file)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Failed to open \"%s\"\n", png->path);

      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "", "    PNG file opened\n");

    writeLog(log, stdout, DEBUG, "",
      "    Creating structure for writing PNG file ...\n");
    if (log->roadmap.id != PNGCREATEWRITESTRUCT_FAILED_RM)
    {
      png->ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL,
        NULL);
    }

    if (!png->ptr)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "png_create_write_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "",
      "    Structure for writing PNG file created\n");

    writeLog(log, stdout, DEBUG, "", "    Creating PNG info structure ...\n");
    if (log->roadmap.id != PNGCREATEWRITEINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "png_create_info_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "    PNG info structure created\n");

    writeLog(log, stdout, INFO, "", "    Searching libPNG error ...\n");
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (log->roadmap.id == PNG_WRITEJMPBUF_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
        "Routine problem: libPNG encountered an error\n");

      status = false;
      break;
    }
    writeLog(log, stdout, INFO, "", "    No error found\n");

    writeLog(log, stdout, DEBUG, "", "    Initializing PNG input/output ...\n");
    png_init_io(png->ptr, png->file);
    writeLog(log, stdout, DEBUG, "", "    PNG input/output initialized\n");

    writeLog(log, stdout, DEBUG, "", "    Building PNG_IHDR chunk %s",
      "information thanks to PNG info structure ...\n");
    png_set_IHDR(png->ptr, png->info, atlas->width,
      atlas->height * atlas->depth, 8, PNG_COLOR_TYPE_RGB_ALPHA,
      PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
      PNG_FILTER_TYPE_DEFAULT);
    writeLog(log, stdout, DEBUG, "", "    PNG_IHDR chunk information built\n");

    writeLog(log, stdout, DEBUG, "", "    Writing PNG info ...\n");
    png_write_info(png->ptr, png->info);
    writeLog(log, stdout, DEBUG, "", "    PNG info written\n");

    writeLog(log, stdout, DEBUG, "", "    Writing PNG image ...\n");
    png_write_image(png->ptr, atlas->texels);
    writeLog(log, stdout, DEBUG, "", "    PNG image written\n");

    writeLog(log, stdout, DEBUG, "", "    Finishing PNG writing ...\n");
    png_write_end(png->ptr, NULL);
    writeLog(log, stdout, DEBUG, "", "    PNG writing finished\n");
  } while (false);

  if (png->file)
  {
    writeLog(log, stdout, DEBUG, "", "    Closing PNG file ...\n");
    fclose(png->file);
    png->file = NULL;
    writeLog(log, stdout, DEBUG, "", "    PNG file closed\n");
  }

  if (png->ptr != NULL)
  {
    writeLog(log, stdout, DEBUG, "",
      "    Destroying PNG write struct and PNG info struct ...\n");
    png_destroy_write_struct(&(png->ptr), png->info ? &(png->info) : 0);
    png->ptr = 0;
    png->info = 0;
    writeLog(log, stdout, DEBUG, "",
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

    writeLog(log, stdout, DEBUG, "",
      "  Testing textures atlas dimensions ...\n");
    if ((atlas->width & (atlas->width - 1)) || (atlas->width < 8) ||
      (atlas->height & (atlas->height - 1)) || (atlas->height < 8))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Textures with dimensions that are not power of two or smaller %s",
        "than 8 failed to load in OpenGL\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Valid textures atlas dimensions\n");

    writeLog(log, stdout, DEBUG, "", "  Allocating memory for texels ...\n");
    if (log->roadmap.id != ATLASTEXELS_MALLOC_FAILED_RM)
    {
      atlas->texels =
        (png_byte**) malloc(sizeof(png_byte*) * atlas->height * atlas->depth);
    }

    if (!atlas->texels)
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Texels malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Memory allocated successfully\n");

    writeLog(log, stdout, DEBUG, "",
      "  Allocating memory for each texels row ...\n");
    for (unsigned i = 0; i < atlas->height * atlas->depth; i++)
    {
      atlas->texels[i] = NULL;

      writeLog(log, stdout, DEBUG, "",
        "    Allocating memory for texels[%d] ...\n", i);
      if (log->roadmap.id != ATLASTEXELROW_MALLOC_FAILED_RM)
      {
        atlas->texels[i] = (png_byte*) malloc(4 * atlas->width);
      }

      if (!atlas->texels[i])
      {
        writeLog(log, (log->verbose ? stdout : stderr), ERROR, "    ",
          "texels[%d] malloc() failed\n", i);

        atlas->height = i;
        atlas->depth = 1;
        status = false;
        break;
      }
      writeLog(log, stdout, DEBUG, "", "    Memory allocated successfully\n");
    }

    if (!status)
    {
      writeLog(log, stdout, ERROR, "", "  Failed to allocate memory\n");
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Memory allocated successfully\n");

    writeLog(log, stdout, DEBUG, "", "  Generating PCG textures ...\n");
    for (int seed = 0; seed < atlas->pcg_depth; seed++)
    {
      writeLog(log, stdout, DEBUG, "", "    Generating PCG texture %d ...\n",
        seed);
      generatePcgTexture(atlas, seed);
      writeLog(log, stdout, DEBUG, "",
        "    PCG texture %d generated successfully\n", seed);
    }
    writeLog(log, stdout, DEBUG, "", "  PCG textures generated successfully\n");

    writeLog(log, stdout, DEBUG, "", "  Writing PNG textures atlas ...\n");
    if (!writePng(atlas, png, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Failed to write PNG textures atlas\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  PNG textures atlas written\n");
  } while (false);

  return status;
}

bool generateAtlas2(Atlas* atlas, PNG* png, Log* log)
{
  bool status = true;
  return status;
}

void freeAtlas(Atlas* atlas, Log* log)
{

  if (atlas->texels != NULL)
  {
    for (unsigned i = 0; i < atlas->height * atlas->depth; i++)
    {
      if (atlas->texels[i] != NULL)
      {
        writeLog(log, stdout, DEBUG, "",
          "  Freeing texels[%d] memory ...\n", i);
        free(atlas->texels[i]);
        atlas->texels[i] = NULL;
        writeLog(log, stdout, DEBUG, "", "  Memory freed successfully\n");
      }
    }

    writeLog(log, stdout, DEBUG, "", "  Freeing texels memory ...\n");
    free(atlas->texels);
    atlas->texels = NULL;
    writeLog(log, stdout, DEBUG, "", "  Memory freed successfully\n");
  }
}

bool loadAtlas(Atlas* atlas, PNG* png, Shaders* shaders, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, DEBUG, "", "  Reading atlas PNG texture ...\n");
    if (!readAtlas(atlas, png, log))
    {
      writeLog(log, (log->verbose ? stdout : stderr), ERROR, "  ",
        "Reading atlas PNG texture failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, DEBUG, "", "  Atlas PNG texture read\n");

    writeLog(log, stdout, INFO, "", "  Generating OpenGL texture ...\n");
    GL_CHECK(glGenTextures(1, &(png->texture)), status, log);
    writeLog(log, stdout, INFO, "", "  OpenGL texture is %d\n", png->texture);

    writeLog(log, stdout, DEBUG, "", "  Activating OpenGL texture ...\n");
    GL_CHECK(glActiveTexture(GL_TEXTURE0 + png->texture_unit), status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL texture activated\n");

    writeLog(log, stdout, DEBUG, "", "  Binding OpenGL textures array ...\n");
    GL_CHECK(glBindTexture(GL_TEXTURE_2D_ARRAY, png->texture), status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL textures array binded\n");

    writeLog(log, stdout, DEBUG, "", "  Setting texture unit to use ...\n");
    GL_CHECK(glUniform1i(glGetUniformLocation(shaders->program, "atlas"),
      png->texture_unit), status, log);
    writeLog(log, stdout, DEBUG, "", "  Texture unit ready to use\n");

    writeLog(log, stdout, DEBUG, "", "  Specifying 2D textures array ...\n");
    GL_CHECK(glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, atlas->width,
      atlas->height, atlas->depth, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0), status,
        log);
    writeLog(log, stdout, DEBUG, "", "  2D textures array specified\n");

    writeLog(log, stdout, DEBUG, "",
      "  Specifying fallback for 2D textures array ...\n");
    GL_CHECK(glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, 0, atlas->width,
      atlas->height, atlas->depth, GL_RGBA, GL_UNSIGNED_BYTE, png->data),
        status, log);
    writeLog(log, stdout, DEBUG, "", "  Fallback specified\n");

    writeLog(log, stdout, DEBUG, "",
      "  Disabling OpenGL textures mipmaps level ...\n");
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_BASE_LEVEL, 0),
      status, log);
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAX_LEVEL, 0),
      status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL textures mipmaps disabled\n");

    writeLog(log, stdout, DEBUG, "",
      "  Enabling OpenGL textures repetition ...\n");
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S,
      GL_REPEAT), status, log);
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T,
      GL_REPEAT), status, log);
    writeLog(log, stdout, DEBUG, "", "  OpenGL textures repetition disabled\n");

    writeLog(log, stdout, DEBUG, "", "  Specifying textures element value %s",
      "to the nearest texture coordinates ...\n");
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_NEAREST), status, log);
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER, GL_NEAREST), status, log);
    writeLog(log, stdout, DEBUG, "",
      "  Textures element value specified ...\n");
  } while (false);

  return status;
}
