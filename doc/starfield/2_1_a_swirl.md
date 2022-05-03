[&#8882; Previous page - Shape the circles grid](1_5_shape_circles_grid.md) | [Next page - Swirls grid &#8883;](2_2_swirls_grid.md)
---|---

---

# 2.1. A swirl

This new chapter is also a fresh start: I promise we are not going to draw
a circle. Instead we are going to draw swirls. A lot of swirls. And what we
have already done before, will really speed up the process. But before drawing
swirls, we will draw a check pattern. For this shader we will draw swirls to
displace UV coordinates so we will only see our swirls if we have something to
displace. I choosed a check pattern because it gives our swirls a nice
looking but we are not going to use this check pattern in the main result of
this tutorial so you can use any pattern you want to highlight your swirls.

Drawing a check pattern can be done with the `floor()` builtin function. I
already talk about it in the last section of this tutorial. This allow us
to split UV coordinates system into squares thanks to its integer part. To
draw squares with alternate colors we need to check `S` the sum of the two
axis of the truncated UV. If the result is even it could be white. To check
the mathematic parity of the result, we can use the `mod(v, b)` builtin
function on `S`. If `mod(S, 2.0)` is less than `1.0`, `S` is even, so the
current pixel is white:

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 UV = fragCoord / iResolution.y;

  // Number of squares vertically
  float squares = 2.0;

  // Split UV cordinates system into squares
  vec2 truncated_UV = floor(UV * squares);

  // Check mathematic parity of the sum of the 2 axis of the truncated UV
  bool is_white = mod(truncated_UV.x + truncated_UV.y, 2.0) < 1.0;

  // If sum is odd, color is darker
  fragColor = vec4(vec3(0.2 + 0.2 * float(is_white)), 1.0);
}
```
```glsl
vec2 rotation(vec2 p, float a){return p * mat2(cos(a), -sin(a),sin(a),cos(a));}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 UV = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    //UV = rotation(UV, (1. - smoothstep(0., 0.5, length(UV))));

    float squares = 2.;
    vec2 UU = floor(UV * squares) / squares;
    bool d1 = mod(UV.x + UU.y, 2. / squares) < 1. / squares;

    squares = sqrt(squares);
    UV = rotation(UV, 0.7853);
    UU = floor(UV * squares) / squares;
    bool d2 = mod(UV.x + UU.y, 2. / squares) < 1. / squares;

    fragColor = vec4(vec3(0.2 + 0.2 * (float(d1 || d2) - float(d1 && d2))), 1.);
}
```

---

[&#8882; Previous page - Shape the circles grid](1_5_shape_circles_grid.md) | [Next page - Swirls grid &#8883;](2_2_swirls_grid.md)
---|---
