### Before starting

If you did not, you should read:
- the [home page](home)

### Going further

After this tutorial you can read:
- the [circled light tutorial](Circled-light)
- the [triangles texture tutorial](Triangles-texture)
- the [swirl tutorial](Swirl)
- the [random tutorial](Random)

### Required tool

Each shader in this wiki are written and illustrated with
[Shadertoy](https://www.shadertoy.com/new). It is one of the online tool
letting you play interactively with WebGL 2.0 shaders. You can get the same
result on your own Shadertoy session. There are very minor changes between
Shadertoy's shaders and GLSL shader. So it will not be hard to translate for
your own needs.

### Synchronize our viewports

Here is our main function:
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
}
```
This function will be called for each pixel of our viewport:
- `fragColor` is the pixel color where each of its `vec4` channel match to a
RGBA channel. Each one of the `fragColor` channel has to be between `0.0` and
`1.0`. If a `fragColor` channel value is not in this interval, **the visual
result is clamped**. `fragColor` is the ouput of our fragment shader.
- `fragCoord` is the pixel coordinates. So if your viewport is your entire
screen and your screen's resolution are **1920x1080**, your first pixel
coordinates are `(0.0, 0.0)` and your last pixel coordinates are
`(1919.0, 1079.0)`. `fragCoord` is the input of our fragment shader.

Before displaying something on our viewport the very first step will be to
uniformize our coordinate system. Depending of our viewport size, the
coordinates system of our shaders are not the same. My viewport is my
entire screen and its resolution is **1920x1080**. Maybe your viewport is
only a **640x360** pixels square of your **1280x1024** screen. Or maybe
its your entire **1280x1024** screen. Whatever our hardware and our viewport
we are using we have to find a way to see the same thing on our screens. For
this reason we can't work with `fragCoord`, we have to translate this system
in UV system. The better way to achieve this, is to add this line in our
`mainImage()` function:
```glsl
  vec2 UV = fragCoord / iResolution.y;
```
`iResolution` is a Shadertoy specific variable. It is defined as: "The
viewport resolution". So `iResolution.y` is our height resolution and now
instead of this coordinate system:

|[[media/fragcoord_sys.png]]|
|:--:|

We have this one:

|[[media/uvcoord_sys.png]]|
|:--:|

And we have the same Y axis. Now, it is time to draw something !
