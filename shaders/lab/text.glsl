int char_id = -1;
vec2 char_pos, dfdx, dfdy;

void char(vec2 p, int c)
{
    vec2 dFdx = dFdx(p / 16.), dFdy = dFdy(p / 16.);
    if (p.x > 0.23 && p.x < 0.77 && p.y > 0. && p.y < 1.)
      char_id = c, char_pos = p, dfdx = dFdx, dfdy = dFdy;
}

vec4 draw_char()
{
    int c = char_id;
    vec2 p = char_pos;
    float r = 1. / 2048.;
    vec4 t = (c < 0 ? vec4(0., 0., 0., 1e5) :
      (textureGrad(iChannel0, p / 16. + fract(vec2(c, 15 - c / 16) / 16.), dfdx, dfdy) * 2. +
      textureGrad(iChannel0, p / 16. + fract(vec2(c, 15 - c / 16) / 16.) + r, dfdx, dfdy) +
      textureGrad(iChannel0, p / 16. + fract(vec2(c, 15 - c / 16) / 16.) + vec2(r, -r), dfdx, dfdy) +
      textureGrad(iChannel0, p / 16. + fract(vec2(c, 15 - c / 16) / 16.) + vec2(-r, r), dfdx, dfdy) +
      textureGrad(iChannel0, p / 16. + fract(vec2(c, 15 - c / 16) / 16.) - r, dfdx, dfdy)
    ) / 6.);
    float a = 1. - smoothstep(0., 1., smoothstep(0.505, 0.52, t.w));
    float b = smoothstep(0., 1., smoothstep(0.48, 0.505, t.w));
    return vec4(mix(vec3(1.), vec3(0.), b), a);
}

int CAPS=0;
#define low CAPS=32;
#define caps CAPS=0;
#define C(c) U.x-=.54; char(U, 64+CAPS+c);
#define __ caps C(-32)
#define _ __ low

void mainImage(out vec4 O, in vec2 u)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = u / iResolution.y;
    vec2 U = (uv + vec2(.05, -0.85)) * 8.;
    caps C(8) low C(15)C(23) _ C(20)C(15) _ C(13)C(1)C(11)C(5) _ C(20)C(8)C(9)C(19)
    O = draw_char();
    O = (O.w <= 0. ? vec4(1., 0., 0., 1.) : (0.6 + 0.6 * cos(6.3 *
      ((u.x * 6. - iResolution.x * 0.25) / (3.14 * iResolution.y)) + vec4(0., 23., 21., 0.))
      * 0.85 + 0.15) * O);
}
