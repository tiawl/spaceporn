#include "xshader.h"
#include "context.h"

int main()
{
  char* fshaderpath = NULL;
  char* vshaderpath = NULL;
  char* texturepath = NULL;
  GLuint vertex_shader;
  GLuint fragment_shader;
  GLuint program;

  initPaths(&fshaderpath, &vshaderpath, &texturepath);

  ContextBuilder builder;
  builder.context = 0;

  initContext(&builder);

  glewExperimental = GL_TRUE;
  glewInit();

  XSelectInput(builder.display, builder.window, ExposureMask);

  GL_CHECK(glEnable(GL_BLEND));
  GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));

#ifdef _DEBUG
  Window event_window = XCreateSimpleWindow(builder.display,
    RootWindow(builder.display, DefaultScreen(builder.display)), 0, 0, 1, 1,
    1, BlackPixel(builder.display, DefaultScreen(builder.display)),
    WhitePixel(builder.display, DefaultScreen(builder.display)));
  XSelectInput(builder.display, event_window, KeyPressMask);
  XMapWindow(builder.display, event_window);
#endif

  if (!loadProgram(&program, &vertex_shader, &vshaderpath, &fragment_shader,
    &fshaderpath))
  {
    printf("\n\tshader program failed to load\n\n");
    exit(0);
  }

  GLuint uniformIds[UNIFORM_COUNT];

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  uniform_values.clock = clock();
  uniform_values.width = builder.window_attribs.width;
  uniform_values.height = builder.window_attribs.height;

  loadPng(&uniform_values.tex, texturepath);

  getUniforms(uniformIds, &program);

  GL_CHECK(glUseProgram(program));

  GL_CHECK(glViewport(0, 0, builder.window_attribs.width,
                      builder.window_attribs.height));

  initVertices();

  XEvent event;

  while(true)
  {
    setUniforms(uniformIds, &uniform_values);

    drawScreen();

    glXSwapBuffers(builder.display, builder.window);

#ifdef _DEBUG
#define ESCAPE 0x09
    if (XCheckMaskEvent(builder.display, KeyPressMask, &event))
    {
      if (event.type == KeyPress)
      {
        if (event.xkey.keycode == ESCAPE)
        {
          break;
        }
      }
    }
#endif

    //usleep(DELAY);
  }

  GL_CHECK(glDisableVertexAttribArray(0));

  free(fshaderpath);
  free(vshaderpath);
  GL_CHECK(glDeleteTextures(1, &(uniform_values.tex.id)));
  GL_CHECK(glDeleteProgram(program));

  glXMakeCurrent(builder.display, 0, 0);
  glXDestroyContext(builder.display, builder.context);

#ifdef _DEBUG
  XDestroyWindow(builder.display, event_window);
#endif

  XDestroyWindow(builder.display, builder.window);
  XFreeColormap(builder.display, builder.cmap);
  XCloseDisplay(builder.display);

  return 0;
}
