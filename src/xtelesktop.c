#include "xtelesktop.h"

void help()
{
  fprintf(stderr, "%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-m] [-p] [-x PIXELS] [-d MICROS]\n",
    NAME);
  fprintf(stderr, "Options:\n\
            -a      - Enable shader animations\n\
                      default: disabled\n\
            -m      - Enable camera motion\n\
                      default: disabled\n\
            -p      - Enable multiple colorschemes\n\
                      default: disabled\n\
            -x      - Pixels value between 100 to 600 (ex: -x 300)\n\
                      default: 500\n\
            -d      - Delay value between each frame in microseconds\n\
                      (ex: -d 0)\n\
                      default: 30000\n");
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

  if (!initPaths(&fshaderpath, &vshaderpath, &texturepath))
  {
    exit(EXIT_FAILURE);
  }

  ContextBuilder builder;
  builder.context = 0;

  if (!initContext(&builder))
  {
    free(fshaderpath);
    free(vshaderpath);
    free(texturepath);
    printf("Failed to create an OpenGL context\n");
    exit(EXIT_FAILURE);
  }

  glewExperimental = GL_TRUE;
  glewInit();

  XSelectInput(builder.display, builder.window, ExposureMask);

  GL_CHECK(glEnable(GL_BLEND));
  GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));

#ifdef _DEBUG
  Window debug_window = XCreateSimpleWindow(builder.display,
    RootWindow(builder.display, DefaultScreen(builder.display)), 0, 0, 1, 1,
    1, BlackPixel(builder.display, DefaultScreen(builder.display)),
    WhitePixel(builder.display, DefaultScreen(builder.display)));

  if (!debug_window)
  {
    free(fshaderpath);
    free(vshaderpath);
    free(texturepath);
    glXMakeCurrent(builder.display, 0, 0);
    glXDestroyContext(builder.display, builder.context);
    XDestroyWindow(builder.display, builder.window);
    XFreeColormap(builder.display, builder.cmap);
    XCloseDisplay(builder.display);
    printf("Failed to create debug window\n");
    exit(EXIT_FAILURE);
  }

  XSelectInput(builder.display, debug_window, KeyPressMask);
  XMapWindow(builder.display, debug_window);
#endif

  if (!loadProgram(&program, &vertex_shader, &vshaderpath, &fragment_shader,
    &fshaderpath))
  {
    free(fshaderpath);
    free(vshaderpath);
    free(texturepath);
    glXMakeCurrent(builder.display, 0, 0);
    glXDestroyContext(builder.display, builder.context);

#ifdef _DEBUG
    XDestroyWindow(builder.display, debug_window);
#endif

    XDestroyWindow(builder.display, builder.window);
    XFreeColormap(builder.display, builder.cmap);
    XCloseDisplay(builder.display);
    printf("\n\tShader program failed to load\n\n");
    exit(EXIT_FAILURE);
  }

  /* array of all uniforms to pass to the shader */
  const Uniform uniforms[] =
  {
    {"fflags", &updateFloatUniforms},
    {"bflags", &updateBoolUniforms},
  };

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

  int delay = DEFAULT_DELAY;
  bool help_needed = false;

  for (int i = 1; i < argc; i++)
  {
    if (strcmp(argv[i], "-x") == 0)
    {
      if (++i < argc)
      {
        uniform_values.pixels = atof(argv[i]);
        if ((uniform_values.pixels > 600.) || (uniform_values.pixels < 100.))
        {
          help();
          help_needed = true;
          break;
        }
      }
    } else if (strcmp(argv[i], "-d") == 0) {
      if (++i < argc)
      {
        delay = atoi(argv[i]);
        if (delay < 0)
        {
          help();
          help_needed = true;
          break;
        }
      }
    } else if (strcmp(argv[i], "-a") == 0) {
      uniform_values.animations = true;
    } else if (strcmp(argv[i], "-m") == 0) {
      uniform_values.motion = true;
    } else if (strcmp(argv[i], "-p") == 0) {
      uniform_values.palettes = true;
    } else {
      help();
      help_needed = true;
      break;
    }
  }

  if (help_needed)
  {
    free(fshaderpath);
    free(vshaderpath);
    free(texturepath);
    GL_CHECK(glDeleteProgram(program));
    glXMakeCurrent(builder.display, 0, 0);
    glXDestroyContext(builder.display, builder.context);

#ifdef _DEBUG
    XDestroyWindow(builder.display, debug_window);
#endif

    XDestroyWindow(builder.display, builder.window);
    XFreeColormap(builder.display, builder.cmap);
    XCloseDisplay(builder.display);
    exit(EXIT_FAILURE);
  }

  GLuint texture;
  if (!loadPng(&texture, texturepath))
  {
    free(fshaderpath);
    free(vshaderpath);
    free(texturepath);
    GL_CHECK(glDeleteProgram(program));
    glXMakeCurrent(builder.display, 0, 0);
    glXDestroyContext(builder.display, builder.context);

#ifdef _DEBUG
    XDestroyWindow(builder.display, debug_window);
#endif

    XDestroyWindow(builder.display, builder.window);
    XFreeColormap(builder.display, builder.cmap);
    XCloseDisplay(builder.display);
    exit(EXIT_FAILURE);
  }

  getUniforms(uniforms, uniformIds, &program);

  GL_CHECK(glUseProgram(program));

  GL_CHECK(glViewport(0, 0, builder.window_attribs.width,
    builder.window_attribs.height));

  GLuint vertexarray;
  GLuint vertexbuffer;
  initVertices(&vertexbuffer, &vertexarray);

  XEvent event;

  while(true)
  {
    updateUniforms(uniforms, uniformIds, &uniform_values);

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

    usleep(delay);
  }

  GL_CHECK(glDisableVertexAttribArray(0));

  free(fshaderpath);
  free(vshaderpath);
  free(texturepath);
  GL_CHECK(glDeleteBuffers(1, &vertexbuffer));
  GL_CHECK(glDeleteVertexArrays(1, &vertexarray));
  GL_CHECK(glDeleteTextures(1, &texture));
  GL_CHECK(glDeleteProgram(program));

  glXMakeCurrent(builder.display, 0, 0);
  glXDestroyContext(builder.display, builder.context);

#ifdef _DEBUG
  XDestroyWindow(builder.display, debug_window);
#endif

  XDestroyWindow(builder.display, builder.window);
  XFreeColormap(builder.display, builder.cmap);
  XCloseDisplay(builder.display);

  return EXIT_SUCCESS;
}
