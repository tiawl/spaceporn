#include "util.h"

static Aggregate xtel;

void aggregateContext(Context* context)
{
  xtel.context = context;
}

void aggregateShaders(Shaders* shaders)
{
  xtel.shaders = shaders;
}

void aggregatePng(PNG* png)
{
  xtel.png = png;
}

void aggregateVertices(Vertices* vertices)
{
  xtel.vertices = vertices;
}

void aggregateVerbose(bool* verbose)
{
  xtel.verbose = verbose;
}

void aggregateRoadmap(Roadmap* roadmap)
{
  xtel.roadmap = roadmap;
}

void exitHandler()
{
  freePaths(xtel.shaders, xtel.png, *(xtel.verbose));
  freeVertices(xtel.vertices, *(xtel.verbose));
  freePng(xtel.png, *(xtel.verbose));
  freeProgram(xtel.shaders, *(xtel.verbose), xtel.roadmap);
  freeContext(xtel.context, *(xtel.verbose));
}

void checkOpenGLError(const char* stmt, const char* fname, int line)
{
  GLenum error = glGetError();
  if (error != GL_NO_ERROR)
  {
    fprintf(stderr, "OpenGL error %08x, at %s:%i - for %s\n", error, fname,
      line, stmt);
    atexit(exitHandler);
    exit(EXIT_FAILURE);
  }
}

void freeContext(Context* context, bool verbose)
{
  if (context->glx_context)
  {
    VERB(verbose, printf("Detaching current rendering context ...\n"));
    glXMakeCurrent(context->display, 0, 0);
    VERB(verbose, printf("Current rendering context detached\n"));

    VERB(verbose, printf("Destroying detached rendering context ...\n"));
    glXDestroyContext(context->display, context->glx_context);
    VERB(verbose, printf("Detached rendering context destroyed\n"));
  }

#if DEBUG
  if (context->debug_window)
  {
    VERB(verbose, printf("Unmapping debug window ...\n"));
    XUnmapWindow(context->display, context->debug_window);
    VERB(verbose, printf("Debug window unmapped\n"));

    VERB(verbose, printf("Destroying debug window ...\n"));
    XDestroyWindow(context->display, context->debug_window);
    VERB(verbose, printf("Debug window destroyed\n"));
  }
#endif

  if (context->visual_info)
  {
    VERB(verbose, printf("Freeing current visual ...\n"));
    XFree(context->visual_info);
    VERB(verbose, printf("Current visual freed\n"));
  }

  if (context->cmap)
  {
    VERB(verbose, printf("Freeing colormap ...\n"));
    XFreeColormap(context->display, context->cmap);
    VERB(verbose, printf("Colormap freed\n"));
  }

  if (context->window)
  {
    VERB(verbose, printf("Unmapping current window ...\n"));
    XUnmapWindow(context->display, context->window);
    VERB(verbose, printf("Current window unmapped\n"));

    VERB(verbose, printf("Destroying current window ...\n"));
    XDestroyWindow(context->display, context->window);
    VERB(verbose, printf("Current window destroyed\n"));
  }

  if (context->display)
  {
    VERB(verbose, printf("Closing Display ...\n"));
    XCloseDisplay(context->display);
    VERB(verbose, printf("Display closed\n"));
  }
}

void freeProgram(Shaders* shaders, bool verbose, Roadmap* roadmap)
{
  if (shaders->vertex_file && (roadmap->id !=
    VERTEX_SHADER_COMPILATION_FAILED_RM) && (roadmap->id !=
    LINKING_PROGRAM_FAILED_RM))
  {
    VERB(verbose, printf("Freeing vertex file ...\n"));
    free(shaders->vertex_file);
    shaders->vertex_file = NULL;
    VERB(verbose, printf("Vertex file freed\n"));
  }

  if (shaders->fragment_file && (roadmap->id !=
    FRAGMENT_SHADER_COMPILATION_FAILED_RM))
  {
    VERB(verbose, printf("Freeing fragment file ...\n"));
    free(shaders->fragment_file);
    shaders->fragment_file = NULL;
    VERB(verbose, printf("Fragment file freed\n"));
  }

  if (shaders->vertex_shader)
  {
    VERB(verbose, printf("Deleting vertex shader ...\n"));
    GL_CHECK(glDeleteShader(shaders->vertex_shader));
    shaders->vertex_shader = 0;
    VERB(verbose, printf("Vertex shader deleted\n"));
  }

  if (shaders->fragment_shader)
  {
    VERB(verbose, printf("Deleting fragment shader ...\n"));
    GL_CHECK(glDeleteShader(shaders->fragment_shader));
    shaders->fragment_shader = 0;
    VERB(verbose, printf("Fragment shader deleted\n"));
  }

  if (shaders->program)
  {
    VERB(verbose, printf("Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(shaders->program));
    shaders->program = 0;
    VERB(verbose, printf("OpenGL program deleted\n"));
  }
}

void freePng(PNG* png, bool verbose)
{
  if(png->parser)
  {
    VERB(verbose, printf("Destroying png_read_struct ...\n"));
    png_destroy_read_struct(&(png->parser), png->info ? &(png->info) : 0, 0);
    png->parser = 0;
    VERB(verbose, printf("png_read_struct destroyed\n"));
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

void freeVertices(Vertices* vertices, bool verbose)
{
  if (vertices->array)
  {
    VERB(verbose, printf("Disabling vertex attribute array ...\n"));
    GL_CHECK(glDisableVertexAttribArray(0));
    VERB(verbose, printf("Vertex attribute array disabled\n"));
  }

  if (vertices->buffer)
  {
    VERB(verbose, printf("Deleting vertex buffer object ...\n"));
    GL_CHECK(glDeleteBuffers(1, &(vertices->buffer)));
    VERB(verbose, printf("Vertex buffer object deleted\n"));
  }

  if (vertices->array)
  {
    VERB(verbose, printf("Deleting vertex array object ...\n"));
    GL_CHECK(glDeleteVertexArrays(1, &(vertices->array)));
    VERB(verbose, printf("Vertex array object deleted\n"));
  }
}

void freePaths(Shaders* shaders, PNG* png, bool verbose)
{
  if (shaders->fshaderpath)
  {
    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(shaders->fshaderpath);
    shaders->fshaderpath = NULL;
    VERB(verbose, printf("fshaderpath freed\n"));
  }

  if (shaders->vshaderpath)
  {
    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(shaders->vshaderpath);
    shaders->vshaderpath = NULL;
    VERB(verbose, printf("vshaderpath freed\n"));
  }

  if (png->path)
  {
    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(png->path);
    png->path = NULL;
    VERB(verbose, printf("texturepath freed\n"));
  }
}
