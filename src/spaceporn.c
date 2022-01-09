#include "spaceporn.h"

int main(int argc, char** argv)
{
  srand(time(NULL));

  bool status = true;
  long fps = DEFAULT_FPS;
  long generation = -1;

  bool verbose = false;

  Roadmap roadmap;
  roadmap.id = EXIT_SUCCESS_RM;

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
  shaders.vertex_shader = 0;
  shaders.fragment_shader = 0;
  shaders.program = 0;

  PNG png;
  png.file = NULL;
  png.data = NULL;
  png.ptr = 0;
  png.info = 0;
  png.row_pointers = NULL;
  png.path = NULL;
  png.texture = 0;
  png.texture_unit = 0;

  PNG png_atlas;
  png_atlas.file = NULL;
  png_atlas.data = NULL;
  png_atlas.ptr = 0;
  png_atlas.info = 0;
  png_atlas.row_pointers = NULL;
  png_atlas.path = NULL;
  png_atlas.texture = 0;
  png_atlas.texture_unit = 1;

  Atlas atlas;
  atlas.texels = NULL;
// atlas.width = nextpow2(MAX_PIXELS * 5);
// atlas.height = nextpow2(MAX_PIXELS * 5);
  atlas.width = 16;
  atlas.height = 8;
  atlas.depth = 4;
  atlas.pcg_depth = 4;
  atlas.seed[0] = rand();
  atlas.seed[1] = rand();

  Context context;
  context.display = NULL;
  context.glx_context = 0;
  context.window = 0;
#if DEBUG
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
    if (!parsing_options(&verbose, &fps, &generation, &uniform_values,
      &roadmap, &argc, argv))
    {
      status = false;
      break;
    }

    uniform_values.zoom /= 100.;

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

    LOG(verbose, printf("Initializing fragment shader, vertex shader and \
texture paths ...\n"));
    if (!initPaths(&shaders, &png, &png_atlas, verbose, &roadmap))
    {
      fprintf((verbose ? stdout : stderr), "Failed to initialize fragment \
shader, vertex shader or texture paths\n");
      status = false;
      break;
    }
    LOG(verbose, printf("Fragment shader, vertex shader and texture paths \
are initialized\n"));

    LOG(verbose, printf("Creating GLX context ...\n"));
    if (!initContext(&context, verbose, &roadmap))
    {
      fprintf((verbose ? stdout : stderr), "Failed to create a GLX context\n");
      status = false;
      break;
    }
    LOG(verbose, printf("GLX context created\n"));

    uniform_values.width = context.window_attribs.width;
    uniform_values.height = context.window_attribs.height;

    if (generation > -1)
    {
      LOG(verbose, printf("Computing textures atlas dimensions ...\n"));

//       if (context.window_attribs.width >= context.window_attribs.height)
//       {
//         atlas.width = nextpow2(MAX_PIXELS * 5 *
//         ((int) round(((double) context.window_attribs.width) /
//           ((double) context.window_attribs.height))));
//       } else {
//         atlas.height = nextpow2(MAX_PIXELS * 5 *
//         ((int) round(((double) context.window_attribs.height) /
//           ((double) context.window_attribs.width))));
//       }
      LOG(verbose, printf("Textures atlas dimensions are: %dx%d\n", atlas.width,
        atlas.height));

      LOG(verbose, printf("Generating textures atlas ...\n"));
      if (!generateAtlas(&atlas, &png_atlas, verbose, &roadmap))
      {
        fprintf((verbose ? stdout : stderr),
          "Failed to generate textures atlas\n");
        status = false;
        break;
      }
      LOG(verbose, printf("Textures atlas generated\n"));

      if (generation == 1)
      {
        break;
      }
    }

    LOG(verbose, printf("Loading OpenGL program ...\n"));
    if (!loadProgram(&context, &shaders, verbose, &roadmap))
    {
      fprintf((verbose ? stdout : stderr), "OpenGL program failed to load\n");
      status = false;
      break;
    }
    LOG(verbose, printf("OpenGL program loaded\n"));

    if (roadmap.id == OPENGL_ERROR_RM)
    {
      GL_CHECK(glBindBuffer(0, -1), status);
    }

    // array of all uniforms to pass to the shader
    const Uniform uniforms[] =
    {
      {"fflags", &updateFloatUniforms},
      {"bflags", &updateBoolUniforms},
    };

    GLuint uniformIds[UNIFORM_COUNT];

    LOG(verbose, printf("Loading PNG texture ...\n"));
    if (!loadPng(&png, &shaders, verbose, &roadmap))
    {
      fprintf((verbose ? stdout : stderr),
        "Failed to load PNG file \"%s\"\n", png.path);

      status = false;
      break;
    }
    LOG(verbose, printf("PNG texture loaded\n"));

    if (uniform_values.slide == 0)
    {
      LOG(verbose, printf("Checking if atlas PNG texture exists ...\n"));
      if (access(png_atlas.path, F_OK) == 0)
      {
        uniform_values.precomputed = true;
        LOG(verbose, printf("Atlas PNG texture exists\n"));

        LOG(verbose, printf("Loading textures atlas ...\n"));
        if (!loadAtlas(&atlas, &png_atlas, &shaders, verbose, &roadmap))
        {
          fprintf((verbose ? stdout : stderr), "Failed to load textures atlas\n");
          status = false;
          break;
        }
        LOG(verbose, printf("Textures atlas loaded\n"));
      } else {
        LOG(verbose, printf("Atlas PNG texture does not exist\n"));
      }
    }

    LOG(verbose, printf("Searching uniforms location ...\n"));
    getUniforms(uniforms, uniformIds, &shaders.program, verbose);
    LOG(verbose, printf("Uniforms location found\n"));

    LOG(verbose, printf("Initializing vertex buffer object and vertex array \
object ...\n"));
    initVertices(&vertices, verbose);
    LOG(verbose, printf("Vertex buffer object and vertex array object \
initialized\n"));

    while (true)
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

      LOG(verbose, printf("Updating uniforms ...\n"));
      updateUniforms(uniforms, uniformIds, &uniform_values, verbose);
      LOG(verbose, printf("Uniforms updated\n"));

      LOG(verbose, printf("Drawing on window ...\n"));
      draw(verbose);
      LOG(verbose, printf("Window drawing done\n"));

      LOG(verbose, printf("Swapping front and back buffers ...\n"));
      glXSwapBuffers(context.display, context.window);
      LOG(verbose, printf("Front and back buffers swapped\n"));

#if DEBUG
#define ESCAPE 0x09
      LOG(verbose, printf("Searching for key press event ...\n"));
      if (XCheckMaskEvent(context.display, KeyPressMask, &context.event))
      {
        if (context.event.xkey.keycode == ESCAPE)
        {
          LOG(verbose, printf("Escape key press event occured\n"));
          break;
        }
        LOG(verbose, printf("Key press event occured\n"));
      } else {
        LOG(verbose, printf("Key press event did not occured\n"));
      }
#endif

      if ((fps > 0) && (uniform_values.slide == 0))
      {
        gettimeofday(&end_loop, NULL);
        gpu_time = timediff(&start_loop, &end_loop) * 1000000.0f;
        LOG(verbose, printf("Sleeping for %d ms ...\n",
          gpu_time >= delay ? 0 : delay - gpu_time));
        usleep(gpu_time >= delay ? 0 : delay - gpu_time);
#if DEBUG
        fps_timer -= (gpu_time > delay ? gpu_time : delay);
        fps_counter++;
#endif
      } else {
        LOG(verbose, printf("Sleeping for %d min ...\n", delay));
        if (roadmap.id == SLIDEMODE_SUCCESS_RM)
        {
          delay = 0;
          roadmap.id = BREAK_SUCCESS_RM;
        }
        sleep(delay * 60);
      }
      LOG(verbose, printf("Ready to loop again\n"));

      if (roadmap.id == BREAK_SUCCESS_RM)
      {
        break;
      }
    }
  } while (false);

  freePaths(&shaders, &png, &png_atlas, verbose);
  freeVertices(&vertices, verbose);
  freePng(&png, verbose);
  freePng(&png_atlas, verbose);
  freeAtlas(&atlas, verbose);
  freeProgram(&shaders, verbose, &roadmap);
  freeContext(&context, verbose);

  return (status ? EXIT_SUCCESS : EXIT_FAILURE);
}
