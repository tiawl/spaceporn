[&#8882; Previous page: Parametrize circles grid](1_4_param_circles_grid.md) | [Next page: &#8883;]()
---|---

---

# 1.5. Shape the circles grid

Ok, we drew enough circles in this tutorial ! Now the goal is to give them a
cloudy shape. For this task I am going to use a voronoi pattern because it is
commonly use to draw clouds but you can use any other noise function you want
and apply same principles. Here the voronoi function we are going to use:

```glsl
float voronoi(vec2 UV, float smoothness, uint seed)
{
  vec3 col;
  vec2 i = floor(UV);
  vec2 f = fract(UV);
  vec2 displacement;
  vec2 p;

  float dist = 8.;
  float tmp;
  float h;

  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      p = vec2(x, y);
      displacement = vec2(hash(i + p, seed), hash(i + p, seed + 1u));
      tmp = length(p + displacement - f);

      col = 0.5 + 0.5 * sin(hash(i + p, seed + 2u) * 2.5 + 3.5 + vec3(2.));
      h = smoothstep(0., 1., 0.5 + 0.5 * (dist - tmp) / smoothness);
      dist = mix(dist, tmp, h) - h * (1. - h) * smoothness / (1. + 3. * smoothness);
    }
  }
  return 1. - dist;
}
```

As you can see this function has some similarities with the `circles()`
function, we wrote in the last step of this tutorial. If you want more details
about what is different with the function we wrote, you can read this
[article](https://iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm).

Now, like in this last step of this tutorial, we are going to make a fractional
brownian motion version of this function to get a cloudy shape looking.
Below what this function is looking for the first octave:

Below for 2 octaves:

Below for 3:

And that is it. We do not need more octaves, this is what we are looking for:
a cloudy shape. Here the function to get this image

```glsl
float fbmVoronoi(vec2 UV, uint seed)
{
  return voronoi(3. * UV, 0.3, seed) * 0.625      // first octave
    + voronoi(6. * UV, 0.3, seed + 1u) * 0.25     // second octave
    + voronoi(12. * UV, 0.3, seed + 2u) * 0.125;  // third octave
}
```

---

[&#8882; Previous page: Parametrize circles grid](1_4_param_circles_grid.md) | [Next page: &#8883;]()
---|---
