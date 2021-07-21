uniform float fflags[6];
uniform bvec3 bflags;
uniform sampler2D big_stars_texture;

out vec4 fragColor;

const float SIZE = 10.0;

const float planets_density = 1.; // WARNING: must be greater than 1 to avoid some artifacts
const float bigstars_density = 3.;

vec2 resolution = vec2(fflags[0], fflags[1]);
vec2 seed = vec2(fflags[2], fflags[3]);
float time = fflags[4];
float pixels = fflags[5];

bool animation = bflags.x;
bool motion = bflags.y;
bool palettes = bflags.z;

struct Planet
{
  float type;
  vec2 center;
  float rotation;
  float radius;
  vec2 seed;
  float time_speed;
  float plan;
  vec2 light_origin;
};

#define TEXTURE_SIZE vec2(256., 32.)
#define NB_COL 7.
