### Before starting

This tutorial is following:
- the [swirl tutorial](Swirl)
- the [circles grid tutorial](Circles-grid)

If you did not, you should read it first

And optionally, you can also read:
- the [triangles texture tutorial](Triangles-texture)

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [randomize swirls grid tutorial](Randomize-swirls-grid)

### Tutorial

This tutorial will not go deeply in details because we already did this
in other tutorials. Instead of copy-pasting what is already written in
[this tutorial](Swirl) and [this tutorial](Circles-grid), I let you try to
understand how you could use what we already made to draw a beautiful swirls
grid. Here the expected result:

|[[media/swirls_grid.png]]|
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

  // Translate UV to the origin
  UV -= center;

  // Shape circled swirls
  float dist = RADIUS - length(UV);

  // Smooth rotation angle of the circled swirl
  float angle = smoothstep(0.0, RADIUS, dist);

  // Increase rotation for better visibility
  angle *= 2.23607;

  // Displace UV into a swirl
  UV = rotate(UV, angle);

  // You can replace this function by your own texture
  vec3 rotated_texture = trianglesTexture(UV);

  fragColor = vec4(rotated_texture, 1.0);
}
```
