#include "xtelesktop.h"

void help()
{
  fprintf(stderr, "\n%s v%s\n", NAME, VERSION);
  fprintf(stderr, "\nUsage: %s [-a] [-m] [-p] [-x PIXELS] [-d MICROS]",
    NAME);

#if DEBUG
  fprintf(stderr, " [-R ROADMAP]");
#endif

  fprintf(stderr, "\n\n");

#if DEBUG
  fprintf(stderr, "User ");
#endif

  fprintf(stderr, "Options:\n\n\
    -a  Enable shader animations\n\n\
    -m  Enable camera motion\n\n\
    -p  Enable multiple colorschemes\n\n\
    -x  Pixels value between 100 to 600 (ex: -x 300) [default: 500]\n\n\
    -d  Delay value between each frame in microseconds (ex: -d 0)\n\
        [default: 30000]\n\n\
    -v  Verbose\n");

#if DEBUG
  fprintf(stderr, "\nDev Options:\n\n\
    -R  Run the corresponding predefined execution roadmap (ex: -R 0)\n\
        [default: 0]\n\n\
        ROADMAP values: - 0 -> Exit Success\n");
#endif

  fprintf(stderr, "\n");
}

int main(int argc, char **argv)
{
  srand(time(NULL));

  bool verbose = false;
  int delay = DEFAULT_DELAY;
  bool help_needed = false;

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  uniform_values.clock = clock();
  uniform_values.pixels = 500;
  uniform_values.animations = false;
  uniform_values.motion = false;
  uniform_values.palettes = false;
  uniform_values.xseed = rand();
  uniform_values.yseed = rand();

#if DEBUG
  int roadmap = EXIT_SUCCESS_RM;
#endif

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
    } else if (strcmp(argv[i], "-v") == 0) {
      verbose = true;
#if DEBUG
    } else if (strcmp(argv[i], "-R") == 0) {
      if (++i < argc)
      {
        roadmap = atoi(argv[i]);
        if ((roadmap < EXIT_SUCCESS_RM) || (roadmap > EXIT_FAILURE_RM))
        {
          help();
          help_needed = true;
          break;
        }
      }
#endif
    } else {
      help();
      help_needed = true;
      break;
    }
  }

  if (help_needed)
  {
    return EXIT_FAILURE;
  }

  char* fshaderpath = NULL;
  char* vshaderpath = NULL;
  char* texturepath = NULL;

  GLuint vertex_shader;
  GLuint fragment_shader;
  GLuint program;

  VERB(verbose, printf("Initializing fragment shader, vertex shader and \
texture paths ...\n"));
  if (!initPaths(&fshaderpath, &vshaderpath, &texturepath, verbose))
  {
    fprintf(stderr, "Failed to initialize fragment shader, vertex shader and \
texture paths\n");
    return EXIT_FAILURE;
  }
  VERB(verbose, printf("Fragment shader, vertex shader and texture paths \
are initialized\n"));

  ContextBuilder builder;
  builder.context = 0;

  VERB(verbose, printf("Creating OpenGL context ...\n"));
  if (!initContext(&builder, verbose))
  {
    fprintf(stderr, "Failed to create an OpenGL context\n");

    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("fshaderpath freed\n"));

    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(vshaderpath);
    VERB(verbose, printf("vshaderpath freed\n"));

    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(texturepath);
    VERB(verbose, printf("texturepath freed\n"));

    return EXIT_FAILURE;
  }
  VERB(verbose, printf("OpenGL context created\n"));

  VERB(verbose, printf("Initializing GLEW ...\n"));
  glewExperimental = GL_TRUE;

  if (glewInit())
  {
    fprintf(stderr, "glewInit() failed\n");

    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("fshaderpath freed\n"));

    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(vshaderpath);
    VERB(verbose, printf("vshaderpath freed\n"));

    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(texturepath);
    VERB(verbose, printf("texturepath freed\n"));

    VERB(verbose, printf("Detaching current rendering context ...\n"));
    glXMakeCurrent(builder.display, 0, 0);
    VERB(verbose, printf("Current rendering context detached\n"));

    VERB(verbose, printf("Destroying detached rendering context ...\n"));
    glXDestroyContext(builder.display, builder.context);
    VERB(verbose, printf("Detached rendering context destroyed\n"));

    VERB(verbose, printf("Destroying current window ...\n"));
    XDestroyWindow(builder.display, builder.window);
    VERB(verbose, printf("Current window destroyed\n"));

    VERB(verbose, printf("Freeing colormap ...\n"));
    XFreeColormap(builder.display, builder.cmap);
    VERB(verbose, printf("Colormap freed\n"));

    VERB(verbose, printf("Closing Display ...\n"));
    XCloseDisplay(builder.display);
    VERB(verbose, printf("Display closed\n"));

    return EXIT_FAILURE;
  }
  VERB(verbose, printf("GLEW initialized\n"));

  VERB(verbose, printf("Requesting X server to report exposure events for \
current window ...\n"));
  XSelectInput(builder.display, builder.window, ExposureMask);
  VERB(verbose, printf("X server is now reporting exposure events for \
current window\n"));

  VERB(verbose, printf("Enabling transparency for current window ...\n"));
  GL_CHECK(glEnable(GL_BLEND));
  VERB(verbose, printf("Transparency enabled for current window\n"));

  VERB(verbose, printf("Selecting transparency function for current \
window ...\n"));
  GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
  VERB(verbose, printf("Transparency function selected for current \
window\n"));

