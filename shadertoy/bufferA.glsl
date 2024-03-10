/*
  # define VIDEO_LENGTH 26. // Part 1
  # define VIDEO_LENGTH 21. // Part 2
  # define VIDEO_LENGTH 19. // Part 3
  # define VIDEO_LENGTH 21. // Part 4
*/

/*
 * Char Map, chars written with "0xab" a is X coord b is Y coord :
 *
 *    0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
 * 1
 * 2     !                    (  )     +     -  .  /
 * 3  0  1  2  3  4  5  6  7  8  9     ;           ?
 * 4  @  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O
 * 5  P  Q  R  S  T  U  V  W  X  Y  Z  [  \  ]  ^  _
 * 6     a  b  c  d  e  f  g  h  i  j  k  l  m  n  o
 * 7  p  q  r  s  t  u  v  w  x  y  z
 * 8
 *
 */

# define BufferAChannel  iChannel0
# define KeyboardChannel iChannel1

# define KEY_LEFT  37
# define KEY_RIGHT 39

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  fragColor = texelFetch(BufferAChannel, ivec2(fragCoord), 0);
  float right = texelFetch(KeyboardChannel, ivec2(KEY_RIGHT, 0), 0).x;
  float left = texelFetch(KeyboardChannel, ivec2(KEY_LEFT, 0), 0).x;
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
    fragColor = vec4(texelFetch(KeyboardChannel, ivec2(0), 0).x, iResolution.y, 0., 0.);
  }
}
