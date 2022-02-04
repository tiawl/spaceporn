// BufferA
// iChannel0 = BufferA
// iChannel1 = Keyboard

const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch( iChannel0, ivec2(fragCoord), 0);
    float up = texelFetch( iChannel1, ivec2(KEY_UP, 2), 0).x;
    float down = texelFetch( iChannel1, ivec2(KEY_DOWN, 2), 0).x;
    if (up != fragColor.y)
    {
      fragColor.x += 10.;
      fragColor.y = up;
    }
    if (down != fragColor.w)
    {
      fragColor.z += 1.;
      fragColor.w = down;
    }
    if ( iFrame < 1 ) fragColor = vec4(0.); 
}