#if DEBUG
  VERB(verbose, printf("Creating a debug window to catch key press events \
...\n"));
  Window debug_window = XCreateSimpleWindow(builder.display,
    RootWindow(builder.display, DefaultScreen(builder.display)), 0, 0, 1, 1,
    1, BlackPixel(builder.display, DefaultScreen(builder.display)),
    WhitePixel(builder.display, DefaultScreen(builder.display)));

  if (!debug_window)
  {
    fprintf(stderr, "Failed to create debug window\n");

    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("fshaderpath freed\n"));

    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(vshaderpath);
    VERB(verbose, printf("vshaderpath freed\n"));

    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(texturepath);
    VERB(verbose, printf("texturepath freed\n"));

    VERB(verbose, printf("Detaching current rendering context ...\n"));
    glXMakeCurrent(builder.display, 0, 0);
    VERB(verbose, printf("Current rendering context detached\n"));

    VERB(verbose, printf("Destroying detached rendering context ...\n"));
    glXDestroyContext(builder.display, builder.context);
    VERB(verbose, printf("Detached rendering context destroyed\n"));

    VERB(verbose, printf("Destroying current window ...\n"));
    XDestroyWindow(builder.display, builder.window);
    VERB(verbose, printf("Current window destroyed\n"));

    VERB(verbose, printf("Freeing colormap ...\n"));
    XFreeColormap(builder.display, builder.cmap);
    VERB(verbose, printf("Colormap freed\n"));

    VERB(verbose, printf("Closing Display ...\n"));
    XCloseDisplay(builder.display);
    VERB(verbose, printf("Display closed\n"));

    return EXIT_FAILURE;
  }
  VERB(verbose, printf("Debug window created\n"));

  VERB(verbose, printf("Requesting X server to report key press events for \
debug window ...\n"));
  XSelectInput(builder.display, debug_window, KeyPressMask);
  VERB(verbose, printf("X server is now reporting key press events for debug \
window\n"));

  VERB(verbose, printf("Mapping debug window ...\n"));
  XMapWindow(builder.display, debug_window);
  VERB(verbose, printf("Debug window mapped\n"));
#endif

  VERB(verbose, printf("Loading OpenGL program ...\n"));
  if (!loadProgram(&program, &vertex_shader, &vshaderpath, &fragment_shader,
    &fshaderpath, verbose))
  {
    fprintf(stderr, "\n\tShader program failed to load\n\n");

    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("fshaderpath freed\n"));

    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(vshaderpath);
    VERB(verbose, printf("vshaderpath freed\n"));

    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(texturepath);
    VERB(verbose, printf("texturepath freed\n"));

    VERB(verbose, printf("Detaching current rendering context ...\n"));
    glXMakeCurrent(builder.display, 0, 0);
    VERB(verbose, printf("Current rendering context detached\n"));

    VERB(verbose, printf("Destroying detached rendering context ...\n"));
    glXDestroyContext(builder.display, builder.context);
    VERB(verbose, printf("Detached rendering context destroyed\n"));

