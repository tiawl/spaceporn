#include "texture.h"

bool loadPng(PNG* png, Shaders* shaders, Log* log)
{
  bool status = true;

  do
  {
    png_uint_32 w, h;
    int bit_depth;
    int color_type;

    writeLog(log, stdout, "", "  Checking PNG filename ...\n");
    if (!png->path || (log->roadmap.id == NO_PNG_FILENAME_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "PNG filename is null\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  PNG filename is not null ...\n");

    writeLog(log, stdout, "", "  Opening PNG file \"%s\" ...\n", png->path);
    if (log->roadmap.id != FOPEN_PNG_FILE_FAILED_RM)
    {
      png->file = fopen(png->path, "rb");
    }

    if (!png->file)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Failed to open \"%s\"\n", png->path);

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  PNG file opened\n");

    writeLog(log, stdout, "",
      "  Creating structure for reading PNG file ...\n");
    if (log->roadmap.id != PNGCREATEREADSTRUCT_FAILED_RM)
    {
      png->ptr =
        png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    }

    if (!png->ptr)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "png_create_read_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Structure for reading PNG file created\n");

    writeLog(log, stdout, "", "  Creating PNG info structure ...\n");
    if (log->roadmap.id != PNGCREATEREADINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->ptr);
    }

    if (!png->info)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "png_create_info_struct() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  PNG info structure created\n");

    writeLog(log, stdout, "", "  Searching libPNG error ...\n");
    if (setjmp(png_jmpbuf(png->ptr)) ||
      (log->roadmap.id == PNG_READJMPBUF_FAILED_RM))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Routine problem: libPNG encountered an error\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  No error found\n");

    writeLog(log, stdout, "", "  Initializing PNG input/output ...\n");
    png_init_io(png->ptr, png->file);
    writeLog(log, stdout, "", "  PNG input/output initialized\n");

    writeLog(log, stdout, "", "  Reading PNG info ...\n");
    png_read_info(png->ptr, png->info);
    writeLog(log, stdout, "", "  PNG info read\n");

    writeLog(log, stdout, "",
      "  Querying PNG_IHDR chunk information from PNG info structure ...\n");
    png_get_IHDR(
      png->ptr, png->info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
    writeLog(log, stdout, "", "  PNG_IHDR chunk information found\n");

    if (log->roadmap.id == BAD_PNG_DIMENSIONS_RM)
    {
      w = 15;
    }

    writeLog(log, stdout, "", "  Testing textures dimensions ...\n");
    if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "Textures with dimensions that are not power of two or smaller %s",
        "than 8 failed to load in OpenGL\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Valid PNG images dimensions\n");

    writeLog(log, stdout, "", "  Updating PNG info structure ...\n");
    png_read_update_info(png->ptr, png->info);
    writeLog(log, stdout, "", "  PNG info structure updated\n");

    writeLog(log, stdout, "", "  Querying number of bytes for a row ...\n");
    int rowbytes = png_get_rowbytes(png->ptr, png->info);
    rowbytes += 3 - ((rowbytes - 1) % 4);
    writeLog(log, stdout, "", "  Number of bytes for a row is %d\n", rowbytes);

    writeLog(log, stdout, "", "  Allocating memory for data ...\n");
    if (log->roadmap.id != PNG_DATA_MALLOC_FAILED_RM)
    {
      png->data = malloc(rowbytes * h * sizeof(png_byte) + 15);
    }

    if (!png->data)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "data malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Memory allocated successfully\n");

    writeLog(log, stdout, "", "  Allocating memory for row_pointers ...\n");
    if (log->roadmap.id != PNG_READROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->row_pointers = malloc(h * sizeof(png_bytep));
    }

    if (!png->row_pointers)
    {
      writeLog(log, (log->verbose ? stdout : stderr), "  ",
        "row_pointers malloc() failed\n");

      status = false;
      break;
    }
    writeLog(log, stdout, "", "  Memory allocated successfully\n");

    for (png_uint_32 i = 0; i < h; ++i)
    {
      writeLog(log, stdout, "", "  Setting individual row_pointers %s %d/%d\n",
        "to point at the correct offsets of data ...", i, h);
      png->row_pointers[h - 1 - i] = png->data + i * rowbytes;
    }
    writeLog(log, stdout, "", "  Setting individual row_pointers %s %d/%d\n",
      "to point at the correct offsets of data ...", h, h);
    writeLog(log, stdout, "", "  Individual row_pointers set\n");

    writeLog(log, stdout, "", "  Reading PNG image into memory ...\n");
    png_read_image(png->ptr, png->row_pointers);
    writeLog(log, stdout, "", "  PNG image read into memory\n");

    writeLog(log, stdout, "", "  Finishing PNG reading ...\n");
    png_read_end(png->ptr, NULL);
    writeLog(log, stdout, "", "  PNG reading finished\n");

    writeLog(log, stdout, "", "  Generating OpenGL texture ...\n");
    GL_CHECK(glGenTextures(1, &(png->texture)), status, log);
    writeLog(log, stdout, "", "  OpenGL texture is %d\n", png->texture);

    writeLog(log, stdout, "", "  Activating OpenGL texture ...\n");
    GL_CHECK(glActiveTexture(GL_TEXTURE0 + png->texture_unit), status, log);
    writeLog(log, stdout, "", "  OpenGL texture activated\n");

    writeLog(log, stdout, "", "  Binding OpenGL texture ...\n");
    GL_CHECK(glBindTexture(GL_TEXTURE_2D, png->texture), status, log);
    writeLog(log, stdout, "", "  OpenGL texture binded\n");

    writeLog(log, stdout, "", "  Setting texture unit to use ...\n");
    GL_CHECK(glUniform1i(glGetUniformLocation(shaders->program,
      "bigstars_texture"), png->texture_unit), status, log);
    writeLog(log, stdout, "", "  Texture unit ready to use\n");

    GLenum texture_format =
      (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;

    writeLog(log, stdout, "", "  Specifying 2D OpenGL texture ...\n");
    GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h,
      0, texture_format, GL_UNSIGNED_BYTE, png->data), status, log);
    writeLog(log, stdout, "", "  2D OpenGL texture specified\n");

    writeLog(log, stdout, "", "  Disabling OpenGL Texture repetition ...\n");
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
      GL_CLAMP_TO_BORDER), status, log);
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
      GL_CLAMP_TO_BORDER), status, log);
    writeLog(log, stdout, "", "  OpenGL texture repetition disabled\n");

    writeLog(log, stdout, "", "  Specifying texture element value to the %s",
      "nearest texture coordinates ...\n");
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST), status, log);
    GL_CHECK(glTexParameteri(
      GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST), status, log);
    writeLog(log, stdout, "", "  Texture element value specified ...\n");
  } while (false);

  return status;
}

