struct Star
{
  uint type;
  vec2 center;
  float size;
  float power;
  float brightness;
  uint shape;
  float diag;
  float ring_size;
};

float sdCircle(vec2 p, float r)
{
  return length(p) - r;
}

float opRing(vec2 p, float r1, float r2)
{
  return abs(sdCircle(p, r1)) - r2;
}

float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}
