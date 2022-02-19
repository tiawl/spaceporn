# version 330 core

precision highp float;
precision highp int;

uniform float fflags[6];
uniform int bflags[4];
uniform sampler2DArray atlas;

vec2 resolution = vec2(fflags[0], fflags[1]);
float shorter_res = min(resolution.x, resolution.y);
float larger_res = max(resolution.x, resolution.y);
uint seed = uint(floor(fflags[2]));
float time = fflags[3] / 50.;
float pixels = fflags[4];
float zoom = fflags[5];

bool animation = (bflags[0] > 0 ? true : false);
bool motion = (bflags[1] > 0 ? true : false);
bool palettes = (bflags[2] > 0 ? true : false);
int precomputed = bflags[3];

# define NB_COLS 7.
# define PLANET_COLS 12.

# define MAX_RATE 300.
# define MOTION_SPEED 1.

# define STARS_DENSITY 20.
# define BIGSTARS_DENSITY 5.
# define HFNEBULA_SIZE 15.
# define LFNEBULA_SIZE 30.
# define PLANETS_DENSITY 10.

# define NO_ATLAS 0
# define STARS_DONE 2

bool dither(vec2 coords1, vec2 coords2)
{
  return mod(coords1.x + coords2.y, 2. / pixels) <= 1. / pixels;
}

float floor2(float x, float base)
{
  return floor(x / base) * base;
}

vec2 rotate(vec2 coords, vec2 center, float angle)
{
  coords -= center;
  coords *= mat2(cos(angle), -sin(angle),
                 sin(angle),  cos(angle));
  coords += center;
  return coords;
}
