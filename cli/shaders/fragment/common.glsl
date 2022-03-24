# version 330 core

precision highp float;
precision highp int;

uniform float flags[8];
uniform sampler2DArray atlas;

vec2 resolution = vec2(flags[0], flags[1]);
float shorter_res = min(resolution.x, resolution.y);
float larger_res = max(resolution.x, resolution.y);
uint seed = uint(floor(flags[2]));
float time = flags[3];
float pixels = flags[4];
float zoom = flags[5];
float mode = flags[6];
float color_settings = flags[7];

bool stars_done = false;

# define NB_COLS              7.
# define PLANET_COLS         12.

# define MAX_RATE           300.
# define MOTION_SPEED         1.

# define STARS_DENSITY       20.
# define BIGSTARS_DENSITY     5.
# define HFNEBULA_SIZE       15.
# define LFNEBULA_SIZE       30.
# define PLANETS_DENSITY     10.

# define ANIM_MOTION_MODE     1.
# define ANIM_MODE            2.
# define MOTION_MODE          3.
# define BGGEN_MODE           4.
# define SLIDE_MODE           5.

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
