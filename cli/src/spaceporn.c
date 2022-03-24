#include "spaceporn.h"

int main(int argc, char** argv)
{
  time_t now = time(NULL);
  srand(now);
  fflush(stdin);

  bool status = true;
  long fps = DEFAULT_FPS;
  bool new_atlas = false;
  long png_width = -1;
  long png_height = -1;
  long slide_delay = DEFAULT_SLIDE;

  Log log;
  log.verbose = false;
  log.roadmap.id = EXIT_SUCCESS_RM;

  UniformValues uniform_values;
  uniform_values.time = 0.0f;
  gettimeofday(&(uniform_values.start), NULL);
  uniform_values.pixels = (rand() % (MAX_PIXELS - MIN_PIXELS)) + MIN_PIXELS;
  uniform_values.zoom = (rand() % (MAX_ZOOM - MIN_ZOOM)) + MIN_ZOOM;
  uniform_values.color = STATIC_MONO;
  uniform_values.mode = NO_MODE;
  uniform_values.seed = -1.;

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
  context.display = NULL;
  context.glx_context = 0;
  context.window = 0;
#if DEV
  context.debug_window = 0;
  int fps_timer = -1;
  int fps_counter = -1;
#endif
  context.visual_info = NULL;
  context.cmap = 0;

  Vertices vertices;
  vertices.array = 0;
  vertices.buffer = 0;

  do
  {
    if (!parsing_options(&fps, &new_atlas, &png_width, &png_height,
      &slide_delay, &uniform_values, &log, &argc, argv))
    {
      status = false;
      break;
    }

    struct timeval start_loop;
    struct timeval end_loop;
    unsigned gpu_time;
    unsigned delay;
    if ((uniform_values.mode >= ANIM_MOTION_MODE) &&
      (uniform_values.mode <= MOTION_MODE))
    {
      delay = 1000000.0f / fps;
    } else if (uniform_values.mode == SLIDE_MODE) {
      delay = slide_delay;
    }

    writeLog(&log, stdout, INFO, "", "Running %s %s %s\n", NAME, VERSION,
      BRANCH);

    writeLog(&log, stdout, DEBUG, "", "Initializing paths ...\n");
    if (!initPaths(&shaders, &png_atlas, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), ERROR, "",
        "Failed to initialize paths\n", ERROR);
      status = false;
      break;
    }
    writeLog(&log, stdout, DEBUG, "", "Paths are initialized\n");

    writeLog(&log, stdout, DEBUG, "", "Creating GLX context ...\n");
    if (!initContext(&context, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), ERROR, "",
        "Failed to create a GLX context\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, DEBUG, "", "GLX context created\n");

    uniform_values.width = context.window_attribs.width;
    uniform_values.height = context.window_attribs.height;

    if (new_atlas || (access(png_atlas.path, F_OK) != 0))
    {
      if (!new_atlas)
      {
        printf("No seed found\n");
      }

      printf("Generating new seed ...\n");
      struct timeval start_new_atlas;
      struct timeval end_new_atlas;
      gettimeofday(&start_new_atlas, NULL);
      writeLog(&log, stdout, INFO, "",
        "Computing textures atlas dimensions ...\n");

      if (context.window_attribs.width >= context.window_attribs.height)
      {
        atlas.width = nextpow2(MAX_PIXELS * 5 *
        ((int) round(((double) context.window_attribs.width) /
          ((double) context.window_attribs.height))));
      } else {
        atlas.height = nextpow2(MAX_PIXELS * 5 *
        ((int) round(((double) context.window_attribs.height) /
          ((double) context.window_attribs.width))));
      }
      writeLog(&log, stdout, INFO, "",
        "Textures atlas dimensions are: %dx%d\n", atlas.width, atlas.height);

      writeLog(&log, stdout, DEBUG, "", "Generating textures atlas ...\n");
      if (!generateAtlas(&atlas, &png_atlas, &log))
      {
        writeLog(&log, (log.verbose ? stdout : stderr), ERROR, "",
          "Failed to generate textures atlas\n");
        status = false;
        break;
      }
      writeLog(&log, stdout, DEBUG, "", "Textures atlas generated\n");
      gettimeofday(&end_new_atlas, NULL);
      double diff = timediff(&start_new_atlas, &end_new_atlas) * 1000000.0f;
      printf("New seed generated in %fs\n", diff / 1000000.0f);

      generateAtlas2(&atlas, &png_atlas, &log);
    }

    if (uniform_values.mode == LOCKED)
    {
      printf("No mode used. Exit\n");
      break;
    }

    if (uniform_values.mode == BGGEN_MODE)
    {
      if ((png_width == -1) || (png_height == -1))
      {
        png_width = context.window_attribs.width;
        png_height = context.window_attribs.height;
      }
      printf("Generation Mode used to generate a %ldx%ld PNG\n", png_width,
        png_height);
      break;
    }

    writeLog(&log, stdout, DEBUG, "", "Loading OpenGL program ...\n");
    if (!loadProgram(&context, &shaders, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), ERROR, "",
        "OpenGL program failed to load\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, DEBUG, "", "OpenGL program loaded\n");

    if (log.roadmap.id == OPENGL_ERROR_RM)
    {
      GL_CHECK(glBindBuffer(0, -1), status, &log);
    }

    // array of all uniforms to pass to the shader
    const Uniform uniforms[] =
    {
      {"flags", &updateFloatUniforms},
    };

    GLuint uniformIds[UNIFORM_COUNT];

    writeLog(&log, stdout, DEBUG, "", "Loading textures atlas ...\n");
    if (!loadAtlas(&atlas, &png_atlas, &shaders, &log))
    {
      writeLog(&log, (log.verbose ? stdout : stderr), ERROR, "",
        "Failed to load textures atlas\n");
      status = false;
      break;
    }
    writeLog(&log, stdout, DEBUG, "", "Textures atlas loaded\n");

    writeLog(&log, stdout, DEBUG, "", "Searching uniforms location ...\n");
    getUniforms(uniforms, uniformIds, &shaders.program, &log);
    writeLog(&log, stdout, DEBUG, "", "Uniforms location found\n");

    writeLog(&log, stdout, DEBUG, "",
      "Initializing vertex buffer object and vertex array object ...\n");
    initVertices(&vertices, &log);
    writeLog(&log, stdout, DEBUG, "",
      "Vertex buffer object and vertex array object initialized\n");

    while (true)
    {
      if ((uniform_values.mode >= ANIM_MOTION_MODE) &&
        (uniform_values.mode <= MOTION_MODE))
      {
        gettimeofday(&start_loop, NULL);

#if DEV
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

      writeLog(&log, stdout, DEBUG, "", "Updating uniforms ...\n");
      updateUniforms(uniforms, uniformIds, &uniform_values, &log);
      writeLog(&log, stdout, DEBUG, "", "Uniforms updated\n");

      writeLog(&log, stdout, DEBUG, "", "Drawing on window ...\n");
      draw(&log);
      writeLog(&log, stdout, DEBUG, "", "Window drawing done\n");

      writeLog(&log, stdout, DEBUG, "",
        "Swapping front and back buffers ...\n");
      glXSwapBuffers(context.display, context.window);
      writeLog(&log, stdout, DEBUG, "", "Front and back buffers swapped\n");

#if DEV
#define ESCAPE 0x09
      writeLog(&log, stdout, DEBUG, "", "Searching for key press event ...\n");
      if (XCheckMaskEvent(context.display, KeyPressMask, &context.event))
      {
        if (context.event.xkey.keycode == ESCAPE)
        {
          writeLog(&log, stdout, DEBUG, "", "Escape key press event occured\n");
          break;
        }
        writeLog(&log, stdout, DEBUG, "", "Key press event occured\n");
      } else {
        writeLog(&log, stdout, DEBUG, "", "Key press event did not occured\n");
      }
#endif

      if ((uniform_values.mode >= ANIM_MOTION_MODE) &&
        (uniform_values.mode <= MOTION_MODE))
      {
        gettimeofday(&end_loop, NULL);
        gpu_time = timediff(&start_loop, &end_loop) * 1000000.0f;
        writeLog(&log, stdout, INFO, "", "Sleeping for %d ms ...\n",
          gpu_time >= delay ? 0 : delay - gpu_time);
        usleep(gpu_time >= delay ? 0 : delay - gpu_time);
#if DEV
        fps_timer -= (gpu_time > delay ? gpu_time : delay);
        fps_counter++;
#endif
      } else {
        writeLog(&log, stdout, INFO, "", "Sleeping for %d min ...\n", delay);
        if (log.roadmap.id == SLIDEMODE_SUCCESS_RM)
        {
          delay = 0;
          log.roadmap.id = BREAK_SUCCESS_RM;
        }
        sleep(delay * 60);
      }
      writeLog(&log, stdout, DEBUG, "", "Ready to loop again\n");

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
