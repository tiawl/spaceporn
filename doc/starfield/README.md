# How to make a pixelized starfield in GLSL ?

This is a tutorial to explain how I made starfield from this
[shader](https://www.shadertoy.com/view/fsjBzy). I will follow same steps from
this [tutorial shader]() but I will go further to describe GLSL details.

## Before starting

If you did not, you should read this [README](/doc/README.md) first.

## Prerequites

The author assumes:
- you have maths knowledges (or at least curious and not afraid about
maths),
- you know what is a fragment shader,
- you already have basic knowlegde of GLSL shaders. At least about specific
types (*vec2*, *vec3*, *vec4*, *ivec2*, *uvec2*, *mat2*, ...) and built-in
functions (*abs()*, *sin()*, *floor()*, *fract()*, *length()*, ...).

If not, you can follow this tutorial but it will not be easy. So I advise you
to do some reading/testing first.

## Table of contents

0) [Setup](0_setup.md)</br>
1) Circles</br>
1.1. [A circled light](1_1_a_circled_light.md)</br>
1.2. [Circles grid](1_2_circles_grid.md)</br>
1.3. [Randomize the circles grid](1_3_rd_circles_grid.md)</br>
1.4. [Parametrize circles grid](1_4_param_circles_grid.md)</br>
1.5. [Shape the circles grid](1_5_shape_circles_grid.md)</br>
2) Swirls</br>
2.1. [Check pattern](2_1_check_pattern.md)</br>
2.2. [A swirl](2_2_a_swirl.md)</br>
2.3. [Swirls grid](2_3_swirls_grid.md)</br>
3) Stars</br>
3.1. [A cross](3_1_a_cross.md)</br>
3.2. [Crosses grid](3_2_crosses_grid.md)</br>
3.3. [Randomize the crosses grid](3_3_rd_crosses_grid.md)</br>
3.4. [Star types](3_4_star_types.md)</br>
4) [Details](4_details.md)</br>

## Author

tiawl/trapped_in_a_while_loop
