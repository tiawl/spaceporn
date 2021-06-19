#include "xshader.h"
#include "context.h"

#define NAME "xtelesktop"
#define VERSION "0.1"

void help()
{
  fprintf(stderr, "%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-c] [-m] [-p PIXELS] [-fps FRAMES]\n",
    NAME);
  fprintf(stderr, "Options:\n\
            -a      - Enable shader animations\n\
            -c      - Enable camera motion\n\
            -m      - Enable multiple colorschemes\n\
            -p      - Pixels value between 200 to 600 (ex: -p 300)\n\
                      default: 500\n\
            -fps    - Frames value between 1 to 60 (ex: -fps 30)\n");
}

int main(int argc, char **argv)
{
  srand(time(NULL));

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
    exit(EXIT_FAILURE);
  }

  GLuint uniformIds[UNIFORM_COUNT];

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  uniform_values.clock = clock();
  uniform_values.width = builder.window_attribs.width;
  uniform_values.height = builder.window_attribs.height;
  uniform_values.pixels = 500;
  uniform_values.animations = false;
  uniform_values.motion = false;
  uniform_values.palettes = false;
  uniform_values.xseed = rand();
  uniform_values.yseed = rand();

  int fps = 60;

  for (int i = 1; i < argc; i++)
  {
    if (strcmp(argv[i], "-p") == 0)
    {
      if (++i < argc)
      {
        uniform_values.pixels = atof(argv[i]);
        if ((uniform_values.pixels > 600.) || (uniform_values.pixels < 200.))
        {
          help();
          exit(EXIT_FAILURE);
        }
      }
    } else if (strcmp(argv[i], "-fps") == 0) {
      if (++i < argc)
      {
        fps = atoi(argv[i]);
        if ((fps > 60) || (fps < 1))
        {
          help();
          exit(EXIT_FAILURE);
        }
      }
    } else if (strcmp(argv[i], "-a") == 0) {
      uniform_values.animations = true;
    } else if (strcmp(argv[i], "-c") == 0) {
      uniform_values.motion = true;
    } else if (strcmp(argv[i], "-m") == 0) {
      uniform_values.palettes = true;
    } else {
      help();
      exit(EXIT_FAILURE);
    }
  }

  loadPng(&uniform_values.tex, texturepath);

  getUniforms(uniformIds, &program);

  GL_CHECK(glUseProgram(program));

  GL_CHECK(glViewport(0, 0, builder.window_attribs.width,
    builder.window_attribs.height));

  initVertices();

  XEvent event;

  while(true)
  {
    updateUniforms(uniformIds, &uniform_values);

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
