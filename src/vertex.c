#include "vertex.h"

bool initVertices(Vertices* vertices, Log* log)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Generating vertex array object ...\n"));
    GL_CHECK(glGenVertexArrays(1, &(vertices->array)), status);
    LOG(verbose, printf("  Vertex array object generated is %d\n",
      vertices->array));

    LOG(verbose, printf("  Binding vertex array object ...\n"));
    GL_CHECK(glBindVertexArray(vertices->array), status);
    LOG(verbose, printf("  Vertex array object binded\n"));

    const GLfloat g_vertex_buffer_data[] =
    {
      -1.0f, -1.0f,
       1.0f, -1.0f,
      -1.0f,  1.0f,
       1.0f,  1.0f
    };

    LOG(verbose, printf("  Generating vertex buffer object ...\n"));
    GL_CHECK(glGenBuffers(1, &(vertices->buffer)), status);
    LOG(verbose, printf("  Vertex buffer object generated is %d\n",
      vertices->buffer));

    LOG(verbose, printf("  Binding vertex buffer object ...\n"));
    GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, vertices->buffer), status);
    LOG(verbose, printf("  Vertex buffer object binded\n"));

    LOG(verbose, printf("  Initializing vertex buffer object's data store \
...\n"));
    GL_CHECK(glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data),
      g_vertex_buffer_data, GL_STATIC_DRAW), status);
    LOG(verbose, printf("  Vertex buffer object's data store initialized\n"));

    LOG(verbose, printf("  Enabling vertex attribute array ...\n"));
    GL_CHECK(glEnableVertexAttribArray(0), status);
    LOG(verbose, printf("  Vertex attribute array enabled\n"));

    LOG(verbose, printf("  Defining array of vertex attribute data ...\n"));
    GL_CHECK(glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0),
      status);
    LOG(verbose, printf("  Array of vertex attribute data defined\n"));
  } while (false);

  return status;
}

bool draw(Log* log)
{
  bool status = true;

  do
  {
    LOG(verbose, printf("  Clearing depth buffer of the window and indicating \
buffers enabled for color writing ...\n"));
    GL_CHECK(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT), status);
    LOG(verbose, printf("  Depth buffer cleared and buffer enabled\n"));

    LOG(verbose, printf("  Clearing color buffer of the window to black color \
  ...\n"));
    GL_CHECK(glClearColor(0.0, 0.0, 0.0, 0.0), status);
    LOG(verbose, printf("  Color buffer cleared\n"));

    LOG(verbose, printf("  Rendering primitives ...\n"));
    GL_CHECK(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4), status);
    LOG(verbose, printf("  Primitives rendered\n"));
  } while (false);

  return status;
}

bool freeVertices(Vertices* vertices, Log* log)
{
  bool status = true;

  do
  {
    if (vertices->array)
    {
      LOG(verbose, printf("Disabling vertex attribute array ...\n"));
      GL_CHECK(glDisableVertexAttribArray(0), status);
      LOG(verbose, printf("Vertex attribute array disabled\n"));
    }
  } while (false);

  do
  {
    if (vertices->buffer)
    {
      LOG(verbose, printf("Deleting vertex buffer object ...\n"));
      GL_CHECK(glDeleteBuffers(1, &(vertices->buffer)), status);
      LOG(verbose, printf("Vertex buffer object deleted\n"));
    }
  } while (false);

  do
  {
    if (vertices->array)
    {
      LOG(verbose, printf("Deleting vertex array object ...\n"));
      GL_CHECK(glDeleteVertexArrays(1, &(vertices->array)), status);
      LOG(verbose, printf("Vertex array object deleted\n"));
    }
  } while (false);

  return status;
}
