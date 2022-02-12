# TODO

This is a list of tasks expressed by the dev team for the dev team. It is not intented to be read by others so the tasks are not detailed. But if you want to contribute without going against the dev team work, you are in the right place. If you do not really know what a task is talking about and it might be a problem for a future contribution: open an issue to ask some details.

## Project management

MED PRIORITY:
- use pushd/popd in bash scripts

LOW PRIORITY:
- run memory checks
- run coverage checks
- run detectmissingconf with strict and nostrict
- add test and dev branches
- add hooks for memory-check, coverage-check and detect-AC_CHECK for master branch
- run test on graphic containers ???

## C files

MED PRIORITY:
- avoid usage of animated shader without generating textures atlas
- zoom default value should be 1
- add a flag to generate wallpaper into a PNG file with screen dimensions

LOW PRIORITY:
- add a flag to disable some planets/galaxy/darkhole/asteroids/bigstars
- use OpenMP for textures atlas generation
- use GLAD instead of GLEW ?

## Shader files

HIGH PRIORITY:
- fixing coord system --> pcg-hash must use frag coords
- use atlas textures
- use 9 cells loop for circles
- floor_multiple() really useful ???
- replace uv by cooords

MED PRIORITY:
- star clouds
- star streams
- no equality between floating numbers
- avoid pow() usage

LOW PRIORITY:
- parallalax
- More parameters on different planets to add more diversity
- use domain warping for moon craters
- slynyrd moon
- land planet with swirl clouds
- dry planet
- lava planet
- swirl planet
- dark planet
- galaxy
- dark hole (with event horizon animation)
- group of asteroids
- palette gen
