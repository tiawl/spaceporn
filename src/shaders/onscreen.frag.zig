const std = @import("std");
const shader = @import("shader.zig");

const out_color = shader.output(shader.Vec4, "out_color", .{ .location = 0 });

const uniform = shader.uniform(shader.OnscreenUBO, "uniform", .{ .descriptor = .{ .set = 0, .binding = 0 } });

const texture_array: std.builtin.ExternOptions.Decoration = .{ .descriptor = .{ .set = 0, .binding = 1 } };

fn randomLayer(uv: shader.Vec2) shader.Vec4 {
    return shader.sampler2dArray(texture_array, .{ uv[0], uv[1], 0 });
}

fn random1(uv: shader.Vec2) f32 {
    return randomLayer(uv)[0];
}

fn random2(uv: shader.Vec2) f32 {
    return randomLayer(uv)[1];
}

fn random3(uv: shader.Vec2) f32 {
    return randomLayer(uv)[2];
}

fn random4(uv: shader.Vec2) f32 {
    return randomLayer(uv)[3];
}

fn stars(uv: shader.Vec2) shader.Vec4 {
    const is_star = random1(uv) > 0.99;
    if (!is_star) return @splat(0.0);
    const star_base_brightness = random2(uv);
    const star_delta_brightness = random3(uv) - 0.5;
    const star_delta_brightness_rythm = @sin((random4(uv) * 20.0 + 10.0) * uniform.time);
    return @splat(star_base_brightness + star_delta_brightness * star_delta_brightness_rythm);
}

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    const MAXIMIZED_MAX_COORD = @max(uniform.max_resolution[0], uniform.max_resolution[1]);
    const uv: shader.Vec2 = .{ std.spirv.frag_coord[0] / MAXIMIZED_MAX_COORD, std.spirv.frag_coord[1] / MAXIMIZED_MAX_COORD };
    out_color.* = stars(uv);
}
