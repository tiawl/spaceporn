# TODO

This is a list of tasks expressed by the maintainers for the maintainers. It is not intented to be read by others so the tasks are not detailed. But if you want to contribute without going against the maintainers' work, you are in the right place. If you do not really know what a task is talking about and it might be a problem for a future contribution: open an issue to ask more details.

## Project management

MEDIUM PRIORITY:
- use pushd/popd in bash scripts

LOW PRIORITY:
- run memory checks
- run coverage checks
- run detectmissingconf with strict and nostrict
- add test and dev branches
- add hooks for memory-check, coverage-check and detect-AC_CHECK for master branch
- run test on graphic containers ???

## C files

MEDIUM PRIORITY:
- avoid usage of animated shader without generating textures atlas
- zoom default value should be 1
- add a flag to generate wallpaper into a PNG file with screen dimensions

LOW PRIORITY:
- add a flag to disable some planets/galaxy/darkhole/asteroids/bigstars
- use OpenMP for textures atlas generation
- use GLAD instead of GLEW
- add a flag to generate wallpaper into a MP4 file with screen dimensions
- Windows OS portability

## Shader files

HIGH PRIORITY:
- use atlas textures
- animation for bigstars
- patterns for bigstars
- if 2 bigstars collide, increase brightness
- no == and != operators between floating numbers
- noisy light for planets (ring)
- fix planets density

MEDIUM PRIORITY:
- star clouds
- star streams
- dry planet
- swirl planet
- avoid pow() usage

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
- dark planet
- galaxy
- dark hole (with event horizon animation)
- group of asteroids
- palette gen
