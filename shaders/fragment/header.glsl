# version 330 core

precision highp float;

uniform float fflags[6];
uniform int bflags[4];
uniform sampler2DArray atlas;

const float stars_density = 20.0;

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

struct Star
{
  float type;
  vec2 center;
  float size;
  float time_speed;
  float brightness;
  float shape;
  uint sharpness;
  float diag;
  float ring_size;
};

# define NB_COLS 7.
# define PLANET_COLS 12.

# define PLANETS_SIZE 0.01
# define MAX_RATE 300.
# define MOTION_SPEED 1.

# define BIGSTARS_DENSITY 5.
# define DUST_SIZE 15.
# define NEBULA_SIZE 30.
# define PLANETS_DENSITY 10.

bool dither(float dither_size, vec2 uv1, vec2 uv2)
{
  return mod(uv1.x + uv2.y, 2.0 / pixels) * dither_size <= 1.0 / pixels;
}

float floor_multiple(float numToRound, float base)
{
  float modulo = mod(numToRound, base);
  return (sign(modulo) < 0.5 ? numToRound : numToRound - modulo);
}

vec2 rotate(vec2 vec, vec2 center, float angle)
{
  vec -= center;
  vec *= mat2(cos(angle), -sin(angle),
              sin(angle),  cos(angle));
  vec += center;
  return vec;
}
