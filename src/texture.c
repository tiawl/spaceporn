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

    LOG(verbose, printf("  Opening PNG file \"%s\"...\n", png->path));
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
      png->parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
    }

    if (!png->parser)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "png_create_read_struct() failed\n");
      status = false;
      break;
    }
    LOG(verbose, printf("  Structure for reading PNG file created\n"));

    LOG(verbose, printf("  Creating PNG info structure ...\n"));
    if (roadmap->id != PNGCREATEINFOSTRUCT_FAILED_RM)
    {
      png->info = png_create_info_struct(png->parser);
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
    if (setjmp(png_jmpbuf(png->parser)) ||
      (roadmap->id == PNG_JMPBUF_FAILED_RM))
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr),
        "Routine problem: libPNG encountered an error\n");
      status = false;
      break;
    }
    LOG(verbose, printf("  No error found\n"));

    LOG(verbose, printf("  Initializing PNG input/output ...\n"));
    png_init_io(png->parser, png->file);
    LOG(verbose, printf("  PNG input/output initialized\n"));

    LOG(verbose, printf("  Reading PNG info ...\n"));
    png_read_info(png->parser, png->info);
    LOG(verbose, printf("  PNG info read\n"));

    LOG(verbose, printf("  Querying PNG_IHDR chunk information from PNG info \
structure ...\n"));
    png_get_IHDR(
      png->parser, png->info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
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
    png_read_update_info(png->parser, png->info);
    LOG(verbose, printf("  PNG info structure updated\n"));

    LOG(verbose, printf("  Querying number of bytes for a row ...\n"));
    int rowbytes = png_get_rowbytes(png->parser, png->info);
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

    LOG(verbose, printf("  Allocating memory for row_pointers ...\n"));
    if (roadmap->id != PNG_ROWPOINTERS_MALLOC_FAILED_RM)
    {
      png->row_pointers = malloc(h * sizeof(png_bytep));
    }

    if (!png->row_pointers)
    {
      LOG(verbose, printf("  "));
      fprintf((verbose ? stdout : stderr), "row_pointers malloc() failed\n");
      status = false;
      break;
    }
    LOG(verbose, printf("  Memory allocated successfully\n"));

    for(png_uint_32 i = 0; i < h; ++i)
    {
      LOG(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", i, h));
      png->row_pointers[h - 1 - i] = png->data + i * rowbytes;
    }
    LOG(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", h, h));
    LOG(verbose, printf("  Individual row_pointers set\n"));

    LOG(verbose, printf("  Reading PNG image into memory ...\n"));
    png_read_image(png->parser, png->row_pointers);
    LOG(verbose, printf("  PNG image read into memory\n"));

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

bool freePng(PNG* png, bool verbose)
{
  int status = true;

  if(png->parser)
  {
    LOG(verbose, printf("Destroying png_read_struct ...\n"));
    png_destroy_read_struct(&(png->parser), png->info ? &(png->info) : 0, 0);
    png->parser = 0;
    LOG(verbose, printf("png_read_struct destroyed\n"));
  }

  if(png->row_pointers)
  {
    LOG(verbose, printf("Freeing row_pointers ...\n"));
    free(png->row_pointers);
    png->row_pointers = NULL;
    LOG(verbose, printf("row_pointers freed\n"));
  }

  if(png->data)
  {
    LOG(verbose, printf("Freeing PNG data ...\n"));
    free(png->data);
    png->data = NULL;
    LOG(verbose, printf("PNG data freed\n"));
  }

  if(png->file)
  {
    LOG(verbose, printf("Closing PNG file ...\n"));
    fclose(png->file);
    png->file = NULL;
    LOG(verbose, printf("PNG file closed\n"));
  }

  do
  {
    if (png->texture)
    {
      LOG(verbose, printf("Deleting OpenGL texture ...\n"));
      GL_CHECK(glDeleteTextures(1, &(png->texture)), status);
      LOG(verbose, printf("OpenGL texture deleted\n"));
    }
  } while (false);

  return status;
}
