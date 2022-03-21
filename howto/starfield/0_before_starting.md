[&#8883; Next page: Nebula](1_nebula.md)

---

# Before starting

I'm not a pro graphic programmer. I did not receive a formal shadering
formation. I learned by myself (and from ressources I found on Internet). So I
will explain details the way I understand them. This is why:
- this tutorial can leak some knowledges and/or precision,
- I will, as mush as possible, link articles.
If you have better knowledges than mine and you found a mistake, I will be
very grateful if you can open an issue to fix it ! I will also be very
grateful if you can open an issue to share an article which could allow a
better understanding of this tutorial.

## Prerequites

I assume:
- you have maths knowledges (or at least curious and not afraid about
maths),
- you know what is a fragment shader,
- you already have basic knowlegde of GLSL shaders. At leat about specific
types (*vec2*, *vec3*, *vec4*, *ivec2*, *uvec2*, *mat2*, ...) and built-in
functions (*abs()*, *sin()*, *floor()*, *fract()*, *length()*, ...).

If not, you can follow this tutorial but it will not be easy. So I recommend
you to do some reading/testing first.

## Setup

In this tutorial we will only write a fragment shader. We do not need any
other shader to make it. We will write this shader on
[Shadertoy](https://www.shadertoy.com/new). It is one of the online tool
letting you play interactively with WebGL 2.0 shaders. So you can get the same
result on you own *Shadertoy* session if you copy-paste the script I am
writing. There are very minor changes between Shadertoy's shaders and GLSL
shader. So it will not be hard to translate the final result in a GLSL shader.

## Synchronize our viewports

Here is our main function:
```
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
}
```
This function will be called for each pixel of our screen.
*fragColor* is the pixel color where each of its *vec4* channel match to a
RGBA channel. Each one of the *fragColor* channel has to be between *0.0* and
*1.0*. If a *fragColor* channel value is not in this interval, the visual
result is clamped. *fragColor* is the ouput of our fragment shader.
*fragCoord* is the pixel coordinates. So if your screen's resolution are
1920x1080, your first pixel coordinates are *(0.0, 0.0)* and your last pixel
coordinates are *(1919.0, 1079.0)*. *fragCoord* is the input of our fragment
shader.

As you can see, now our *mainImage()* function is empty. We have to fill it to
display something on screen.

The first step is to uniformize our coordinate system. Depending of your
screen, the coordinates system of your shader is not the same as mine. My
screen's resolution are 1920x1080 but maybe your screen's resolution are
1280x1024. We have to find a way to see the same thing on our screens. For
this reason we can't work with *fragCoord*, we have to translate this system
in UV system. The better way to achieve this, is to add this line in our
*mainImage()* function:
```
  vec2 UV = fragCoord / iResolution.y;
```
*iResolution* is a Shadertoy specific variable. It is defined as: "The
viewport resolution". So *iResolution.y* is our height resolution. So now
instead of this coordinate system:

<img src="media/fragcoord_sys.png">

We have this one:

<img src="media/uvcoord_sys.png">

And we have the same Y axis. Now we can start to draw something.

---

[&#8883; Next page: Nebula](1_nebula.md)
