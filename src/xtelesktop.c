#include "xtelesktop.h"

int main(int argc, char** argv)
{
  srand(time(NULL));

  bool verbose = false;
  int delay = DEFAULT_DELAY;

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  uniform_values.clock = clock();
  uniform_values.pixels = 500;
  uniform_values.animations = false;
  uniform_values.motion = false;
  uniform_values.palettes = false;
  uniform_values.xseed = rand();
  uniform_values.yseed = rand();

  if (!parsing_options(&verbose, &delay, &uniform_values, &argc, argv))
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

    freePaths(&fshaderpath, &vshaderpath, &texturepath, verbose);

    return EXIT_FAILURE;
  }
  VERB(verbose, printf("OpenGL context created\n"));

  VERB(verbose, printf("Initializing GLEW ...\n"));
  glewExperimental = GL_TRUE;

  if (glewInit())
  {
    fprintf(stderr, "glewInit() failed\n");
    freePaths(&fshaderpath, &vshaderpath, &texturepath, verbose);
    freeContext(&builder, verbose);

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
  if (!initDebugWindow(&builder, verbose))
  {
    freePaths(&fshaderpath, &vshaderpath, &texturepath, verbose);
    freeContext(&builder, verbose);
    return EXIT_FAILURE;
  }

  XEvent event;
#endif

  VERB(verbose, printf("Loading OpenGL program ...\n"));
  if (!loadProgram(&program, &vertex_shader, &vshaderpath, &fragment_shader,
    &fshaderpath, verbose))
  {
    fprintf(stderr, "\n\tShader program failed to load\n\n");
    freePaths(&fshaderpath, &vshaderpath, &texturepath, verbose);
    freeDebugContext(&builder, verbose);

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
    freePaths(&fshaderpath, &vshaderpath, &texturepath, verbose);

    VERB(verbose, printf("Deleting OpenGL program ...\n"));
    GL_CHECK(glDeleteProgram(program));
    VERB(verbose, printf("OpenGL program deleted\n"));

    freeDebugContext(&builder, verbose);

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

  freePaths(&fshaderpath, &vshaderpath, &texturepath, verbose);
  freeVertices(&vertexbuffer, &vertexarray, verbose);

  VERB(verbose, printf("Deleting OpenGL texture ...\n"));
  GL_CHECK(glDeleteTextures(1, &texture));
  VERB(verbose, printf("OpenGL texture deleted\n"));

  VERB(verbose, printf("Deleting OpenGL program ...\n"));
  GL_CHECK(glDeleteProgram(program));
  VERB(verbose, printf("OpenGL program deleted\n"));

  freeDebugContext(&builder, verbose);

  return EXIT_SUCCESS;
}
