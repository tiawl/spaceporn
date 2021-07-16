#include "xtelesktop.h"

int main(int argc, char** argv)
{
  srand(time(NULL));

  int delay = DEFAULT_DELAY;

  bool verbose = false;
  aggregateVerbose(&verbose);

  enum Roadmap roadmap = EXIT_SUCCESS_RM;
  aggregateRoadmap(&roadmap);

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  uniform_values.clock = clock();
  uniform_values.pixels = 500;
  uniform_values.animations = false;
  uniform_values.motion = false;
  uniform_values.palettes = false;
  uniform_values.xseed = rand();
  uniform_values.yseed = rand();

  if (!parsing_options(&verbose, &delay, &uniform_values, &roadmap,
    &argc, argv))
  {
    return EXIT_FAILURE;
  }

  Shaders shaders;
  aggregateShaders(&shaders);
  shaders.vertex_file = NULL;
  shaders.fragment_file = NULL;
  shaders.fshaderpath = NULL;
  shaders.vshaderpath = NULL;
  shaders.vertex_shader = 0;
  shaders.fragment_shader = 0;
  shaders.program = 0;

  PNG png;
  aggregatePng(&png);
  png.file = NULL;
  png.data = NULL;
  png.parser = 0;
  png.info = 0;
  png.row_pointers = NULL;
  png.path = NULL;
  png.texture = 0;

  Context context;
  aggregateContext(&context);
  context.display = NULL;
  context.glx_context = 0;
  context.window = 0;
#if DEBUG
  context.debug_window = 0;
#endif
  context.visual_info = NULL;
  context.cmap = 0;

  Vertices vertices;
  aggregateVertices(&vertices);
  vertices.array = 0;
  vertices.buffer = 0;

  VERB(verbose, printf("Initializing fragment shader, vertex shader and \
texture paths ...\n"));
  if (!initPaths(&shaders, &png, verbose, roadmap))
  {
    fprintf(stderr, "Failed to initialize fragment shader, vertex shader or \
texture paths\n");
    freePaths(&shaders, &png, verbose);
    return EXIT_FAILURE;
  }
  VERB(verbose, printf("Fragment shader, vertex shader and texture paths \
are initialized\n"));

  VERB(verbose, printf("Creating GLX context ...\n"));
  if (!initContext(&context, verbose, roadmap))
  {
    fprintf(stderr, "Failed to create a GLX context\n");
    freePaths(&shaders, &png, verbose);
    freeContext(&context, verbose);
    return EXIT_FAILURE;
  }
  VERB(verbose, printf("GLX context created\n"));

  VERB(verbose, printf("Loading OpenGL program ...\n"));
  if (!loadProgram(&context, &shaders, verbose, roadmap))
  {
    fprintf(stderr, "OpenGL program failed to load\n");
    freePaths(&shaders, &png, verbose);
    freeProgram(&shaders, verbose, roadmap);
    freeContext(&context, verbose);
    return EXIT_FAILURE;
  }
  VERB(verbose, printf("OpenGL program loaded\n"));

  if (roadmap == OPENGL_ERROR_RM)
  {
    GL_CHECK(glBindBuffer(0, -1));
  }

  /* array of all uniforms to pass to the shader */
  const Uniform uniforms[] =
  {
    {"fflags", &updateFloatUniforms},
    {"bflags", &updateBoolUniforms},
  };

  GLuint uniformIds[UNIFORM_COUNT];

  uniform_values.width = context.window_attribs.width;
  uniform_values.height = context.window_attribs.height;

  VERB(verbose, printf("Loading PNG texture ...\n"));
  if (!loadPng(&png, verbose, roadmap))
  {
    fprintf(stderr, "Failed to load PNG file \"%s\"\n", png.path);
    freePaths(&shaders, &png, verbose);
    freePng(&png, verbose);
    freeProgram(&shaders, verbose, roadmap);
    freeContext(&context, verbose);
    return EXIT_FAILURE;
  }
  VERB(verbose, printf("PNG texture loaded\n"));

  VERB(verbose, printf("Searching uniforms location ...\n"));
  getUniforms(uniforms, uniformIds, &shaders.program, verbose);
  VERB(verbose, printf("Uniforms location found\n"));

  VERB(verbose, printf("Initializing vertex buffer object and vertex array \
object ...\n"));
  initVertices(&vertices, verbose);
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
    glXSwapBuffers(context.display, context.window);
    VERB(verbose, printf("Front and back buffers swapped\n"));

#if DEBUG
#define ESCAPE 0x09
    VERB(verbose, printf("Searching for key press event ...\n"));
    if (XCheckMaskEvent(context.display, KeyPressMask, &context.event))
    {
      if (context.event.xkey.keycode == ESCAPE)
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

    if (roadmap == BREAK_SUCCESS_RM)
    {
      break;
    }
  }

  freePaths(&shaders, &png, verbose);
  freeVertices(&vertices, verbose);
  freePng(&png, verbose);
  freeProgram(&shaders, verbose, roadmap);
  freeContext(&context, verbose);

  return EXIT_SUCCESS;
}
