### Before starting

This tutorial is following:
- the [cloud shape tutorial](Cloud-shape)
- the [randomize swirls grid tutorial](Randomize-swirls-grid)

If you did not, you should read it first

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
-

### Tutorial

To draw our nebula we are going to modify the `mainImage()` function we used
in [this tutorial](Cloud-shape) to apply swirls we drawn in
[this tutorial](Randomize-swirls-grid).

### Style

It is ok but we want to give our clouds a more anime looking. To achieve this
we are going to reduce the colors. The `floor(v)` builtin function gives us a
simple way to do that. This function truncates the float parameter `v`.
Because it truncates `floor(v)` will decrease the light intensity of our
clouds. To avoid this, we will increase a little bit the light before. We can
use a constant for that:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 UV = fragCoord / iResolution.y;

  // Unzoom to get a 10 units height grid
  UV *= 10.0;

  // Draw 2 layers of circles grid
  float dist = max(fbmCircles(UV, 0u), fbmCircles(UV, 5u));

  // Increase light
  dist += 0.3;

  fragColor = vec4(vec3(dist), 1.0);
}
```

It is an effective and cheap way to increase the light but it is not nice to
look. Instead, we could use the `smax()` function we already used
[here](Parametrize-circles-grid). The goal is to take advantage of the
interpolation propriety of this function to get a more smoothy light. For this
we need to replace this line:

```glsl
  dist += 0.3;
```

by this line:

```glsl
  dist = smax(-1.0, dist, 3.2);
```

The `-1.0` magic number is a minimum value with what we interpolate the
circles grid.

It is now time to reduce colors: let suppose we only want 4 colors in our
shader. The only thing we have to do is to apply this formula:
`floor(v * COLOR_NUMBER) / COLOR_NUMBER`. So if the `v` value is in:
- the `[0.0; 0.25[` interval, this formula will return `0.0`,
- the `[0.25; 0.5[` interval, this formula will return `0.25`,
- the `[0.5; 0.75[` interval, this formula will return `0.5`,
- the `[0.75; 1.0[` interval, this formula will return `0.75`,

And this is how we have a more anime looking:

```glsl
#define COLORS 18.0

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 uv = fragCoord / iResolution.y;

  // Unzoom UV cordinates system for the circles grid
  vec2 UV = 10.0 * uv;

  // Draw 2 layers of circles grid
  float dist = max(fbmCircles(UV, 0u), fbmCircles(UV, 5u));

  // Draw a cloudy shape
  float fv = fbmVoronoi(uv, 2u);

  // Increase contrast and add a little bit of light on the cloud
  fv *= fv * 1.5;

  // Add a smooth light on the circles grid
  dist = smax(-1.0, dist, 3.2);

  // Apply cloudy shape on the circles grid
  dist *= fv;

  // Reduce colors number
  dist = floor(dist * COLORS) / COLORS;

  fragColor = vec4(vec3(dist), 1.0);
}
```

Here the expected result:

|[[media/final_1_5.png]]|
|:--:|
