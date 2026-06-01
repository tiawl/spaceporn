### Before starting

This tutorial is following:
- the [swirls grid tutorial](Swirls-grid)
- the [random tutorial](Random)
- the [randomize circles grid tutorial](Randomize-circles-grid)

If you did not, you should read it first

And optionally, you can also read:
- the [triangles texture tutorial](Triangles-texture)

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [nebula tutorial](Nebula)

### Tutorial

This tutorial will not go deeply in details because we already did this
in other tutorials. Instead of copy-pasting what is already written in
[this tutorial](Swirls-grid) and [this tutorial](Randomize-circles-grid), I
let you try to understand how you could use what we already made to randomize
the position of our swirls. Here the expected result:

|[[media/rd_pos_swirls_grid.png]]|
|:--:|

And here the fully commented answer:

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
  vec2 displacement;
  vec2 cell_center;
  vec2 displaced_cell_center;
  float dist;
  float angle;

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

      // Shape circled swirls
      dist = RADIUS - length(UV);

      // Smooth rotation angle of the circled swirl
      angle = smoothstep(0.0, RADIUS, dist);

      // Increase rotation for better visibility
      angle *= 2.23607;

      // Displace UV into a swirl
      UV = rotate(UV, angle);

      // And come back to its place
      UV += displaced_cell_center;
    }
  }

  // You can replace this function by your own texture
  vec3 rotated_texture = trianglesTexture(UV);

  fragColor = vec4(rotated_texture, 1.0);
}
```

If you want to go further, we can randomize the rotation angle and the
rotation direction by adding those lines before the main loop:

```glsl
  float direction;
  float intensity;
```

Adding this one in the main loop after
`displacement = vec2(hash(cell_center, 0u), hash(cell_center, 1u)) - vec2(0.5);`:

```glsl
      // Generate value between -1.5 and 1.5
      angle = hash(cell_center, 2u) * 3.0 - 1.5;
      direction = sign(angle);
      intensity = abs(angle);
```

And replacing this one in the main loop:

```glsl
      angle = smoothstep(0.0, RADIUS, dist);
```

By this one:

```glsl
      angle = smoothstep(0.0, RADIUS, dist * intensity) * direction;
```

We can also randomize the radius by removing this line:

```glsl
#define RADIUS 0.5
```

Adding this one before the main loop:

```glsl
  float radius;
```

Adding this one in the main loop after
`displacement = vec2(hash(cell_center, 0u), hash(cell_center, 1u)) - vec2(0.5);`:

```glsl
      radius = 0.25 + hash(cell_center, 3u) * 0.5;
```

And switching `RADIUS` occurences by `radius`.

To finally display:

|[[media/rd_swirls_grid.png]]|
|:--:|
