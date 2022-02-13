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

float smin(float a, float b, float k, uint p)
{
  float h = max(k - abs(a - b), 0.) / k;
  float H = 1.;
  while (p > 0u)
  {
    H *= h;
    p -= 1u;
  }
  return min(a, b) - H * k * (1. /4.);
}
