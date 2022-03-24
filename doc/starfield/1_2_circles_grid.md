[Previous page: A circled light &#8882;](1_1_a_circled_light.md)] | [&#8883; Next page: Randomize the circles grid](1_3_rd_circles_grid.md)

---

# 1.2. Circles grid

We saw in the last section of this tutorial that drawing a circle could be
done with the *length(v)* builtin function. But what if we want to draw 2
circles ? We can duplicate the *length(v)* function call. But for 3 circles ?
And for 100 circles or more ? We can not duplicate the *length(v)* function
call for each circle we need to draw. We need to find a more flexible (and
faster) way to draw our circles without comparing each pixel coordinates to
each *length(v)* call.

```
  vec2 UV = 10. * fragCoord / iResolution.y;

  vec2 fractional = fract(UV);

  float maximum = -1e9;
  float tmp;
  float radius = 0.5;
  for (int x = -1; x < 2; x++)
  {
    for (int y = -1; y < 2; y++)
    {
      tmp = radius - length(vec2(x, y) - fractional);
      maximum = max(maximum, tmp);
    }
  }

  fragColor = vec4(vec3(d), 1.);
```

---

[Previous page: A circled light &#8882;](1_1_a_circled_light.md)] | [&#8883; Next page: Randomize the circles grid](1_3_rd_circles_grid.md)
