#include "pngtexture.h"

void cleanup(png_structp* parser, png_infop* info, png_bytep** row_pointers,
  uint8_t** data, FILE** file, char const * const filename, bool verbose)
{
  if(*parser)
  {
    VERB(verbose, printf("  Destroying png_read_struct ...\n"));
    png_destroy_read_struct(parser, *info ? info : 0, 0);
    VERB(verbose, printf("  png_read_struct destroyed \n"));
  }

  if(*row_pointers)
  {
    VERB(verbose, printf("  Freeing row_pointers ...\n"));
    free(*row_pointers);
    VERB(verbose, printf("  row_pointers freed\n"));
  }

  if(*data)
  {
    VERB(verbose, printf("  Freeing PNG data ...\n"));
    free(*data);
    VERB(verbose, printf("  PNG data freed\n"));
  }

  if(*file)
  {
    VERB(verbose, printf("  Closing PNG file ...\n"));
    fclose(*file);
    VERB(verbose, printf("  PNG file closed\n"));
  }
}

bool loadPng(GLuint* texture, char const* const filename, bool verbose,
  enum Roadmap roadmap)
{
  FILE* file = NULL;
  uint8_t* data = NULL;
  png_structp parser = 0;
  png_infop info = 0;
  png_bytep* row_pointers = NULL;

  png_uint_32 w, h;
  int bit_depth;
  int color_type;

  if (!filename || (roadmap == NO_PNG_FILENAME_RM))
  {
    fprintf(stderr, "  PNG filename is null\n");
    return false;
  }

  VERB(verbose, printf("  Opening PNG file \"%s\"...\n", filename));
  if (roadmap != FOPEN_PNG_FILE_FAILED_RM)
  {
    file = fopen(filename, "rb");
  }

  if (!file)
  {
    fprintf(stderr, "  Failed to open \"%s\"\n", filename);
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  PNG file opened\n"));

  VERB(verbose, printf("  Creating structure for reading PNG file ...\n"));
  if (roadmap != PNGCREATEREADSTRUCT_FAILED_RM)
  {
    parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
  }

  if (!parser)
  {
    fprintf(stderr, "  png_create_read_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  Structure for reading PNG file created\n"));

  VERB(verbose, printf("  Creating PNG info structure ...\n"));
  if (roadmap != PNGCREATEINFOSTRUCT_FAILED_RM)
  {
    info = png_create_info_struct(parser);
  }

  if (!info)
  {
    fprintf(stderr, "  png_create_info_struct() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  PNG info structure created\n"));

  VERB(verbose, printf("  Searching libPNG error ...\n"));
  if (setjmp(png_jmpbuf(parser)))
  {
    fprintf(stderr, "Routine problem: libPNG encountered an error\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  No error found\n"));

  VERB(verbose, printf("  Initializing PNG input/output ...\n"));
  png_init_io(parser, file);
  VERB(verbose, printf("  PNG input/output initialized\n"));

  VERB(verbose, printf("  Reading PNG info ...\n"));
  png_read_info(parser, info);
  VERB(verbose, printf("  PNG info read\n"));

  VERB(verbose, printf("  Querying PNG_IHDR chunk information from PNG info \
structure ...\n"));
  png_get_IHDR(parser, info, &w, &h, &bit_depth, &color_type, 0, 0, 0);
  VERB(verbose, printf("  PNG_IHDR chunk information found\n"));

  VERB(verbose, printf("  Testing PNG images dimensions ...\n"));
  if ((w & (w - 1)) || (h & (h - 1)) || (w < 8) || (h < 8))
  {
    fprintf(stderr, "PNG images with dimensions that are not power of two \
or smaller than 8 failed to load in OpenGL\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  Valid PNG images dimensions\n"));

  VERB(verbose, printf("  Testing validity of chunk data ...\n"));
  if (png_get_valid(parser, info, PNG_INFO_tRNS) ||
    (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) ||
    color_type == PNG_COLOR_TYPE_PALETTE)
  {
    VERB(verbose, printf("  Valid chunk data\n"));

    VERB(verbose, printf("  Setting expansion transformation ...\n"));
    png_set_expand(parser);
    VERB(verbose, printf("  Expansion transformation set\n"));
  } else {
    VERB(verbose, printf("  Unvalid chunk data\n"));
  }

  if (bit_depth == 16)
  {
    VERB(verbose, printf("  Striping 16 bit PNG file to 8 bit depth ...\n"));
    png_set_strip_16(parser);
    VERB(verbose, printf("  16 bit PNG file to 8 bit depth modification \
done\n"));
  }

  if (color_type == PNG_COLOR_TYPE_GRAY ||
    color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
  {
    VERB(verbose, printf("  Expanding grayscale image to 24-bit RGB ...\n"));
    png_set_gray_to_rgb(parser);
    VERB(verbose, printf("  Grayscale image expanded\n"));
  }

  VERB(verbose, printf("  Updating PNG info structure ...\n"));
  png_read_update_info(parser, info);
  VERB(verbose, printf("  PNG info structure updated\n"));

  VERB(verbose, printf("  Querying number of bytes for a row ...\n"));
  int rowbytes = png_get_rowbytes(parser, info);
  rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes
  VERB(verbose, printf("  Number of bytes for a row is %d\n", rowbytes));

  VERB(verbose, printf("  Allocating memory for data ...\n"));
  data = malloc(rowbytes * h * sizeof(png_byte) + 15);
  if (!data)
  {
    fprintf(stderr, "data malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  Memory allocated for data\n"));

  VERB(verbose, printf("  Allocating memory for row_pointers ...\n"));
  row_pointers = malloc(h * sizeof(png_bytep));
  if (!row_pointers)
  {
    fprintf(stderr, "row_pointers malloc() failed\n");
    cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
    return false;
  }
  VERB(verbose, printf("  Memory allocated for row_pointers\n"));

  for(png_uint_32 i = 0; i < h; ++i)
  {
    VERB(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", i, h));
    row_pointers[h - 1 - i] = data + i * rowbytes;
  }
  VERB(verbose, printf("  Setting individual row_pointers to point at the \
correct offsets of data ... %d/%d\n", h, h));
  VERB(verbose, printf("  Individual row_pointers set\n"));

  VERB(verbose, printf("  Reading PNG image into memory ...\n"));
  png_read_image(parser, row_pointers);
  VERB(verbose, printf("  PNG image read into memory\n"));

  VERB(verbose, printf("  Generating OpenGL texture ...\n"));
  GL_CHECK(glGenTextures(1, texture));
  VERB(verbose, printf("  OpenGL texture is %d\n", *texture));

  VERB(verbose, printf("  Binding OpenGL texture ...\n"));
  GL_CHECK(glBindTexture(GL_TEXTURE_2D, *texture));
  VERB(verbose, printf("  OpenGL texture binded\n"));

  GLenum texture_format =
    (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;

  VERB(verbose, printf("  Specifying 2D OpenGL texture ...\n"));
  GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h,
    0, texture_format, GL_UNSIGNED_BYTE, data));
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

  cleanup(&parser, &info, &row_pointers, &data, &file, filename, verbose);
  return true;
}
