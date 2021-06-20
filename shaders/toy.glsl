float pixels = 200.;
vec2 light_origin = vec2(0.5, 0.5);

// This rotation applies to both land and clouds. It can be split if needed
float rotation = 0.0;

// Land
float planet_time_speed = 0.1;
float planet_size = 4.6;
float river_cutoff = 0.368;
float dither_size = 3.951;
float light_border_1 = 0.52;
float light_border_2 = 0.62;
int planet_octaves = 5;

vec3 col1 = vec3(0.388, 0.670, 0.247);
vec3 col2 = vec3(0.231, 0.490, 0.309);
vec3 col3 = vec3(0.184, 0.341, 0.325);
vec3 col4 = vec3(0.156, 0.207, 0.250);
vec3 river_col = vec3(0.309, 0.643, 0.721);
vec3 river_col_dark = vec3(0.250, 0.286, 0.450);

// Clouds
float cloud_cover = 0.47;
float time_speed_clouds = 0.1;
float stretch = 2.0;
float cloud_curve = 1.3;
float light_border_clouds_1 = 0.52;
float light_border_clouds_2 = 0.62;

vec3 base_color = vec3(0.960, 1.000, 0.909);
vec3 outline_color = vec3(0.874, 0.878, 0.909);
vec3 shadow_base_color = vec3(0.407, 0.435, 0.6);
vec3 shadow_outline_color = vec3(0.250, 0.286, 0.450);

float size_clouds = 7.315;
int cloud_octaves = 2;

