#include "texture.h"

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
