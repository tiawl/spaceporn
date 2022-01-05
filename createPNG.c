#include <stdio.h>
#include <malloc.h>
#include <png.h>

int writeImage(char* filename, int width, int height);

int main(int argc, char *argv[])
{
  if (argc != 2) {
    fprintf(stderr, "Please specify output file\n");
    return 1;
  }
  int width = 5;
  int height = 5;

  int result = writeImage(argv[1], width, height);

  return result;
}


int writeImage(char* filename, int width, int height)
{
  int code = 0;
  FILE *fp = NULL;
  png_structp png_ptr = NULL;
  png_infop info_ptr = NULL;
  png_byte** row_ptrs = NULL;
  uvec4 u;

  do
  {
    row_ptrs = (png_byte**)malloc(sizeof(png_byte*) * height);
    if (!row_ptrs)
    {
      printf("Allocation failed\n");
      break;
    }
    for (int i = 0; i < height; i++)
    {
      row_ptrs[i] = (png_byte*) malloc(4 * width);
      if (!row_ptrs[i])
      {
        printf("Allocation failed\n");
        break;
      }
    }
    // fill image with color
    for (int y = 0; y < height; y++)
    {
      for (int x = 0; x < width * 4; x += 4)
      {
        u.x = x / 4;
        u.y = y;
        u.z = 0;
        u.w = 0;
        pcg4d(&u);
        row_ptrs[height - 1 - y][x] = (((double) u.x) / (double) UINT_MAX) * 255.;
        row_ptrs[height - 1 - y][x + 1] = (((double) u.y) / (double) UINT_MAX) * 255.;
        row_ptrs[height - 1 - y][x + 2] = (((double) u.z) / (double) UINT_MAX) * 255.;
        row_ptrs[height - 1 - y][x + 3] = (((double) u.w) / (double) UINT_MAX) * 255.;
      }
    }

    // Open file for writing (binary mode)
    fp = fopen(filename, "wb");
    if (fp == NULL) {
      fprintf(stderr, "Could not open file %s for writing\n", filename);
      code = 1;
      break;
    }

    // Initialize write structure
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL) {
      fprintf(stderr, "Could not allocate write struct\n");
      code = 1;
      break;
    }

    // Initialize info structure
    info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr == NULL) {
      fprintf(stderr, "Could not allocate info struct\n");
      code = 1;
      break;
    }

    // Setup Exception handling
    if (setjmp(png_jmpbuf(png_ptr))) {
      fprintf(stderr, "Error during png creation\n");
      code = 1;
      break;
    }

    png_init_io(png_ptr, fp);

    png_set_IHDR(png_ptr, info_ptr, width, height,
        8, PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE,
        PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);

    png_write_info(png_ptr, info_ptr);
    png_write_image(png_ptr, row_ptrs);
    png_write_end(png_ptr, NULL);
  } while(0);

  if (fp != NULL) fclose(fp);
  if (info_ptr != NULL) png_free_data(png_ptr, info_ptr, PNG_FREE_ALL, -1);
  if (png_ptr != NULL) png_destroy_write_struct(&png_ptr, (png_infopp)NULL);

  for (int i = 0; i < height; i++)
  {
    if (row_ptrs[i])
    {
      free(row_ptrs[i]);
    }
  }
  if (row_ptrs)
  {
    free(row_ptrs);
  }

  return code;
}
