#include "spaceporn.h"

int main(int argc, char** argv)
{
  time_t now = time(NULL);
  srand(now);
  fflush(stdin);

  bool status = true;
  long fps = DEFAULT_FPS;
  long generation = -1;

  Log log;
  log.verbose = false;
  log.roadmap.id = EXIT_SUCCESS_RM;

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  uniform_values.slide = 0;
  gettimeofday(&(uniform_values.start), NULL);
  uniform_values.pixels = DEFAULT_PIXELS;
  uniform_values.zoom = DEFAULT_ZOOM;
  uniform_values.animations = DEFAULT_ANIMATIONS;
  uniform_values.motion = DEFAULT_MOTION;
  uniform_values.palettes = DEFAULT_PALETTES;
  uniform_values.seed = -1.;
  uniform_values.precomputed = false;

  Shaders shaders;
  shaders.vertex_file = NULL;
  shaders.fragment_file = NULL;
  shaders.fshaderpath = NULL;
  shaders.vshaderpath = NULL;
  shaders.fshaderdir = NULL;
  shaders.vshaderdir = NULL;
  shaders.vertex_shader = 0;
  shaders.fragment_shader = 0;
  shaders.program = 0;

  PNG png_atlas;
  png_atlas.file = NULL;
  png_atlas.data = NULL;
  png_atlas.ptr = 0;
  png_atlas.info = 0;
  png_atlas.row_pointers = NULL;
  png_atlas.path = NULL;
  png_atlas.texture = 0;
  png_atlas.texture_unit = 0;

  Atlas atlas;
  atlas.texels = NULL;
  atlas.width = nextpow2(MAX_PIXELS * 5);
  atlas.height = nextpow2(MAX_PIXELS * 5);
  atlas.depth = 4;
  atlas.pcg_depth = 4;
  atlas.seed[0] = rand();
  atlas.seed[1] = rand();

  Context context;
  context.window = NULL;
#if DEBUG
  int fps_timer = -1;
  int fps_counter = -1;
#endif

  Vertices vertices;
  vertices.array = 0;
  vertices.buffer = 0;

  do
  {
    if (!parsing_options(&fps, &generation, &(atlas.width), &(atlas.height),
      &uniform_values, &log, &argc, argv))
    {
      status = false;
      break;
    }

    struct timeval start_loop;
    struct timeval end_loop;
    unsigned gpu_time;
    unsigned delay;
    if ((fps > 0) && (uniform_values.slide == 0))
    {
      delay = 1000000.0f / fps;
    } else {
      delay = uniform_values.slide;
    }

    writeLog(&log, stdout, "", "Initializing paths ...\n");
    if (!initPaths(&shaders, &png_atlas, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), "",
        "Failed to initialize paths\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, "", "Paths are initialized\n");

    writeLog(&log, stdout, "", "Creating context ...\n");
    if (!initContext(&context, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), "",
        "Failed to create a context\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, "", "Context created\n");

    uniform_values.width = context.width;
    uniform_values.height = context.height;

    if ((generation > -1) || (access(png_atlas.path, F_OK) != 0))
    {
      writeLog(&log, stdout, "", "Computing textures atlas dimensions ...\n");

      if ((atlas.width == UNDEFINED_SIZE) || (atlas.height == UNDEFINED_SIZE)
        || (generation == -1))
      {
        atlas.width = nextpow2(7);
        atlas.height = nextpow2(7);
      } else {
        if (context.width >= context.height)
        {
          atlas.width = nextpow2(MAX_PIXELS * 5 *
          ((int) round(((double) context.width) / ((double) context.height))));
        } else {
          atlas.height = nextpow2(MAX_PIXELS * 5 *
          ((int) round(((double) context.height) / ((double) context.width))));
        }
      }
      writeLog(&log, stdout, "", "Textures atlas dimensions are: %dx%d\n",
        atlas.width, atlas.height);

      writeLog(&log, stdout, "", "Generating textures atlas ...\n");
      if (!generateAtlas(&atlas, &png_atlas, &log))
      {
        writeLog(&log, (log.verbose ? stdout : stderr), "",
          "Failed to generate textures atlas\n");
        status = false;
        break;
      }
      writeLog(&log, stdout, "", "Textures atlas generated\n");

      if (generation == 1)
      {
        break;
      }
    }

    writeLog(&log, stdout, "", "Loading OpenGL program ...\n");
    if (!loadProgram(&context, &shaders, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), "",
        "OpenGL program failed to load\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, "", "OpenGL program loaded\n");

    if (log.roadmap.id == OPENGL_ERROR_RM)
    {
      GL_CHECK(glBindBuffer(0, -1), status, &log);
    }

    // array of all uniforms to pass to the shader
    const Uniform uniforms[] =
    {
      {"fflags", &updateFloatUniforms},
      {"bflags", &updateBoolUniforms},
    };

    GLuint uniformIds[UNIFORM_COUNT];

    writeLog(&log, stdout, "", "Loading textures atlas ...\n");
    if (!loadAtlas(&atlas, &png_atlas, &shaders,
      &(uniform_values.precomputed), &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), "",
        "Failed to load textures atlas\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, "", "Textures atlas loaded\n");

    writeLog(&log, stdout, "", "Searching uniforms location ...\n");
    getUniforms(uniforms, uniformIds, &shaders.program, &log);
    writeLog(&log, stdout, "", "Uniforms location found\n");

    writeLog(&log, stdout, "",
      "Initializing vertex buffer object and vertex array object ...\n");
    initVertices(&vertices, &log);
    writeLog(&log, stdout, "",
      "Vertex buffer object and vertex array object initialized\n");

    while (!glfwWindowShouldClose(context.window))
    {
      if ((fps > 0) && (uniform_values.slide == 0))
      {
        gettimeofday(&start_loop, NULL);

#if DEBUG
        if (fps_timer <= 0)
        {
          if (fps_counter >= 0)
          {
            printf("%d FPS\n", fps_counter);
          }
          fps_counter = 0;
          fps_timer = 1000000;
        }
#endif
      }

      writeLog(&log, stdout, "", "Updating uniforms ...\n");
      updateUniforms(uniforms, uniformIds, &uniform_values, &log);
      writeLog(&log, stdout, "", "Uniforms updated\n");

      writeLog(&log, stdout, "", "Drawing on window ...\n");
      draw(&log);
      writeLog(&log, stdout, "", "Window drawing done\n");

      writeLog(&log, stdout, "", "Swapping front and back buffers ...\n");
      glfwSwapBuffers(context.window);
      writeLog(&log, stdout, "", "Front and back buffers swapped\n");

#if DEBUG
      writeLog(&log, stdout, "", "Processing events in the event queue ...\n");
      glfwPollEvents();
      writeLog(&log, stdout, "", "Events processed\n");
#endif

      if ((fps > 0) && (uniform_values.slide == 0))
      {
        gettimeofday(&end_loop, NULL);
        gpu_time = timediff(&start_loop, &end_loop) * 1000000.0f;
        writeLog(&log, stdout, "", "Sleeping for %d ms ...\n",
          gpu_time >= delay ? 0 : delay - gpu_time);
        usleep(gpu_time >= delay ? 0 : delay - gpu_time);
#if DEBUG
        fps_timer -= (gpu_time > delay ? gpu_time : delay);
        fps_counter++;
#endif
      } else {
        writeLog(&log, stdout, "", "Sleeping for %d min ...\n", delay);
        if (log.roadmap.id == SLIDEMODE_SUCCESS_RM)
        {
          delay = 0;
          log.roadmap.id = BREAK_SUCCESS_RM;
        }
        sleep(delay * 60);
      }
      writeLog(&log, stdout, "", "Ready to loop again\n");

      if (log.roadmap.id == BREAK_SUCCESS_RM)
      {
        break;
      }
    }
  } while (false);

  freeVertices(&vertices, &log);
  freePng(&png_atlas, &log);
  freeAtlas(&atlas, &log);
  freeProgram(&shaders, &log);
  freeContext(&context, &log);

  return (status ? EXIT_SUCCESS : EXIT_FAILURE);
}
