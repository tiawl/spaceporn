[&#8882; Previous page - A swirl](2_2_a_swirl.md) | [Next page - A cross &#8883;](3_1_a_cross.md)
---|---

---

# 2.3. Swirls grid

For this section we are going to use the same method we used previously with
circles to make more swirls.

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

vec2 rotate(vec2 UV, float angle)
{
  return UV * mat2(cos(angle), -sin(angle),
                   sin(angle),  cos(angle));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 UV = fragCoord / iResolution.y;
  UV *= 10.0;

  // Swirl radius
  float radius = 0.5;

  vec2 center = round(UV);
  vec2 displacement;
  vec2 cell_center;
  float rotation;

  for (int x = -1; x <= 1; x++)
  {
    for (int y = -1; y <= 1; y++)
    {
      cell_center = center + vec2(x, y);
      displacement = vec2(hash(cell_center, 0u), hash(cell_center, 1u)) - vec2(0.5);

      // Smooth rotation angle of the circled swirl
      rotation = smoothstep(0.0, radius, radius - length(UV + displacement - center));

      // Increase rotation for better visibility
      rotation *= sqrt(5.0);

      // Displace UV into a swirl
      UV = rotate(UV - center, rotation);
    }
  }

  // Check pattern: you can replace those lines by your own drawing
  float squares = 2.0;
  vec2 truncated_UV = floor(UV * squares);
  bool is_brighter = mod(truncated_UV.x + truncated_UV.y, 2.0) < 1.0;
  squares = sqrt(2.0);
  UV = rotate(UV, 0.7853);
  truncated_UV = floor(UV * squares);
  bool is_brighter2 = mod(truncated_UV.x + truncated_UV.y, 2.0) < 1.0;
  fragColor = vec4(vec3(0.2 + (is_brighter ^^ is_brighter2 ? 0.2 : 0.0)), 1.0);
}
```

---

[&#8882; Previous page - A swirl](2_2_a_swirl.md) | [Next page - A cross &#8883;](3_1_a_cross.md)
---|---