bool freePng(PNG* png, Log* log)
{
  int status = true;

  if (png->path)
  {
    writeLog(log, stdout, "", "Freeing texture path ...\n");
    free(png->path);
    png->path = NULL;
    writeLog(log, stdout, "", "Texture path freed\n");
  }

  if (png->ptr)
  {
    writeLog(log, stdout, "",
      "Destroying PNG read struct and PNG info struct ...\n");
    png_destroy_read_struct(&(png->ptr), png->info ? &(png->info) : 0, 0);
    png->ptr = 0;
    png->info = 0;
    writeLog(log, stdout, "",
      "PNG read struct and PNG info struct destroyed\n");
  }

  if (png->row_pointers)
  {
    writeLog(log, stdout, "", "Freeing PNG row_pointers ...\n");
    free(png->row_pointers);
    png->row_pointers = NULL;
    writeLog(log, stdout, "", "PNG row_pointers freed\n");
  }

  if (png->data)
  {
    writeLog(log, stdout, "", "Freeing PNG data ...\n");
    free(png->data);
    png->data = NULL;
    writeLog(log, stdout, "", "PNG data freed\n");
  }

  if (png->file)
  {
    writeLog(log, stdout, "", "Closing PNG file ...\n");
    fclose(png->file);
    png->file = NULL;
    writeLog(log, stdout, "", "PNG file closed\n");
  }

  do
  {
    if (png->texture)
    {
      writeLog(log, stdout, "", "Deleting OpenGL texture ...\n");
      GL_CHECK(glDeleteTextures(1, &(png->texture)), status, log);
      writeLog(log, stdout, "", "OpenGL texture deleted\n");
    }
  } while (false);

  return status;
}
