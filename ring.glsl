# define float2 vec2
# define float3 vec3
# define float4 vec4

float pixels = 200.0;
float gaz_rotation = 0.0;
vec2 light_origin;
float radius = 1.;
vec2 center= vec2(1.25);
float time_speed = 0.05;
float light_border_1= 0.52;
float light_border_2= 0.62;
float bands = 1.0;

float gaz_size = 8.0;
int OCTAVES = 5;
float gaz_seed = 3.036;

float ring_rotation = -.5;
float ring_perspective = 1.7; // 6.0;
float ring_width = 0.15; // 0.127;
float scale_rel_to_planet = 0.;
float ring_size = 10.0;
float ring_seed = 8.461;

const float3[15] lightColors = float3[](
  float3(0.933, 0.764, 0.603),    // #eec39a
  float3(0.913, 0.729, 0.552),
  float3(0.894, 0.698, 0.501),
  float3(0.870, 0.662, 0.450),
  float3(0.850, 0.627, 0.4),      // #d9a066
  float3(0.792, 0.568, 0.364),
  float3(0.733, 0.509, 0.333),
  float3(0.678, 0.454, 0.298),
  float3(0.619, 0.396, 0.266),
  float3(0.560, 0.337, 0.231),    // #8f563b
  float3(0.0, 1.0, 1.0),        // control colors from here on. To watch for overflows
  float3(0.0, 0.8, 0.8),
  float3(0.0, 0.6, 0.6),
  float3(0.0, 0.4, 0.4),
  float3(0.0, 0.2, 0.2)
);

const float3[15] darkColors = float3[](
  float3(0.4, 0.223, 0.192),      // #663931
  float3(0.368, 0.207, 0.203),
  float3(0.337, 0.192, 0.215),
  float3(0.301, 0.172, 0.223),
  float3(0.270, 0.156, 0.235),    // #45283c
  float3(0.243, 0.149, 0.227),
  float3(0.215, 0.145, 0.223),
  float3(0.188, 0.137, 0.215),
  float3(0.160, 0.133, 0.211),
  float3(0.133, 0.125, 0.203),    // #222034
  float3(1.0, 1.0, 1.0),        // control colors from here on. To watch for overflows
  float3(1.0, 0.8, 0.8),
  float3(1.0, 0.6, 0.6),
  float3(1.0, 0.4, 0.4),
  float3(1.0, 0.2, 0.2)
);

float rand(vec2 coord, float size, float seed) {
  coord = mod(coord, vec2(2.0,1.0)*round(size));
  return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 15.5453 * seed);
}

float noise(vec2 coord, float size, float seed){
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i, size, seed);
  float b = rand(i + vec2(1.0, 0.0), size, seed);
  float c = rand(i + vec2(0.0, 1.0), size, seed);
  float d = rand(i + vec2(1.0, 1.0), size, seed);

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord, float size, float seed){
  float value = 0.0;
  float scale = 0.5;

  for(int i = 0; i < OCTAVES ; i++){
    value += noise(coord, size, seed) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float circleNoise(vec2 uv, float size, float seed) {
    float uv_y = floor(uv.y);
    uv.x += uv_y*.31;
    vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x),floor(uv_y)), size, seed);
    float m = (length(f-0.25-(h*0.5)));
    float r = h*0.25;
    return smoothstep(0.0, r, m*0.75);
}

float turbulence(vec2 uv, float size, float seed) {
  float c_noise = 0.0;


  // more iterations for more turbulence
  for (int i = 0; i < 10; i++) {
    c_noise += circleNoise((uv * size *0.3) + (float(i+1)+10.) + (vec2(iTime * time_speed, 0.0)), size, seed);
  }
  return c_noise;
}

bool dither(vec2 uv_pixel, vec2 uv_real) {
  return mod(uv_pixel.x+uv_real.y,2.0/pixels) <= 1.0 / pixels;
}

vec2 spherify(vec2 uv) {
  vec2 centered= uv *2.0-1.0;
  float z = sqrt(1.0 - dot(centered.xy, centered.xy));
  vec2 sphere = centered/(z + 1.0);
  return sphere * 0.5+0.5;
}

