// BufferA
// iChannel0 = BufferA
// iChannel1 = Keyboard

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch( iChannel0, ivec2(fragCoord), 0);
    if (texelFetch( iChannel1, ivec2(38,0),0 ).x > 0.)
      fragColor += vec4(10., 0., 0., 0.);
    if ( iFrame < 1 ) fragColor = vec4(0.); 
}
