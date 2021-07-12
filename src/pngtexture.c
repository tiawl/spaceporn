#include "pngtexture.h"

void freePng(PNG* png, bool verbose)
{
  if(png->parser)
  {
    VERB(verbose, printf("Destroying png_read_struct ...\n"));
    png_destroy_read_struct(&(png->parser), png->info ? &(png->info) : 0, 0);
    png->parser = 0;
    VERB(verbose, printf("png_read_struct destroyed \n"));
  }

  if(png->row_pointers)
  {
    VERB(verbose, printf("Freeing row_pointers ...\n"));
    free(png->row_pointers);
    png->row_pointers = NULL;
    VERB(verbose, printf("row_pointers freed\n"));
  }

  if(png->data)
  {
    VERB(verbose, printf("Freeing PNG data ...\n"));
    free(png->data);
    png->data = NULL;
    VERB(verbose, printf("PNG data freed\n"));
  }

  if(png->file)
  {
    VERB(verbose, printf("Closing PNG file ...\n"));
    fclose(png->file);
    png->file = NULL;
    VERB(verbose, printf("PNG file closed\n"));
  }

  if (png->texture)
  {
    VERB(verbose, printf("Deleting OpenGL texture ...\n"));
    GL_CHECK(glDeleteTextures(1, &(png->texture)));
    VERB(verbose, printf("OpenGL texture deleted\n"));
  }
}

