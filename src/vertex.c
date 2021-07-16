#include "vertex.h"

void initVertices(Vertices* vertices, bool verbose)
{
  VERB(verbose, printf("  Generating vertex array object ...\n"));
  GL_CHECK(glGenVertexArrays(1, &(vertices->array)));
  VERB(verbose, printf("  Vertex array object generated is %d\n",
    vertices->array));

  VERB(verbose, printf("  Binding vertex array object ...\n"));
  GL_CHECK(glBindVertexArray(vertices->array));
  VERB(verbose, printf("  Vertex array object binded\n"));

  const GLfloat g_vertex_buffer_data[] =
  {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    1.0f, 1.0f
  };

  VERB(verbose, printf("  Generating vertex buffer object ...\n"));
  GL_CHECK(glGenBuffers(1, &(vertices->buffer)));
  VERB(verbose, printf("  Vertex buffer object generated is %d\n",
    vertices->buffer));

  VERB(verbose, printf("  Binding vertex buffer object ...\n"));
  GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, vertices->buffer));
  VERB(verbose, printf("  Vertex buffer object binded\n"));

  VERB(verbose, printf("  Initializing vertex buffer object's data store \
...\n"));
  GL_CHECK(glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data),
    g_vertex_buffer_data, GL_STATIC_DRAW));
  VERB(verbose, printf("  Vertex buffer object's data store initialized\n"));

  VERB(verbose, printf("  Enabling vertex attribute array ...\n"));
  GL_CHECK(glEnableVertexAttribArray(0));
  VERB(verbose, printf("  Vertex attribute array enabled\n"));

  VERB(verbose, printf("  Defining array of vertex attribute data ...\n"));
  GL_CHECK(glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0));
  VERB(verbose, printf("  Array of vertex attribute data defined\n"));
}

void draw(bool verbose)
{
  VERB(verbose, printf("  Clearing depth buffer of the window and indicating \
buffers enabled for color writing ...\n"));
  GL_CHECK(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT));
  VERB(verbose, printf("  Depth buffer cleared and buffer enabled\n"));

  VERB(verbose, printf("  Clearing color buffer of the window to black color \
...\n"));
  GL_CHECK(glClearColor(0.0, 0.0, 0.0, 0.0));
  VERB(verbose, printf("  Color buffer cleared\n"));

  VERB(verbose, printf("  Rendering primitives ...\n"));
  GL_CHECK(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4));
  VERB(verbose, printf("  Primitives rendered\n"));
}
