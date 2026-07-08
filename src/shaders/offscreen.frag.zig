const std = @import("std");
const shader = @import("shader.zig");

const out_color = shader.output(shader.Vec4, "out_color", .{ .location = 0 });

const uniform = shader.uniform(shader.OffscreenUBO, "uniform", .{ .descriptor = .{ .set = 0, .binding = 0 } });

// http://www.jcgt.org/published/0009/03/02/
fn pcg4d(v: shader.Uvec4) shader.Uvec4 {
    const a: shader.Uvec4 = @splat(1_664_525);
    const b: shader.Uvec4 = @splat(1_013_904_223);

    var u = v *% a +% b;

    u[0] = u[0] +% u[1] *% u[3];
    u[1] = u[1] +% u[2] *% u[0];
    u[2] = u[2] +% u[0] *% u[1];
    u[3] = u[3] +% u[1] *% u[2];

    u ^= u >> @splat(16);

    u[0] = u[0] +% u[1] *% u[3];
    u[1] = u[1] +% u[2] *% u[0];
    u[2] = u[2] +% u[0] *% u[1];
    u[3] = u[3] +% u[1] *% u[2];

    return u;
}

fn random(frag_coord: shader.Vec4) shader.Vec4 {
    const MAX_COORD = @max(uniform.resolution_x, uniform.resolution_y);
    const max: shader.Vec4 = @splat(shader.max_u32f);
    return shader.Vec4FromUvec4(pcg4d(.{
        @floor((frag_coord[0] / uniform.resolution_x) * MAX_COORD),
        @floor((frag_coord[1] / uniform.resolution_y) * MAX_COORD),
        std.math.lossyCast(u32, frag_coord[2]),
        uniform.seed,
    })) / max;
}

fn pink() shader.Vec4 {
    return .{ 0.8, 0.2, 0.5, 1.0 };
}

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    out_color.* = switch (uniform.layer) {
        0 => random(std.spirv.frag_coord),
        1 => pink(),
        else => unreachable,
    };
}
