int char_id = -1;
vec2 char_pos, dfdx, dfdy;

vec4 char(vec2 p, int c)
{
    vec2 dFdx = dFdx(p / 16.), dFdy = dFdy(p / 16.);
    if (p.x > 0.25 && p.x < 0.75 && p.y > 0. && p.y < 1.)
      char_id = c, char_pos = p, dfdx = dFdx, dfdy = dFdy;
    return vec4(0.);
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
    float a = 1. - smoothstep(0., 1., smoothstep(0.51, 0.53, t.w));
    float b = smoothstep(0., 1., smoothstep(0.48, 0.51, t.w));
    return vec4(mix(vec3(1.), vec3(0.), b), a);
}

int CAPS=0;
#define low CAPS=32;
#define caps CAPS=0;
#define C(c) U.x-=.5; O+= char(U,64+CAPS+c);

void mainImage( out vec4 O, in vec2 u )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = u/iResolution.y;
    vec2 U = (uv + vec2(.05, -0.85)) * 8.; caps C(18) low C(5)C(19)C(15)C(12) caps C(-6)
    O = draw_char();
    O = (O.w <= 0. ? vec4(1., 0., 0., 1.) : O);
}
