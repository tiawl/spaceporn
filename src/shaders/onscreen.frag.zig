const std = @import("std");
const shader = @import("shader.zig");

const out_color = shader.output(shader.Vec4, "out_color", .{ .location = 0 });

const uniform = shader.uniform(shader.OnscreenUBO, "uniform", .{ .descriptor = .{ .set = 0, .binding = 0 } });

const texture_array: std.builtin.ExternOptions.Decoration = .{ .descriptor = .{ .set = 0, .binding = 1 } };

fn stars(uv: shader.Vec2) shader.Vec4 {
    const random = shader.sampler2dArray(texture_array, .{ uv[0], uv[1], 0 });
    const is_star = random[0] > 0.99;
    if (!is_star) return @splat(0.0);
    const star_base_brightness = random[1];
    const star_delta_brightness = random[2] - 0.5;
    const star_delta_brightness_rythm = @sin((random[3] * 20.0 + 10.0) * uniform.time);
    return @splat(star_base_brightness + star_delta_brightness * star_delta_brightness_rythm);
}

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    const MAXIMIZED_MAX_COORD = @max(uniform.max_resolution_x, uniform.max_resolution_y);
    const uv: shader.Vec2 = .{ std.spirv.frag_coord[0] / MAXIMIZED_MAX_COORD, std.spirv.frag_coord[1] / MAXIMIZED_MAX_COORD };
    out_color.* = stars(uv);
}
