const std = @import("std");
const shader = @import("shader.zig");

const in_pos = shader.input(shader.Vec2, "in_pos", .{ .location = 0 });

export fn main() callconv(.spirv_vertex) void {
    std.spirv.position_out.* = .{ in_pos.*[0], in_pos.*[1], 0.0, 1.0 };
}
