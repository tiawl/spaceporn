# TODO

This is a list of tasks expressed by the maintainers for the maintainers. It is not intented to be read by others so the tasks are not detailed. But if you want to contribute without going against the maintainers' work, you are in the right place. If you do not really know what a task is talking about and it might be a problem for a future contribution: open an issue to ask more details.

## Project management

MEDIUM PRIORITY:
- use pushd/popd in bash scripts

LOW PRIORITY:
- add test and dev branches
- add hooks for memory-check, coverage-check and detect-AC_CHECK for master branch
- run test on graphic containers ???

REMINDER:
- run memory checks
- run coverage checks
- run detectmissingconf with strict and nostrict

## C files

HIGH PRIORITY:
- use FrameBuffer with RenderBuffer and tilling (1024x1024 max size for opengl 3.3) to generate textures atlas:
https://stackoverflow.com/questions/59433403/how-to-save-fragment-shader-image-changes-to-image-output-file
- query for debugging purposes:
glGetIntegerv (GL_MAX_ARRAY_TEXTURE_LAYERS, &max_arraytextures_layers);
glGetIntegerv (GL_MAX_RENDERBUFFER_SIZE, &max_rb_size);
glGetInteger2v (GL_MAX_VIEWPORT_DIMS, &max_viewport_dims);
glGetIntegerv (GL_MAX_TEXTURE_SIZE, &max_texture_size);

MEDIUM PRIORITY:
- avoid usage of animated shader without generating textures atlas
- zoom default value should be 1
- add a flag to generate wallpaper into a PNG file with screen dimensions

LOW PRIORITY:
- add a flag to disable some planets/galaxy/darkhole/asteroids/bigstars
- use GLAD instead of GLEW
- Windows OS portability

## Shader files

HIGH PRIORITY:
- use atlas textures
- mirroring UV in nova patterns

MEDIUM PRIORITY:
- star clouds
- star streams
- swirl planet
- dry planet
- fix ring overflow
- dark planet

LOW PRIORITY:
- parallalax
- More parameters on different planets to add more diversity --> light colors for land ??
- use domain warping for moon craters
- slynyrd moon
- land planet with swirl clouds
- lava planet
- abueloretrowave ring planet
- abueloretrowave metal planet
- death star ??
- galaxy
- dark hole (with event horizon animation)
- group of asteroids
- palette gen
- lab : https://www.shadertoy.com/view/3slXDf, https://www.shadertoy.com/view/7dffzn, https://www.shadertoy.com/view/NdlfzX

REMINDER:
- no == and != operators between floats
- check float format: 5. and 0.5
- avoid pow() usage
