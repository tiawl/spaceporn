### Before starting

This tutorial is following:
- the [setup tutorial](Setup)

If you did not, you should read it first

### Related shaders

You can play with these [shader](https://www.shadertoy.com/view/XlGcRh) when
reading this tutorial.

### Going further

This tutorial is used in these tutorials:
- the [randomize circles grid tutorial](Randomize-circles-grid)
- the [randomize swirls grid tutorial](Randomize-swirls-grid)

### Tutorial

Unfortunely, I have 2 bad news:
- GLSL does not provide a `rand()` or `random()` builtin function,
- this tutorial about random is not really a tutorial because I am not going
to explain how to write a random function.

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

Because this subject is out of the scope of this wiki and also because I
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

|[[media/hash.png]]|
|:--:|
