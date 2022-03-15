# How to make a pixelized starfield in GLSL ?

This is a tutorial to explain how I made starfield from this
[shader](https://www.shadertoy.com/view/fsjBzy). I will follow same steps from
this [tutorial shader]() and I will describe GLSL details.

## Before starting

I'm not a pro graphic programer. I did not receive a formal shadering
formation. I learned by myself (and from ressources I found on Internet). So I
will explain details the way I understand them. This is why this tutorial can
leak some knowledges and/or precision. If you have those knowledges and you
found a mistake, I will be very grateful if you open an issue to fix it !

### Prerequites

I assume that you know what is a fragment shader. I also assume you already
have basic knowlegde of GLSL shaders. At leat about specific types (*vec2*,
*vec3*, *vec4*, *ivec2*, *uvec2*, *mat2*, ...) and built-in functions
(*abs()*, *sin()*, *floor()*, *fract()*, *length()*, ...), if not, I recommend
you go do some reading/testing first.

### Setup

In this tutorial we will only write a fragment shader. We do not need any
other shader to make it. We will write this shader on
[Shadertoy](https://www.shadertoy.com/new). It is one of the online tool
letting you play interactively with WebGL 2.0 shaders. So you can get the same
result if you copy-paste **Result** section of each step on your own Shadertoy
session. There are very minor changes between Shadertoy's shaders and GLSL
shader. So it will not be hard to translate the final result in a GLSL shader.

## 1. A simple circle

Here is our main function:
```
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
}
```
This function will be called for each pixel of our screen.
*fragColor* is the pixel color where each field match to a RGBA field. Each
one of the *fragColor* field have to be between *0.0* and *1.0*. It is the
ouput of our fragment shader.
*fragCoord* is the pixel coordinates. So if your screen's resolution are
1920x1080, your first pixel coordinates are *(0.0, 0.0)* and your last pixel
coordinates are *(1919.0, 1079.0)*. It is the input of our fragment shader.

As you can see, now our *mainImage()* function is empty. We have to fill it to
display something on screen.

The first step is to uniformize our coordinate system. Depending of your
screen, the coordinates system of your shader is not the same as mine. My
screen's resolution are 1920x1080 but maybe your screen's resolution are
1280x1024. We have to find a way for you to see on your screen what I see on
mine. For this reason we can't work with *fragCoord*, we have to translate
this system in UV system. The better way to achieve this, is to add this line
in our *mainImage()* function:
```
  vec2 UV = fragCoord / iResolution.y;
```
*iResolution* is a Shadertoy specific variable. It is defined as: "The
viewport resolution". So *iResolution.y* is our height resolution. So now
instead of this coordinate system:

<img src="/howto/starfield/media/fragcoord_sys.png">

We have this one:

<img src="/howto/starfield/media/uvcoord_sys.png">

## Author

tiawl/trapped_in_a_while_loop
