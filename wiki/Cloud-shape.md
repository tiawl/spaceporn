### Before starting

This tutorial is following:
- the [parametrize circles grid tutorial](Parametrize-circles-grid)

If you did not, you should read it first

### Related shaders

You can play with these [shader]() when reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [nebula tutorial](Nebula)

### Tutorial

Our next goal is to give the circles a cloudy shape. For this task I am going
to use a voronoi texture because it is commonly use to draw clouds but you can
use any other noise function you want and apply same principles. Here the
voronoi function we are going to use:

```glsl
float voronoi(vec2 UV, float smoothness, uint seed)
{
  const vec2 i = floor(UV);
  const vec2 f = fract(UV);

  // Initialize loop variables
  vec3 col;
  vec2 displacement;
  vec2 p;
  float dist = 8.0;
  float tmp;
  float h;

  // Iterate over the current cell and its neighborhood
  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      p = vec2(x, y);
      displacement = vec2(hash(i + p, seed), hash(i + p, seed + 1u));
      tmp = length(p + displacement - f);

      col = 0.5 + 0.5 * sin(hash(i + p, seed + 2u) * 2.5 + 3.5 + vec3(2.0));
      h = smoothstep(0.0, 1.0, 0.5 + 0.5 * (dist - tmp) / smoothness);
      dist = mix(dist, tmp, h) - h * (1.0 - h) * smoothness / (1.0 + 3.0 * smoothness);
    }
  }

  return 1.0 - dist;
}
```

As you can see this function has some similarities with the `circles()`
function, we wrote in [this tutorial](Parametrize-circles-grid). If you want
more details about what is different between those two functions, you can read
this
[article](https://iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm).

Now, with this function, we are going to make a fractional brownian motion
version to get a cloudy shape looking. Below what this function is looking for
different octaves:

|[[media/voronoi_oct1.png]]|[[media/voronoi_oct2.png]]|[[media/voronoi_oct3.png]]|
|:--:|:--:|:--:|
|1 octave|2 octaves|3 octaves|

And that is it. We do not need more octaves, this is what we are looking for:
a cloudy shape. Here the function to get this image:

```glsl
float fbmVoronoi(vec2 UV, uint seed)
{
  return voronoi(1.5 * UV, 0.3, seed) * 0.625       // first octave
    + voronoi(3.0 * UV, 0.3, seed + 1u) * 0.25      // second octave
    + voronoi(6.0 * UV, 0.3, seed + 2u) * 0.125;    // third octave
}
```

We are going to modify the `mainImage()` function we used in
[this tutorial](Parametrize-circles-grid). First of all we are going to
increase contrast of the clouds. The `fbmVoronoi()` function returns a value
between `0.0` and `1.0`. So if we multiply the returned value by itself, more
this value is near from `1.0`, less this value should decrease:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // Uniformize coordinate system
  vec2 uv = fragCoord / iResolution.y;

  // Draw a cloudy shape
  float fv = fbmVoronoi(uv, 2u);

  // Increase contrast
  fv *= fv * 1.5;

  fragColor = vec4(vec3(fv), 1.0);
}
```

And this is what the clouds looks:

|[[media/voronoi_contrast.png]]|
|:--:|
