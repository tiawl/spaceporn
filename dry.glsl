float pixels = 200.;
float rotation = 0.0;
vec2 light_origin = vec2(0.39, 0.39);
float light_distance1 = 0.362;
float light_distance2 = 0.525;
float time_speed = 0.2;
float dither_size = 2.0;
float size = 8.0;
int OCTAVES = 3;
float seed = 1.175;

float rand(vec2 coord) {
	// land has to be tiled
	// tiling only works for integer values, thus the rounding
	// it would probably be better to only allow integer sizes
	// multiply by vec2(2,1) to simulate planet having another side
	coord = mod(coord, vec2(2.0,1.0)*round(size));
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 43758.5453 * seed);
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES ; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

bool dither(vec2 uv1, vec2 uv2) {
	return mod(uv1.x+uv2.y,2.0/pixels) <= 1.0 / pixels;
}

vec2 rotate(vec2 coord, float angle){
	coord -= 0.5;
	coord *= mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	return coord + 0.5;
}

vec2 spherify(vec2 uv) {
	vec2 centered= uv *2.0-1.0;
	float z = sqrt(1.0 - dot(centered.xy, centered.xy));
	vec2 sphere = centered/(z + 1.0);
	return sphere * 0.5+0.5;
}


void mainImage(out vec4 COLOR, in vec2 UV) {
    const vec3 color1 = vec3(1.000, 0.537, 0.200);
    const vec3 color2 = vec3(0.898, 0.266, 0.219);
    const vec3 color3 = vec3(0.674, 0.184, 0.266);
    const vec3 color4 = vec3(0.317, 0.196, 0.243);
    const vec3 color5 = vec3(0.239, 0.156, 0.211);
	//pixelize uv
      UV = UV/iResolution.xy;
    UV.x *= iResolution.x / iResolution.y;
	vec2 uv = floor(UV*pixels)/pixels;
	bool dith = dither(uv, UV);
	
	// cut out a circle
	float d_circle = distance(uv, vec2(0.5));
	float a = step(d_circle, 0.49999);
	
	uv = spherify(uv);
	
	// check distance distance to light
	float d_light = distance(uv , vec2(light_origin));
	
	uv = rotate(uv, rotation);
	
	// noise
	float f = fbm(uv*size+vec2(iTime*time_speed, 0.0));
	
	// remap light
	d_light = smoothstep(-0.3, 1.2, d_light);
	
	if (d_light < light_distance1) {
		d_light *= 0.9;
	}
	if (d_light < light_distance2) {
		d_light *= 0.9;
	}
	
	
	float c = d_light*pow(f,0.8)*3.5; // change the magic nums here for different light strengths
	
	// apply dithering
	if (dith) {
		c += 0.02;
		c *= 1.05;
	}
	
	// now we can assign colors based on distance to light origin
	float posterize = floor(c*4.0)/4.0;
	vec3 col;
    if (posterize < 0.25)
	{
		col = color1;
	}
	else if (posterize < 0.40)
	{
		col = color2;
	}
	else if (posterize < 0.65)
	{
		col = color3;
	}
	else if (posterize < 0.80)
	{
		col = color4;
	}
	else {
		col = color5;
	}
	
	
	COLOR = vec4(col, a);
}
