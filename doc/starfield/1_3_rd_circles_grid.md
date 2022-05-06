[&#8882; Previous page: Circles grid](1_2_circles_grid.md) | [Next page: Parametrize circles grid &#8883;](1_4_param_circles_grid.md)
---|---

---

# 1.3. Randomize the circles grid

The next step of this tutorial is to give our grid a less "well-organized"
aspect. We need to randomize some parameters (mainly radius and position of
our circles). Unfortunely, GLSL does not provide a `rand()` builtin-function.
However, many people worked on this subject to build `hash()` functions which
simulate random. For this reason we are going to pick one of them. I choosed
this one:

```glsl
uvec3 pcg3d(uvec3 v)
{
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return v;
}

float hash(vec2 s, uint hash_seed)
{
  float res;
  uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y));
  uvec3 p = pcg3d(uvec3(u.x, u.y, hash_seed));
  res = float(p) * (1.0 / float(0xffffffffu));
  return res;
}
```

Because this subject is out of the scope of this tutorial and also because I
will fail to explain what is really happening in these functions, I am not
going to try. However if you want answers, you can follow those links and come
back later:
- [How to build a hash function ?](https://nullprogram.com/blog/2018/07/31/)
- [How to evaluate a hash function ?](https://www.jcgt.org/published/0009/03/02/)
- [How PCG hash function works ?](https://www.pcg-random.org/paper.html)

I choosed this function because:
- it is a 3D function and we are working with 2D coordinates. So I can use the
Z axis parameter to simulate the seeding of the `hash()` function,
- the "How to evaluate a hash function ?" article evalutes this `hash()`
function as a good one.

What does really matter is that you can choose the `hash()` function you want.
So if you do not like mine you can replace it by yours.

Whatever the `hash()` function you choosed, with those lines (and minor
modifications depending of your `hash()`):
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  fragColor = vec4(vec3(hash(fragCoord, 0u)), 1.0);
}
```

You should see this:

|![](media/hash.png)|
|:--:|

Now we can use this on our grid and displace our circles:
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 UV = fragCoord / iResolution.y;
  UV *= 10.0;

  vec2 center = round(UV);

  // Generate values between -0.5 and 0.5
  vec2 displacement = vec2(hash(center, 0u), hash(center, 1u)) - vec2(0.5);

  float radius = 0.5;

  // Displace the center of our circle
  float dist = radius - length(UV + displacement - center);

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

|![](media/error1.png)|
|:--:|

This is not really what we expected, so what is happening ? The problem is
that we are using the `round()` function. Because of this, our circles are
only considering points with distance less than `0.5`. If a point exceeds
this limit, it is not considered for the current circle. And this is what we
are facing now: The maximum radius of a circle is `0.5`. The maximum
displacement is `0.5` horizontally and `0.5` vertically so
![](https://latex.codecogs.com/svg.image?displacement_{max}=\sqrt{0.5*0.5&plus;0.5*0.5}=\sqrt{0.5}\approx0.707).
So the maximum distance for a point is
![](https://latex.codecogs.com/svg.image?displacement_{max}&plus;radius_{max}\approx0.5&plus;0.707\approx1.207),
which is greater than `0.5`. This is what this GIF is highlighting:

|![](media/error.gif)|
|:--:|

We need to increase this radius. To achieve this, for each pixel we will visit
the current cell and its 8 neighbours to check if it is part of one of their
circles. The current cell is `vec2(0.0, 0.0)`, so the bottom-left one is
`vec2(-1.0, -1.0)` and the top-right one is `vec2(1.0, 1.0)`.

|![](media/neighbours.png)|
|:--:|

But is it enough ? If we take the 8 neighbours around the current cell, the
maximum covered distance is now `1.5` in each direction (`0.5` for the current
cell and `1.0` for the neighbour). So yes it is enough ! Here our new code:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 UV = fragCoord / iResolution.y;
  UV *= 10.0;

  vec2 center = round(UV);
  vec2 cell_center;
  vec2 displacement;
  float radius = 0.5;

  // Initialize this variable with a minimum value
  float dist = 0.0;

  // Iterate over the current cell and its neighborhood
  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      cell_center = center + vec2(x, y);

      // Generate values between -0.5 and 0.5 for current cell
      displacement = vec2(hash(cell_center, 0u), hash(cell_center, 1u)) - vec2(0.5);

      // Keep the maximum light value
      dist = max(dist, radius - length(UV + displacement - cell_center));
    }
  }

  fragColor = vec4(vec3(dist * 2.0), 1.0);
}
```

And the displayed result is:

|![](media/displaced.png)|
|:--:|

We can also randomize the radius by adding this line in the main loop:

```glsl
      radius = 0.25 + hash(cell_center, 2u) * 0.5;
```

---

[&#8882; Previous page: Circles grid](1_2_circles_grid.md) | [Next page: Parametrize circles grid &#8883;](1_4_param_circles_grid.md)
---|---
