#include "vertex.h"

bool initVertices(Vertices* vertices, Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "  Generating vertex array object ...\n");
    GL_CHECK(glGenVertexArrays(1, &(vertices->array)), status, log);
    writeLog(log, stdout, "", "  Vertex array object generated is %d\n",
      vertices->array);

    writeLog(log, stdout, "", "  Binding vertex array object ...\n");
    GL_CHECK(glBindVertexArray(vertices->array), status, log);
    writeLog(log, stdout, "", "  Vertex array object binded\n");

    const GLfloat g_vertex_buffer_data[] =
    {
      -1.0f, -1.0f,
       1.0f, -1.0f,
      -1.0f,  1.0f,
       1.0f,  1.0f
    };

    writeLog(log, stdout, "", "  Generating vertex buffer object ...\n");
    GL_CHECK(glGenBuffers(1, &(vertices->buffer)), status, log);
    writeLog(log, stdout, "", "  Vertex buffer object generated is %d\n",
      vertices->buffer);

    writeLog(log, stdout, "", "  Binding vertex buffer object ...\n");
    GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, vertices->buffer), status, log);
    writeLog(log, stdout, "", "  Vertex buffer object binded\n");

    writeLog(log, stdout, "",
      "  Initializing vertex buffer object's data store ...\n");
    GL_CHECK(glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data),
      g_vertex_buffer_data, GL_STATIC_DRAW), status, log);
    writeLog(log, stdout, "",
      "  Vertex buffer object's data store initialized\n");

    writeLog(log, stdout, "", "  Enabling vertex attribute array ...\n");
    GL_CHECK(glEnableVertexAttribArray(0), status, log);
    writeLog(log, stdout, "", "  Vertex attribute array enabled\n");

    writeLog(log, stdout, "",
      "  Defining array of vertex attribute data ...\n");
    GL_CHECK(glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0),
      status, log);
    writeLog(log, stdout, "", "  Array of vertex attribute data defined\n");
  } while (false);

  return status;
}

bool draw(Log* log)
{
  bool status = true;

  do
  {
    writeLog(log, stdout, "", "  Clearing depth buffer of the window and %s",
      "indicating buffers enabled for color writing ...\n");
    GL_CHECK(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
      | GL_STENCIL_BUFFER_BIT), status, log);
    writeLog(log, stdout, "", "  Depth buffer cleared and buffer enabled\n");

    writeLog(log, stdout, "",
      "  Clearing color buffer of the window to black color ...\n");
    GL_CHECK(glClearColor(0.0, 0.0, 0.0, 0.0), status, log);
    writeLog(log, stdout, "", "  Color buffer cleared\n");

    writeLog(log, stdout, "", "  Rendering primitives ...\n");
    GL_CHECK(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4), status, log);
    writeLog(log, stdout, "", "  Primitives rendered\n");
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
      writeLog(log, stdout, "", "Disabling vertex attribute array ...\n");
      GL_CHECK(glDisableVertexAttribArray(0), status, log);
      writeLog(log, stdout, "", "Vertex attribute array disabled\n");
    }
  } while (false);

  do
  {
    if (vertices->buffer)
    {
      writeLog(log, stdout, "", "Deleting vertex buffer object ...\n");
      GL_CHECK(glDeleteBuffers(1, &(vertices->buffer)), status, log);
      writeLog(log, stdout, "", "Vertex buffer object deleted\n");
    }
  } while (false);

  do
  {
    if (vertices->array)
    {
      writeLog(log, stdout, "", "Deleting vertex array object ...\n");
      GL_CHECK(glDeleteVertexArrays(1, &(vertices->array)), status, log);
      writeLog(log, stdout, "", "Vertex array object deleted\n");
    }
  } while (false);

  return status;
}