#if DEBUG
    VERB(verbose, printf("Destroying debug window ...\n"));
    XDestroyWindow(builder.display, debug_window);
    VERB(verbose, printf("Debug window destroyed\n"));
#endif

    VERB(verbose, printf("Destroying current window ...\n"));
    XDestroyWindow(builder.display, builder.window);
    VERB(verbose, printf("Current window destroyed\n"));

    VERB(verbose, printf("Freeing colormap ...\n"));
    XFreeColormap(builder.display, builder.cmap);
    VERB(verbose, printf("Colormap freed\n"));

    VERB(verbose, printf("Closing Display ...\n"));
    XCloseDisplay(builder.display);
    VERB(verbose, printf("Display closed\n"));

    return EXIT_FAILURE;
  }
  VERB(verbose, printf("OpenGL program loaded\n"));

  /* array of all uniforms to pass to the shader */
  const Uniform uniforms[] =
  {
    {"fflags", &updateFloatUniforms},
    {"bflags", &updateBoolUniforms},
  };

  GLuint uniformIds[UNIFORM_COUNT];

  uniform_values.width = builder.window_attribs.width;
  uniform_values.height = builder.window_attribs.height;

  VERB(verbose, printf("Loading PNG texture ...\n"));
  GLuint texture;
  if (!loadPng(&texture, texturepath, verbose))
  {
    fprintf(stderr, "Failed to load PNG file %s\n", texturepath);

    VERB(verbose, printf("Freeing fshaderpath ...\n"));
    free(fshaderpath);
    VERB(verbose, printf("fshaderpath freed\n"));

    VERB(verbose, printf("Freeing vshaderpath ...\n"));
    free(vshaderpath);
    VERB(verbose, printf("vshaderpath freed\n"));

    VERB(verbose, printf("Freeing texturepath ...\n"));
    free(texturepath);
    VERB(verbose, printf("texturepath freed\n"));

    VERB(verbose, printf("Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(program));
    VERB(verbose, printf("OpenGL program deleted\n"));

    VERB(verbose, printf("Detaching current rendering context ...\n"));
    glXMakeCurrent(builder.display, 0, 0);
    VERB(verbose, printf("Current rendering context detached\n"));

    VERB(verbose, printf("Destroying detached rendering context ...\n"));
    glXDestroyContext(builder.display, builder.context);
    VERB(verbose, printf("Detached rendering context destroyed\n"));

#if DEBUG
    VERB(verbose, printf("Destroying debug window ...\n"));
    XDestroyWindow(builder.display, debug_window);
    VERB(verbose, printf("Debug window destroyed\n"));
#endif

    VERB(verbose, printf("Destroying current window ...\n"));
    XDestroyWindow(builder.display, builder.window);
    VERB(verbose, printf("Current window destroyed\n"));

    VERB(verbose, printf("Freeing colormap ...\n"));
    XFreeColormap(builder.display, builder.cmap);
    VERB(verbose, printf("Colormap freed\n"));

    VERB(verbose, printf("Closing Display ...\n"));
    XCloseDisplay(builder.display);
    VERB(verbose, printf("Display closed\n"));

    return EXIT_FAILURE;
  }
  VERB(verbose, printf("PNG texture loaded\n"));

  VERB(verbose, printf("Searching uniforms location ...\n"));
  getUniforms(uniforms, uniformIds, &program, verbose);
  VERB(verbose, printf("Uniforms location found\n"));

  VERB(verbose, printf("Installing OpenGL program as part of current \
rendering state...\n"));
  GL_CHECK(glUseProgram(program));
  VERB(verbose, printf("OpenGL program installed\n"));

  VERB(verbose, printf("Specifying viewport ...\n"));
  GL_CHECK(glViewport(0, 0, builder.window_attribs.width,
    builder.window_attribs.height));
  VERB(verbose, printf("Viewport specified\n"));

  GLuint vertexarray;
  GLuint vertexbuffer;

  VERB(verbose, printf("Initializing vertex buffer object and vertex array \
object ...\n"));
  initVertices(&vertexbuffer, &vertexarray, verbose);
  VERB(verbose, printf("Vertex buffer object and vertex array object \
initialized\n"));

#if DEBUG
  XEvent event;
#endif

  while(true)
  {
    VERB(verbose, printf("Updating uniforms ...\n"));
    updateUniforms(uniforms, uniformIds, &uniform_values, verbose);
    VERB(verbose, printf("Uniforms updated\n"));

    VERB(verbose, printf("Drawing on window ...\n"));
    draw(verbose);
    VERB(verbose, printf("Window drawing done\n"));

    VERB(verbose, printf("Swapping front and back buffers ...\n"));
    glXSwapBuffers(builder.display, builder.window);
    VERB(verbose, printf("Front and back buffers swapped\n"));

#if DEBUG
#define ESCAPE 0x09
    VERB(verbose, printf("Searching for key press event ...\n"));
    if (XCheckMaskEvent(builder.display, KeyPressMask, &event))
    {
      if (event.xkey.keycode == ESCAPE)
      {
        VERB(verbose, printf("Escape key press event occured\n"));
        break;
      }
      VERB(verbose, printf("Key press event occured\n"));
    } else {
      VERB(verbose, printf("Key press event did not occured\n"));
    }
#endif

    VERB(verbose, printf("Sleeping for %d ms ...\n", delay));
    usleep(delay);
    VERB(verbose, printf("Ready to loop again\n"));
  }

  VERB(verbose, printf("Disabling vertex attribute array ...\n"));
  GL_CHECK(glDisableVertexAttribArray(0));
  VERB(verbose, printf("Vertex attribute array disabled\n"));

  VERB(verbose, printf("Freeing fshaderpath ...\n"));
  free(fshaderpath);
  VERB(verbose, printf("fshaderpath freed\n"));

  VERB(verbose, printf("Freeing vshaderpath ...\n"));
  free(vshaderpath);
  VERB(verbose, printf("vshaderpath freed\n"));

  VERB(verbose, printf("Freeing texturepath ...\n"));
  free(texturepath);
  VERB(verbose, printf("texturepath freed\n"));

  VERB(verbose, printf("Deleting vertex buffer object ...\n"));
  GL_CHECK(glDeleteBuffers(1, &vertexbuffer));
  VERB(verbose, printf("Vertex buffer object deleted\n"));

  VERB(verbose, printf("Deleting vertex array object ...\n"));
  GL_CHECK(glDeleteVertexArrays(1, &vertexarray));
  VERB(verbose, printf("Vertex array object deleted\n"));

  VERB(verbose, printf("Deleting OpenGL texture ...\n"));
  GL_CHECK(glDeleteTextures(1, &texture));
  VERB(verbose, printf("OpenGL texture deleted\n"));

  VERB(verbose, printf("Deleting OpenGL program ...\n"));
  GL_CHECK(glDeleteProgram(program));
  VERB(verbose, printf("OpenGL program deleted\n"));

  VERB(verbose, printf("Detaching current rendering context ...\n"));
  glXMakeCurrent(builder.display, 0, 0);
  VERB(verbose, printf("Current rendering context detached\n"));

  VERB(verbose, printf("Destroying detached rendering context ...\n"));
  glXDestroyContext(builder.display, builder.context);
  VERB(verbose, printf("Detached rendering context destroyed\n"));

#if DEBUG
  VERB(verbose, printf("Destroying debug window ...\n"));
  XDestroyWindow(builder.display, debug_window);
  VERB(verbose, printf("Debug window destroyed\n"));
#endif

  VERB(verbose, printf("Destroying current window ...\n"));
  XDestroyWindow(builder.display, builder.window);
  VERB(verbose, printf("Current window destroyed\n"));

  VERB(verbose, printf("Freeing colormap ...\n"));
  XFreeColormap(builder.display, builder.cmap);
  VERB(verbose, printf("Colormap freed\n"));

  VERB(verbose, printf("Closing Display ...\n"));
  XCloseDisplay(builder.display);
  VERB(verbose, printf("Display closed\n"));

  return EXIT_SUCCESS;
}
