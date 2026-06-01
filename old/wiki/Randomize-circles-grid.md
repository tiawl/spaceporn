### Before starting

This tutorial is following:
- the [circles grid tutorial](Circles-grid)
- the [random tutorial](Random)

If you did not, you should read it first

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [parametrize circles grid tutorial](Parametrize-circles-grid)
- the [randomize swirls grid tutorial](Randomize-swirls-grid)

### Tutorial

Our circles grid is a little bit "well-organized". We want to give it a more
"natural" aspect. We need to randomize some parameters (mainly radius and
position of our circles). We can use the `hash()` function we are using
[here](Random) on our grid to displace our circles:
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

  // Generate values between -0.5 and 0.5
  vec2 displacement = vec2(hash(center, 0u), hash(center, 1u)) - vec2(0.5);

  // Factorization variable
  vec2 displaced_cell_center = center + displacement;

  // Translate UV to the origin
  UV -= displaced_cell_center;

  // Display circles
  float dist = RADIUS - length(UV);

  // Multiply dist by 2.0 for better visibility
  fragColor = vec4(vec3(dist * 2.0), 1.0);
}
```

The `hash()` function generates a float between `0.0` and `1.0`. Even if it
will not change the final result, we also want to display circles' center with
negative values. So we substract `hash()` results by `0.5`. We are giving
`center` variable to the `hash()` function to displace each pixel of a circle
with the same value. We are using `hash()` function two times with two
different seed parameter (`0u` and `1u`) to displace circles center with two
different values. And here the result:

|[[media/error1.png]]|
|:--:|

This is not really what we expected, so what is happening ? The problem is
that we are using the `round()` function. Because of this, our circles are
only considering points with distance less than `0.5`. If a point exceeds
this limit, it is not considered for the current circle. And this is what we
are facing now: The maximum radius of a circle is `0.5`. The maximum
displacement is `0.5` horizontally and `0.5` vertically so
[[media/maths8.png]]. So the maximum distance for a point is
[[media/maths7.png]], which is greater than `0.5`. This is what this GIF is
highlighting:

|[[media/error.gif]]|
|:--:|

We need to increase this radius. To achieve this, for each pixel we will visit
the current cell and its 8 neighbours to check if it is part of one of their
circles. The current cell is `vec2(0.0, 0.0)`, so the bottom-left one is
`vec2(-1.0, -1.0)` and the top-right one is `vec2(1.0, 1.0)`.

|[[media/neighbours.png]]|
|:--:|

But is it enough ? If we take the 8 neighbours around the current cell, the
maximum covered distance is now `1.5` in each direction (`0.5` for the current
cell and `1.0` for the neighbour). So yes it is enough ! Here our new code:

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

  // Initialize loop variables
  vec2 cell_center;
  vec2 displacement;
  vec2 displaced_cell_center;

  // Initialize this variable with a minimum value
  float dist = 0.0;

  // Iterate over the current cell and its neighborhood
  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      // Center of one of the neighbor circle
      cell_center = center + vec2(x, y);

      // Generate values between -0.5 and 0.5 for current cell
      displacement = vec2(hash(cell_center, 0u), hash(cell_center, 1u)) - vec2(0.5);

      // Factorization variable
      displaced_cell_center = cell_center + displacement;

      // Translate UV to the origin
      UV -= displaced_cell_center;

      // Keep the maximum light value
      dist = max(dist, RADIUS - length(UV));

      // And come back to its place
      UV += displaced_cell_center;
    }
  }

  // Multiply dist by 2.0 for better visibility
  fragColor = vec4(vec3(dist * 2.0), 1.0);
}
```

And the displayed result is:

|[[media/displaced.png]]|
|:--:|

We can also randomize the radius by removing this line:

```glsl
#define RADIUS 0.5
```

Adding this one before the main loop:

```glsl
  float radius;
```

And adding this one in the main loop after
`displacement = vec2(hash(cell_center, 0u), hash(cell_center, 1u)) - vec2(0.5);`:

```glsl
      radius = 0.25 + hash(cell_center, 2u) * 0.5;
```

And switching `RADIUS` occurences by `radius`.
