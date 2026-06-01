const std = @import("std");
const shader = @import("shader.zig");

const out_color = shader.output(shader.Vec4, "out_color", .{ .location = 0 });

const uniform = shader.uniform(shader.OffscreenUBO, "uniform", .{ .descriptor = .{ .set = 0, .binding = 0 } });

const push = shader.pushConstant(shader.PushConstants, "push");

// http://www.jcgt.org/published/0009/03/02/
fn pcg4d(v: shader.Vec4) shader.Vec4 {
    var u = shader.Uvec4FromVec4(v);

    const a: shader.Uvec4 = @splat(1_664_525);
    const b: shader.Uvec4 = @splat(1_013_904_223);

    u = u *% a +% b;

    u[0] = u[0] +% u[1] *% u[3];
    u[1] = u[1] +% u[2] *% u[0];
    u[2] = u[2] +% u[0] *% u[1];
    u[3] = u[3] +% u[1] *% u[2];

    u ^= u >> @splat(16);

    u[0] = u[0] +% u[1] *% u[3];
    u[1] = u[1] +% u[2] *% u[0];
    u[2] = u[2] +% u[0] *% u[1];
    u[3] = u[3] +% u[1] *% u[2];

    return shader.Vec4FromUvec4(u);
}

fn random() shader.Vec4 {
    const MAX_COORD = @max(uniform.resolution[0], uniform.resolution[1]);
    return pcg4d(.{
        @floor((std.spirv.frag_coord[0] / uniform.resolution[0]) * MAX_COORD),
        @floor((std.spirv.frag_coord[1] / uniform.resolution[1]) * MAX_COORD),
        std.spirv.frag_coord[2],
        uniform.seed,
    });
}

fn pink() shader.Vec4 {
    return .{ 0.8, 0.2, 0.5, 1.0 };
}

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    out_color.* = switch (push.layer_index) {
        0 => random(),
        1 => pink(),
        else => unreachable,
    };
}