vec2 rotate(vec2 vec, vec2 center, float angle)
{
  vec -= center;
  vec *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
  vec += center;
  return vec;
}

float3 colorSelection(float3 colors[15], float posterized) {
  int pos = int(floor(posterized * 9.5));
  return colors[pos];
}

float4 computePlanetUnder(float2 uv, bool dith)
{
  float light_d = distance(uv, light_origin);

  // stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
  float a = step(length(uv-vec2(0.5)), 0.49999);

  // rotate planet
  uv = rotate(uv, vec2(0.5), gaz_rotation);

  // map to sphere
  uv = spherify(uv);

  // a band is just one dimensional noise
  float band = fbm(vec2(0.0, uv.y*gaz_size*bands), gaz_size, gaz_seed);

  // turbulence value is circles on top of each other
  float turb = turbulence(uv, gaz_size, gaz_seed);

  // by layering multiple noise values & combining with turbulence and bands
  // we get some dynamic looking shape
  float fbm1 = fbm(uv*gaz_size, gaz_size, gaz_seed);
  float fbm2 = fbm(uv*vec2(1.0, 2.0)*gaz_size+fbm1+vec2(-iTime*time_speed,0.0)+turb, gaz_size, gaz_seed);

  // all of this is just increasing some contrast & applying light
  fbm2 *= pow(band,2.0)*7.0;
  float light = fbm2 + light_d*1.8;
  fbm2 += pow(light_d, 1.0)-0.3;
  fbm2 = smoothstep(-0.2, 4.0-fbm2, light);

  // apply the dither value
  if (dith) {
    fbm2 *= 1.1;
  }

  // finally add colors
  float posterized = floor(fbm2*4.0)/2.0;
  vec3 col;
  if (fbm2 < 0.625) {
    col = colorSelection(lightColors, posterized);
  } else {
    col = colorSelection(darkColors, posterized - 1.0);
  }

  return vec4(col, a);
}

float4 computeRing(float2 uv)
{
  uv = rotate(uv, vec2(0.5), ring_rotation * sin(iTime)*4.);
    uv += vec2(-0.5);
  float light_d = distance(uv, light_origin);


  // center is used to determine ring position
  vec2 uv_center = uv;

  // tilt ring
  uv_center *= vec2(0.4, ring_perspective);
  float center_d = distance(uv_center,vec2(0.));


  // cut out 2 circles of different sizes and only intersection of the 2.
  float ring = smoothstep(0.5-ring_width*2.0, 0.5-ring_width, center_d);
  ring *= smoothstep(center_d-ring_width, center_d, 0.4);

  // pretend like the ring goes behind the planet by removing it if it's in the upper half.
  if (uv.y > 0.1) {
      scale_rel_to_planet = 2.*radius;
    ring *= step(1./scale_rel_to_planet, distance(uv,vec2(0.0)));
  }

  // rotate material in the ring
  uv_center = rotate(uv_center+vec2(0, 0.5), vec2(0.5), iTime*time_speed);
  // some noise
  ring *= fbm(uv_center*ring_size, ring_size, ring_seed);

  // apply some colors based on final value
  float posterized = floor((ring*light_d)*8.0)/8.0;
  vec3 col;
  if (posterized <= 1.0) {
    col = colorSelection(lightColors, posterized);
  } else {
    col = colorSelection(darkColors, posterized - 1.0);
  }
  float ring_a = step(0.28, ring);
  return vec4(col, ring_a);
}

void mainImage(out vec4 COLOR, in vec2 UV)
{
    UV = UV/iResolution.xy;
    UV.x *= iResolution.x / iResolution.y;
    UV -= vec2(0.65, 0.25);
    UV *= 2.;
  vec2 uv = floor(UV*pixels)/pixels;

  // we use this value later to dither between colors
  bool dith = dither(uv, UV);

    light_origin = center - vec2(0.32*radius,0.32*radius);

    float4 planetRing = computeRing(uv);
  float4 result;

  // Optimized rendering. Don't calculate what you don't need to.
  if (planetRing.a != 0.0) {
    result = planetRing;
  }
  else
  {
    result = computePlanetUnder(uv, dith);
  }

  COLOR = result;
}
