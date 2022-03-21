# How to make a pixelized starfield in GLSL ?

This is a tutorial to explain how I made starfield from this
[shader](https://www.shadertoy.com/view/fsjBzy). I will follow same steps from
this [tutorial shader]() but I will go further to describe GLSL details.

## Before starting

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

## Table of contents

0) [Setup](0_setup.md)</br>
1) Circles</br>
1.1. [A circled light](1_1_a_circled_light.md)</br>
1.2. [Circles grid](1_2_circles_grid.md)</br>
1.3. [Randomize the circles grid](1_3_rd_circles_grid.md)</br>
1.4. [Use circles grid as a noise](1_4_noise_circles_grid.md)</br>
1.5. [Shape the circles grid](1_5_shape_circles_grid.md)</br>
2) Swirls</br>
3) Stars</br>
4) Details</br>

## Author

tiawl/trapped_in_a_while_loop
