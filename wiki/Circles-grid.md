### Before starting

This tutorial is following:
- the [circled light tutorial](Circled-light)

If you did not, you should read it first

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [randomize circles grid tutorial](Randomize-circles-grid)
- the [swirls grid tutorial](Circles-grid)

### Tutorial

The goal of this tutorial is to find a more flexible way that using
duplicated `length(v)` builtin function calls to draw multiple circles. We
need to find a more flexible (and faster) way to draw our circles without
comparing each pixel coordinates to each circle we want to draw. An usual way
to achieve this is to draw a grid of primitives (here our primitive is a
circle).

As mentioned in the [circled light tutorial](Circled-light), the `length(v)`
builtin function returns the length of its parameter: the vector `v`. A vector
is expressed by the substraction between its 2 points. The center of our first
circle was the origin. So the other point of each of our vectors was the
origin and we used `length(UV)` as a simplified version of
`length(UV - vec2(0.0))`. But now we are drawing more than 1 circle and each
of them has an unique center. For each circle, its center will be an integer
point of our viewport. We will call this point `i`. So for each pixel of our
shader we will compare it to the nearest integer:
- for `vec2 v = vec2(0.2, 5.3)`, the nearest integer to `v.x` is `0` and the
nearest integer to `v.y` is `5`. So `vec2 i = vec2(0.0, 5.0)`,
- for `vec2 v = vec2(1.7, 2.3)`, the nearest integer to `v.x` is `2` and the
nearest integer to `v.y` is `2`. So `vec2 i = vec2(2.0, 2.0)`,
- for `vec2 v = vec2(8.8, 4.6)`, the nearest integer to `v.x` is `9` and the
nearest integer to `v.y` is `5`. So `vec2 i = vec2(9.0, 5.0)`.

The `round(x)` builtin function returns the nearest integer to `x`. This is
exactly what we need to find the center of our circles.

After that we need to translate our UV coordinates to the origin. We can
achieve this by substracting the center of our circle to the UV coordinates.
This allow us to consider the center of our circle as the origin. And we can
use again the `length(UV)` builtin function to display a circle.

We are going to use a 10 units height grid. First before drawing anything, we
are going to apply an unzoom to fully display this grid. After this unzoom, we
have to include our new way to draw circles:

```glsl
#define RADIUS 0.5

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 UV = fragCoord / iResolution.y;

  // Unzoom to get a 10 units height grid
  UV *= 10.0;

  // Center of the circle
  vec2 center = round(UV);

  // Translate to the origin
  UV -= center;

  // Revert color value and give a radius to the light depending how far the pixel is from the origin
  float dist = RADIUS - length(UV);

  // Multiply dist by 2.0 for better visibility
  fragColor = vec4(vec3(dist * 2.0), 1.0);
}
```

And we have a beautiful circles grid:

|[[media/circles_grid.png]]|
|:--:|

