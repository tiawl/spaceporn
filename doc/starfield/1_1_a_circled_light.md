[Previous page: Setup &#8882;](0_setup.md) | [&#8883; Next page: Circles grid](1_2_circles_grid.md)

---

# 1.1. A circled light

For this shader, we have to draw a lot of circled light. So before going
further we need to understand how to draw a lonely circled light. One of the
easier way to achieve this is to use the *length(v)* builtin function. This
function returns the
[length of the vector](https://onlinemschool.com/math/library/vector/length/)
*v*. Giving the UV coordinates of the current pixel to the *length(v)*
function will return the distance between our pixel and the origin. So for
this script:

```
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 UV = fragCoord / iResolution.y;

  // Compute the distance between the current pixel and the origin
  float dist = length(UV);

  // Dislay the result
  fragColor = vec4(vec3(dist), 1.0);
}
```

We have this result (nearer is the point from the origin, darker it is):

![](media/dist.png)

First we need to center the result. We saw *iResolution* was the viewport
resolution. So we just uniformize this value, half it and substract it to our
pixel's UV coordinates to center the light. Finally, we have to revert the
color. To achieve this, we multiply the *length(UV)* function by *-1.0*. Now
the color value is between *0.0* and *-&infin;*. So if we display something,
we will see a black screen. We have to add a value to increase the maximum
color value (which is *0.0*). Greater this value will be, greater will be the
maximum color value and bigger will be our circle. This value will be its
radius.

```
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 UV = fragCoord / iResolution.y;

  // Uniformize viewport resolution
  vec2 res = iResolution.xy / iResolution.y;

  // Half it
  res /= 2.0;

  // Substract it to the pixel's UV coordinates
  UV -= res;

  float radius = 0.5;

  // Revert color value and give a radius to the light
  float dist = radius - length(UV);

  fragColor = vec4(vec3(dist), 1.0);
}
```

|![](media/light.png)|
|:--:|
|For better visibility on this picture, *dist* is multiplied by 2*|

---

[Previous page: Setup &#8882;](0_setup.md) | [&#8883; Next page: Circles grid](1_2_circles_grid.md)
