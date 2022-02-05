// iChannel0 = BufferA
// iChannel1 = Keyboard

const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch( iChannel0, ivec2(fragCoord), 0);
    float up = texelFetch( iChannel1, ivec2(KEY_UP, 0), 0).x;
    float down = texelFetch( iChannel1, ivec2(KEY_DOWN, 0), 0).x;
    float right = texelFetch( iChannel1, ivec2(KEY_RIGHT, 0), 0).x;
    float left = texelFetch( iChannel1, ivec2(KEY_LEFT, 0), 0).x;
    if ((up > 0.5) && (sign(fragColor.x) < 0.5))
    {
      fragColor.x = abs(fragColor.x);
      fragColor.x += 10.;
    } else if ((up < 0.5) && (sign(fragColor.x) > 0.)) {
      fragColor.x = -1. * fragColor.x;
    }
    if ((down > 0.5) && (sign(fragColor.y) < 0.5))
    {
      fragColor.y = abs(fragColor.y);
      fragColor.y += 1.;
    } else if ((down < 0.5) && (sign(fragColor.y) > 0.)) {
      fragColor.y = -1. * fragColor.y;
    }
    if ((right > 0.5) && (fragColor.z < R.y))
    {
      fragColor.z += 1.;
    }
    if ((left > 0.5) && (fragColor.z > 50.))
    {
      fragColor.z -= 1.;
    }
    if ( iFrame < 1 ) fragColor = vec4(0., 0., 100., 0.); 
}
