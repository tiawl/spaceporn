#version 450
#include "std/add.frag"

layout (location = 0) out vec4 o;

void main ()
{
  o = vec4 (add (0.25, 0.4));
}
