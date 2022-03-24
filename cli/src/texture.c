#include "texture.h"

bool freePng(PNG* png, Log* log)
{
  int status = true;

  if (png->path)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing texture path ...\n");
    free(png->path);
    png->path = NULL;
    writeLog(log, stdout, DEBUG, "", "Texture path freed\n");
  }

  if (png->ptr)
  {
    writeLog(log, stdout, DEBUG, "",
      "Destroying PNG read struct and PNG info struct ...\n");
    png_destroy_read_struct(&(png->ptr), png->info ? &(png->info) : 0, 0);
    png->ptr = 0;
    png->info = 0;
    writeLog(log, stdout, DEBUG, "",
      "PNG read struct and PNG info struct destroyed\n");
  }

  if (png->row_pointers)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing PNG row_pointers ...\n");
    free(png->row_pointers);
    png->row_pointers = NULL;
    writeLog(log, stdout, DEBUG, "", "PNG row_pointers freed\n");
  }

  if (png->data)
  {
    writeLog(log, stdout, DEBUG, "", "Freeing PNG data ...\n");
    free(png->data);
    png->data = NULL;
    writeLog(log, stdout, DEBUG, "", "PNG data freed\n");
  }

  if (png->file)
  {
    writeLog(log, stdout, DEBUG, "", "Closing PNG file ...\n");
    fclose(png->file);
    png->file = NULL;
    writeLog(log, stdout, DEBUG, "", "PNG file closed\n");
  }

  do
  {
    if (png->texture)
    {
      writeLog(log, stdout, DEBUG, "", "Deleting OpenGL texture ...\n");
      GL_CHECK(glDeleteTextures(1, &(png->texture)), status, log);
      writeLog(log, stdout, DEBUG, "", "OpenGL texture deleted\n");
    }
  } while (false);

  return status;
}
