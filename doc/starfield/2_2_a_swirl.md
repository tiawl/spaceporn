[&#8882; Previous page - Check pattern](2_1_check_pattern.md) | [Next page - Swirls grid &#8883;](2_3_swirls_grid.md)
---|---

---

# 2.2. A swirl

It is now time to draw our first swirl. Because we are going to use swirls to
displace things we drawn, we are not really drawing them. We are going to
displace UV and then we will draw something (which will look swirly). For this
task we are going to use a function we already used before: the
`rotate(UV, angle)` function. I used this function in the
[2.1. Check pattern](2_1_check_pattern.md) section. If you did not follow this
section because you want to displace something you drawn by yourself, here the
function I am talking about:

```glsl
vec2 rotate(vec2 UV, float angle)
{
  return UV * mat2(cos(angle), -sin(angle),
                   sin(angle),  cos(angle));
}
```

If you have no idea how this function was built, here
[the Wikipedia page of the 2D vectorial rotation](https://en.wikipedia.org/wiki/Rotation_(mathematics)#Two_dimensions)
(Don't be afraid: unlike some other heavy maths article on Wikipedia, the
linked section of this Wikipedia page is short and maths are simple).
Reminder: `angle` parameter is quantified in radians (not in degrees).

Ok, now if we use this `rotate(UV, angle)` function, how to complete `UV` and
`angles` parameters ? For `UV`, we are going to use centered UV coordonates to
display our swirl. For `angle`, we have to give the swirl angle, but how to
find it ? It depends of the shape of our swirl. Here we want to display a
circled swirl so we are going to use the `length(v)` builtin function we used
before to draw our circles. Because we want that the nearer is a point from
the swirl's center, the more displaced it is, we have to revert the
`length(v)` returned value. But now the returned value is between `0.0` and
`-∞`. We have to add a value to increase the maximum returned  value (which is
`0.0` right now). The greater will be this value, the greater will be the
swirl radius.

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 UV = fragCoord / iResolution.y;

  // Displace UV to the center of the viewport
  vec2 centered_UV = UV - vec2(1.0, 0.5);

  // Rotation angle of the circled swirl
  //float rotation = 0.5-min(length(centered_UV), 0.5);
  float rotation = 5.0 * (1.0 - smoothstep(0.0, 0.5, length(centered_UV)));

  // Displace UV into a swirl
  UV = rotate(centered_UV, rotation);

  // First check pattern
  float squares = 2.0;
  vec2 truncated_UV = floor(UV * squares);
  bool is_brighter = mod(truncated_UV.x + truncated_UV.y, 2.0) < 1.0;

  // Second ckeck pattern
  squares = sqrt(2.0);
  UV = rotate(UV, 0.7853);
  truncated_UV = floor(UV * squares);
  bool is_brighter2 = mod(truncated_UV.x + truncated_UV.y, 2.0) < 1.0;

  fragColor = vec4(vec3(0.2 + (is_brighter ^^ is_brighter2 ? 0.2 : 0.0)), 1.0);
}
```

---

[&#8882; Previous page - Check pattern](2_1_check_pattern.md) | [Next page - Swirls grid &#8883;](2_3_swirls_grid.md)
---|---
