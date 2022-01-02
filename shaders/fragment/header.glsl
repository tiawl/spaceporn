// TODO:
// - More parameters on different planets to add more variety
// - add zoom uniform (to avoid confusion with pixels)
// - ring planet
// - dry planet
// - galaxy
// - dark hole (with event horizon animation)
// - group of asteroids
// - palette gen

uniform float fflags[6];
uniform bvec3 bflags;
uniform sampler2D big_stars_texture;

out vec4 fragColor;

const float planets_density = 1.; // WARNING: must be greater than 1 to avoid some artifacts
const float bigstars_density = 3.;
const float stars_density = 20.0;

vec2 resolution = vec2(fflags[0], fflags[1]);
uint seed = uint(floor(fflags[2]));
float time = fflags[3] / 50.;
float pixels = fflags[4];

bool animation = bflags.x;
bool motion = bflags.y;
bool palettes = bflags.z;

struct Planet
{
  float type;
  vec2 center;
  float rotation;
  float radius;
  uint seed;
  float time_speed;
  float plan;
  vec2 light_origin;
  uint turbulence;
};

# define TEXTURE_SIZE vec2(256., 32.)
# define NB_COLS 7.
# define GAZ_COLS 12.
# define PLANET_COLS 20.

# define DUST_SIZE 0.015
# define PLANETS_SIZE 0.01
# define MAX_RATE 300.
# define MOTION_SPEED 1.

bool dither(float dither_size, vec2 uv1, vec2 uv2)
{
  return mod(uv1.x + uv2.y, 2.0 / pixels) * dither_size <= 1.0 / pixels;
}
