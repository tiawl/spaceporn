/*
#define VIDEO_LENGTH 26. // Part 1
#define VIDEO_LENGTH 21. // Part 2
*/

const int KEY_LEFT  = 37;
const int KEY_RIGHT = 39;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
  float right = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x;
  float left = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x;
  if (right > 0.5 && fragColor.z < 0.5)
  {
    fragColor.z = 1.;
    fragColor.x += min(3., VIDEO_LENGTH - (iTime + fragColor.x));
  } else if (right < 0.5 && fragColor.z > 0.5 && fragColor.z < 1.5) {
    fragColor.z = 0.;
  }
  if (left > 0.5 && fragColor.z < 0.5)
  {
    fragColor.z = 2.;
    fragColor.x -= (iTime + fragColor.x > VIDEO_LENGTH ? iTime + fragColor.x - VIDEO_LENGTH : 0.);
    fragColor.x -= min(3., iTime + fragColor.x);
  } else if (left < 0.5 && fragColor.z > 1.5) {
    fragColor.z = 0.;
  }
  if (iFrame < 1)
  {
    fragColor = vec4(0., iResolution.y, 0., 0.);
  }
  if (fragColor.y != iResolution.y)
  {
    fragColor = vec4(texelFetch(iChannel0, ivec2(0), 0).x, iResolution.y, 0., 0.);
  }
}
