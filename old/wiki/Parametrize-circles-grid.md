### Before starting

This tutorial is following:
- the [randomize circles grid tutorial](Randomize-circles-grid)

If you did not, you should read it first

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [cloud shape tutorial](Cloud-shape)

### Tutorial

The script written in [this tutorial](Randomize-circles-grid) is a little bit
messy. It is not parametrable, not easily readable and reusable. We need to
rework on this to:
- avoid some headaches when reading what we done,
- to help us when drawing another circles grid.

Here is our new `circles()` function:

```glsl
float circles(vec2 UV, float r, uint seed)
{
  // Center of the circle
  vec2 center = round(UV);

  // Initialize loop variables
  vec2 cell_center;
  vec2 displacement;
  float radius;
  float dist = 0.0;

  // Iterate over the current cell and its neighborhood
  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      // Center of one of the neighbor circle
      cell_center = center + vec2(x, y);

      // Generate values between -0.5 and 0.5
      displacement = vec2(hash(cell_center, seed), hash(cell_center, seed + 1u)) - vec2(0.5);

      // Vary radius between r / 2.0 and r * 3.0 / 2.0
      radius = r / 2.0 + hash(cell_center, seed + 2u) * r;

      // Keep the maximum light value
      dist = max(dist, radius - length(UV + displacement - cell_center));
    }
  }

  return dist;
}
```

There are nothing new in this function except the 2 new parameters:
- `r` allows us to control circles radius without manipulating `UV`,
- `seed` to select a new "random" circles grid.

Now the main idea is to use the method described in this
[article](https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm) to write a
new function which will use our newly written `circles()` function:

```glsl
#define OCTAVES 2u

float fbmCircles(vec2 UV, uint seed)
{
  // Initialize loop variables
  float strength = 1.0;
  float new;
  float dist = -1.;

  // Iterate over octaves
  for (uint i = 0u; i < OCTAVES; i++)
  {
    // Evaluate new octave
    new = strength * circles(UV, 0.5, seed + i);

    // Add
    dist = smax(dist, new, 0.3 * strength);

    // Prepare new octave
    UV *= 2.0;
    strength *= 0.5;
  }

  return dist;
}
```

Those lines add a new circles grid with smaller radius after each looping:

|[[media/fbm.gif]]|
|:--:|

Here the `smax()` function used by `fbmCircles()` function:

```glsl
float smax(float a, float b, float k)
{
  float h = max(k - abs(a - b), 0.0);
  return max(a, b) + h * h * 0.25 / k;
}
```

You can find more details about this function in this
[article](https://iquilezles.org/www/articles/smin/smin.htm). This new
function is an interpolation function. This allow us to smooth intersections
between circles:

|[[media/max.png]]|[[media/smax.png]]|
|:--:|:--:|
| with `max()` | with `smax()` |

This is why we are going to include also this new function in `circles()`
function instead of `max()` usage. We are going to replace this line:

```glsl
      dist = max(dist, radius - length(UV + displacement - cell_center));
```

with this line:

```glsl
      dist = smax(dist, radius - length(UV + displacement - cell_center), 0.3);
```

With those 3 new functions, drawing circles can be achieved with only some
calls. Here is our new `mainImage()` function:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 UV = fragCoord / iResolution.y;

  // Unzoom to get a 10 units height grid
  UV *= 10.0;

  // Draw 2 layers of circles grid
  float dist = max(fbmCircles(UV, 0u), fbmCircles(UV, 5u));

  fragColor = vec4(vec3(dist), 1.0);
}
```

And the expected result:

|[[media/2layerscircles.png]]|
|:--:|

And that is it: we drew more circles than before but with a smaller
`mainImage()` function. Drawing a circles grid is now really simple !
