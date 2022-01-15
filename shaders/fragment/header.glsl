# version 330 core

// TODO:
// - More parameters on different planets to add more diversity
// - dry planet
// - lava planet
// - dark planet
// - add 2 more stars types
// - galaxy
// - dark hole (with event horizon animation)
// - group of asteroids
// - palette gen

precision highp float;

uniform float fflags[6];
uniform int bflags[4];
uniform sampler2D bigstars_texture;
uniform sampler2DArray atlas;

const float planets_density = 1.; // WARNING: must be greater than 3 to avoid some artifacts
const float bigstars_density = 3.;
const float stars_density = 20.0;

vec2 resolution = vec2(fflags[0], fflags[1]);
uint seed = uint(floor(fflags[2]));
float time = fflags[3] / 50.;
float pixels = fflags[4];
float zoom = fflags[5];

bool animation = (bflags[0] > 0 ? true : false);
bool motion = (bflags[1] > 0 ? true : false);
bool palettes = (bflags[2] > 0 ? true : false);
bool precomputed = (bflags[3] > 0 ? true : false);

struct Planet
{
  float type;
  vec2 center;
  float rotation;
  float radius;
  float time_speed;
  float plan;
  vec2 light_origin;
  uint turbulence;
  float ring;
  float ring_a;
};

# define NB_COLS 7.
# define PLANET_COLS 12.

# define DUST_SIZE 0.015
# define PLANETS_SIZE 0.01
# define MAX_RATE 300.
# define MOTION_SPEED 1.

bool dither(float dither_size, vec2 uv1, vec2 uv2)
{
  return mod(uv1.x + uv2.y, 2.0 / pixels) * dither_size <= 1.0 / pixels;
}