bool loadPng(PNG* png, bool verbose, enum Roadmap roadmap)
{
  png_uint_32 w, h;
  int bit_depth;
  int color_type;

  if (!png->path || (roadmap == NO_PNG_FILENAME_RM))
  {
    fprintf(stderr, "  PNG filename is null\n");
    return false;
  }

  VERB(verbose, printf("  Opening PNG file \"%s\"...\n", png->path));
  if (roadmap != FOPEN_PNG_FILE_FAILED_RM)
  {
    png->file = fopen(png->path, "rb");
  }

  if (!png->file)
  {
    fprintf(stderr, "  Failed to open \"%s\"\n", png->path);
    return false;
  }
  VERB(verbose, printf("  PNG file opened\n"));

  VERB(verbose, printf("  Creating structure for reading PNG file ...\n"));
  if (roadmap != PNGCREATEREADSTRUCT_FAILED_RM)
  {
    png->parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
  }

  if (!png->parser)
  {
    fprintf(stderr, "  png_create_read_struct() failed\n");
    return false;
  }
  VERB(verbose, printf("  Structure for reading PNG file created\n"));

  VERB(verbose, printf("  Creating PNG info structure ...\n"));
  if (roadmap != PNGCREATEINFOSTRUCT_FAILED_RM)
  {
    png->info = png_create_info_struct(png->parser);
  }

  if (!png->info)
  {
    fprintf(stderr, "  png_create_info_struct() failed\n");
    return false;
  }
  VERB(verbose, printf("  PNG info structure created\n"));

  VERB(verbose, printf("  Searching libPNG error ...\n"));
  if (setjmp(png_jmpbuf(png->parser)) ||
    (roadmap == PNG_JMPBUF_FAILED_RM))
  {
    fprintf(stderr, "  Routine problem: libPNG encountered an error\n");
    return false;
  }
  VERB(verbose, printf("  No error found\n"));

  VERB(verbose, printf("  Initializing PNG input/output ...\n"));
  png_init_io(png->parser, png->file);
  VERB(verbose, printf("  PNG input/output initialized\n"));

  VERB(verbose, printf("  Reading PNG info ...\n"));
  png_read_info(png->parser, png->info);
  VERB(verbose, printf("  PNG info read\n"));

  VERB(verbose, printf("  Querying PNG_IHDR chunk information from PNG info \
structure ...\n"));
  png_get_IHDR(
    png->parser, png->info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
  VERB(verbose, printf("  PNG_IHDR chunk information found\n"));

  if (roadmap == BAD_PNG_DIMENSIONS_RM)
  {
    w = 15;
  }

  VERB(verbose, printf("  Testing PNG images dimensions ...\n"));
  if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
  {
    fprintf(stderr, "  PNG images with dimensions that are not power of two \
or smaller than 8 failed to load in OpenGL\n");
    return false;
  }
  VERB(verbose, printf("  Valid PNG images dimensions\n"));

  VERB(verbose, printf("  Testing validity of chunk data ...\n"));
  if (png_get_valid(png->parser, png->info, PNG_INFO_tRNS) ||
    (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) ||
    color_type == PNG_COLOR_TYPE_PALETTE)
  {
    VERB(verbose, printf("  Valid chunk data\n"));

    VERB(verbose, printf("  Setting expansion transformation ...\n"));
    png_set_expand(png->parser);
    VERB(verbose, printf("  Expansion transformation set\n"));
  } else {
    VERB(verbose, printf("  Unvalid chunk data\n"));
  }

  if (bit_depth == 16)
  {
    VERB(verbose, printf("  Striping 16 bit PNG file to 8 bit depth ...\n"));
    png_set_strip_16(png->parser);
    VERB(verbose, printf("  16 bit PNG file to 8 bit depth modification \
done\n"));
  }

  if (color_type == PNG_COLOR_TYPE_GRAY ||
    color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
  {
    VERB(verbose, printf("  Expanding grayscale image to 24-bit RGB ...\n"));
    png_set_gray_to_rgb(png->parser);
    VERB(verbose, printf("  Grayscale image expanded\n"));
  }

  VERB(verbose, printf("  Updating PNG info structure ...\n"));
  png_read_update_info(png->parser, png->info);
  VERB(verbose, printf("  PNG info structure updated\n"));

  VERB(verbose, printf("  Querying number of bytes for a row ...\n"));
  int rowbytes = png_get_rowbytes(png->parser, png->info);
  rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes
  VERB(verbose, printf("  Number of bytes for a row is %d\n", rowbytes));

  VERB(verbose, printf("  Allocating memory for data ...\n"));
  if (roadmap != PNG_DATA_MALLOC_FAILED_RM)
  {
    png->data = malloc(rowbytes * h * sizeof(png_byte) + 15);
  }

  if (!png->data)
  {
    fprintf(stderr, "  data malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Memory allocated for data\n"));

  VERB(verbose, printf("  Allocating memory for row_pointers ...\n"));
  if (roadmap != PNG_ROWPOINTERS_MALLOC_FAILED_RM)
  {
    png->row_pointers = malloc(h * sizeof(png_bytep));
  }

  if (!png->row_pointers)
  {
    fprintf(stderr, "  row_pointers malloc() failed\n");
    return false;
  }
  VERB(verbose, printf("  Memory allocated for row_pointers\n"));

  for(png_uint_32 i = 0; i < h; ++i)
  {
    VERB(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", i, h));
    png->row_pointers[h - 1 - i] = png->data + i * rowbytes;
  }
  VERB(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", h, h));
  VERB(verbose, printf("  Individual row_pointers set\n"));

  VERB(verbose, printf("  Reading PNG image into memory ...\n"));
  png_read_image(png->parser, png->row_pointers);
  VERB(verbose, printf("  PNG image read into memory\n"));

  VERB(verbose, printf("  Generating OpenGL texture ...\n"));
  GL_CHECK(glGenTextures(1, &(png->texture)));
  VERB(verbose, printf("  OpenGL texture is %d\n", png->texture));

  VERB(verbose, printf("  Binding OpenGL texture ...\n"));
  GL_CHECK(glBindTexture(GL_TEXTURE_2D, png->texture));
  VERB(verbose, printf("  OpenGL texture binded\n"));

  GLenum texture_format =
    (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;

  VERB(verbose, printf("  Specifying 2D OpenGL texture ...\n"));
  GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h,
    0, texture_format, GL_UNSIGNED_BYTE, png->data));
  VERB(verbose, printf("  2D OpenGL texture specified\n"));

  VERB(verbose, printf("  Disabling OpenGL Texture repetition ...\n"));
  GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
    GL_CLAMP_TO_BORDER));
  GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
    GL_CLAMP_TO_BORDER));
  VERB(verbose, printf("  OpenGL texture repetition disabled\n"));

  VERB(verbose, printf("  Specifying texture element value to the nearest \
texture coordinates ...\n"));
  GL_CHECK(glTexParameteri(
    GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST));
  GL_CHECK(glTexParameteri(
    GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
  VERB(verbose, printf("  Texture element value specified ...\n"));

  return true;
}