float rand(float size, vec2 sizeModifier, vec2 coord) {
	// land has to be tiled
	// tiling only works for integer values, thus the rounding
	// it would probably be better to only allow integer sizes
	// multiply by vec2(2,1) to simulate planet having another side
	coord = mod(coord, sizeModifier * round(size));

	// keep the number below small to avoid weird capping on frac (original: 43758.5453)
	return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(float size, vec2 sizeModifier, vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	float a = rand(size, sizeModifier, i);
	float b = rand(size, sizeModifier, i + vec2(1.0, 0.0));
	float c = rand(size, sizeModifier, i + vec2(0.0, 1.0));
	float d = rand(size, sizeModifier, i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

// Converted fbm function from GLSL
float fbm(float size, vec2 sizeModifier, int octaves, vec2 coord) {
	float value = 0.0;
	float scale = 0.5;

	//[unroll(50)]
	for (int i = 0; i < octaves; i++) {
		value = value + noise(size, sizeModifier, coord) * scale;
		coord = coord * 2.0;
		scale = scale * 0.5;
	}
	return value;
}

bool dither(float pixels, float dither_size, vec2 uv_pixel, vec2 uv_real) {
	return mod(uv_pixel.x + uv_real.y, 2.0 / pixels) * dither_size <= 1.0 / pixels;
}

vec2 rotate(vec2 coord, float angle){
	coord -= 0.5;
	coord *= mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	return coord + 0.5;
}

vec2 spherify(vec2 uv) {
	vec2 centered = uv *2.0-1.0;
	float z = sqrt(1.0 - dot(centered.xy, centered.xy));
	vec2 sphere = centered/(z + 1.0);
	
	return sphere * 0.5+0.5;
}

float circleNoise(float size, vec2 sizeModifier, vec2 uv) {
	float uv_y = floor(uv.y);
	uv.x += uv_y * .31;
	vec2 f = fract(uv);
	float h = rand(size, sizeModifier, vec2(floor(uv.x), floor(uv_y)));
	float m = (length(f - 0.25 - (h * 0.5)));
	float r = h * 0.25;
	return smoothstep(0.0, r, m * 0.75);
}

float cloud_alpha(float size, vec2 sizeModifier, float time_speed, int octaves, vec2 uv) {
	float c_noise = 0.0;

	// more iterations for more turbulence
	for (int i = 0; i < 9; i++) {
		c_noise += circleNoise(size, sizeModifier, (uv * size * 0.3) + (float(i + 1) + 10.0) + (vec2(iTime * time_speed, 0.0)));
	}
	float fbmVal = fbm(size, sizeModifier, octaves, uv * size + c_noise + vec2(iTime * time_speed, 0.0));

	return fbmVal;//step(a_cutoff, fbm);
}

// Layers
// Land
vec4 computeLand(vec2 inputUV) {
	vec2 uv = floor(inputUV * pixels) / pixels;
	float d_light = distance(uv, light_origin);
	bool dith = dither(pixels, dither_size, uv, inputUV);

	uv = rotate(uv, rotation);
	// map to sphere
	uv = spherify(uv);

	vec2 base_fbm_uv = uv * planet_size + vec2(iTime * planet_time_speed, 0.0);

	float fbm1 = fbm(planet_size, vec2(2.0, 1.0), planet_octaves, base_fbm_uv);
	float fbm2 = fbm(planet_size, vec2(2.0, 1.0), planet_octaves, base_fbm_uv - light_origin * fbm1);
	float fbm3 = fbm(planet_size, vec2(2.0, 1.0), planet_octaves, base_fbm_uv - light_origin * 1.5 * fbm1);
	float fbm4 = fbm(planet_size, vec2(2.0, 1.0), planet_octaves, base_fbm_uv - light_origin * 2.0 * fbm1);

	float river_fbm = fbm(planet_size, vec2(2.0, 1.0), planet_octaves, base_fbm_uv + fbm1 * 6.0);
	river_fbm = step(river_cutoff, river_fbm);

	float dither_border = (1.0 / pixels) * dither_size;

	if (d_light < light_border_1) {
		fbm4 *= 0.9;
	}
	if (d_light > light_border_1) {
		fbm2 *= 1.05;
		fbm3 *= 1.05;
		fbm4 *= 1.05;
	}
	if (d_light > light_border_2) {
		fbm2 *= 1.3;
		fbm3 *= 1.4;
		fbm4 *= 1.8;
		if (d_light < light_border_2 + dither_border && dith) {
			fbm4 *= 0.5;
		}
	}

	d_light = pow(d_light, 2.0) * 0.4;
	vec3 col = col4;
	if (fbm4 + d_light < fbm1 * 1.5) {
		col = col3;
	}
	if (fbm3 + d_light < fbm1 * 1.0) {
		col = col2;
	}
	if (fbm2 + d_light < fbm1) {
		col = col1;
	}
	if (river_fbm < fbm1 * 0.5) {
		col = river_col_dark;
		if (fbm4 + d_light < fbm1 * 1.5) {
			col = river_col;
		}
	}

	return vec4(col, step(distance(vec2(0.5, 0.5), uv), 0.5));
}

// The clouds
vec4 computeClouds(vec2 inputUV) {
	// pixelize uv
	vec2 uv = floor(inputUV * pixels) / pixels;
	// distance to light source
	float d_light = distance(uv, light_origin);

	float d_to_center = distance(uv, vec2(0.5, 0.5));

	uv = rotate(uv, rotation);
	// map to sphere
	uv = spherify(uv);

	// slightly make uv go down on the right, and up in the left
	uv.y += smoothstep(0.0, cloud_curve, abs(uv.x - 0.4));

	float c = cloud_alpha(size_clouds, vec2(1.0, 1.0), time_speed_clouds, cloud_octaves, uv * vec2(1.0, stretch));

	// assign some colors based on cloud depth & distance from light
	vec3 col = base_color;
	if (c < cloud_cover + 0.03) {
		col = outline_color;
	}
	if (d_light + c * 0.2 > light_border_clouds_1) {
		col = shadow_base_color;

	}
	if (d_light + c * 0.2 > light_border_clouds_2) {
		col = shadow_outline_color;
	}

	c *= step(d_to_center, 0.5);

	return vec4(col, step(cloud_cover, c));
}

// Fragment composition here
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 inputUV = fragCoord / iResolution.xy;
    inputUV.x *= iResolution.x / iResolution.y;

	vec4 planetClouds = computeClouds(inputUV);
	vec4 result;

	// Optimized rendering. Don't calculate what you don't need to.
	if (planetClouds.a != 0.0) {
		result = planetClouds;
	}
	else {
		result = computeLand(inputUV);
	}

	fragColor = result;
}

