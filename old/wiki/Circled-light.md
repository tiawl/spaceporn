### Before starting

This tutorial is following:
- the [setup tutorial](Setup)

If you did not, you should read it first

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [circles grid tutorial](Circles-grid)

### Tutorial

One of the easier way to draw a lonely circled light is to use the `length(v)`
builtin function. This function returns the
[length of the vector](https://onlinemschool.com/math/library/vector/length/)
`v`. Giving the UV coordinates of the current pixel to the `length(v)`
function will return the distance between our pixel and the origin. So the
further is a point from the origin, the greater is the `length(v)` returned
value. For this script:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 UV = fragCoord / iResolution.y;

  // Compute the distance between the current pixel and the origin
  float dist = length(UV);

  // Dislay the distance value
  fragColor = vec4(vec3(dist), 1.0);
}
```

What you should see (the nearer is the point from the origin, the darker it
is):

|[[media/dist.png]]|
|:--:|

First we need to center the result. We saw `iResolution` was the viewport
resolution. So we just uniformize this value, half it and substract it to our
pixel's UV coordinates to center the light. Finally, we have to revert the
color. To achieve this, we multiply the `length(UV)` function by `-1.0`. Now
the color value is between `0.0` and `-∞`. So if we display something,
we will see a black screen. We have to add a value to increase the maximum
color value (which is right now `0.0`). The greater will be this value, the
greater will be the maximum color value and the bigger will be our circle.
This value is our circle radius.

```glsl
#define RADIUS 0.5

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 UV = fragCoord / iResolution.y;

  // Uniformize viewport resolution
  vec2 res = iResolution.xy / iResolution.y;

  // Half it
  res /= 2.0;

  // Substract it to the pixel's UV coordinates
  UV -= res;

  // Revert color value and give a radius to the light
  float dist = RADIUS - length(UV);

  // Multiply dist by 2.0 for better visibility
  fragColor = vec4(vec3(dist * 2.0), 1.0);
}
```

|[[media/light.png]]|
|:--:|
