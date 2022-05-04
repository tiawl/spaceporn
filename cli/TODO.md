# TODO

## Project management

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
- -b flag
- rework roadmaps

MEDIUM PRIORITY:
- use GLAD instead of GLEW

LOW PRIORITY:
- add a flag to disable some planets/galaxy/darkhole/asteroids/bigstars
- add a (--sample ?) flag to show one instance of a planet/galaxy/bigstar (new generation every 3 secs) in a little window
- Windows OS portability
- Vulkan compatibility

## Shader files

HIGH PRIORITY:
- Check if dithering could be achieved with an other method
- deferring heavy process out of loop & more advices: https://drive.google.com/file/d/1K50YnhApcdOV4RuqUTtl42JZqdxgMkm9/view

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
- Deep-Fold galaxy
- generic galaxies
- dark hole (with event horizon animation)
- group of asteroids
- color settings
- lab : https://www.shadertoy.com/view/3slXDf, https://www.shadertoy.com/view/7dffzn, https://www.shadertoy.com/view/NdlfzX

REMINDER:
- no == and != operators between floats
- check float format: 5. and 0.5
- avoid pow() usage
- deferring heavy process out of loop & more advices: https://drive.google.com/file/d/1K50YnhApcdOV4RuqUTtl42JZqdxgMkm9/view
