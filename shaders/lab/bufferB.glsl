const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

//iChannel0 BufferB
//iChannel1 Keyboard
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    float up = texelFetch(iChannel1, ivec2(KEY_UP, 0), 0).x;
    float down = texelFetch(iChannel1, ivec2(KEY_DOWN, 0), 0).x;
    float right = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x;
    float left = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x;

    if ((up > 0.5))
    {
      fragColor = vec4(iTime, 1., 0., 0.);
    }
    
    if ((iTime - fragColor.x > 1.) || (iFrame < 1))
    {
      fragColor = vec4(0.);
    }
}
