const std = @import("std");

const types = @import("types.zig");
pub const Vec2 = types.Vec2;
pub const Vec3 = types.Vec3;
pub const Vec4 = types.Vec4;
pub const Uvec4 = types.Uvec4;
pub const OnscreenUBO = types.OnscreenUBO;
pub const OffscreenUBO = types.OffscreenUBO;

const ImageArray = @SpirvType(.{
    .image = .{
        .usage = .{ .sampled = f32 },
        .dim = .@"2d",
        .depth = .unknown,
        .arrayed = true,
        .multisampled = false,
        .access = .unknown,
        .format = .unknown,
    },
});
const SampledImageArray = @SpirvType(.{ .sampled_image = ImageArray });

pub fn Uvec4FromVec4(v: Vec4) Uvec4 {
    return .{
        std.math.lossyCast(u32, @round(v[0])),
        std.math.lossyCast(u32, @round(v[1])),
        std.math.lossyCast(u32, @round(v[2])),
        std.math.lossyCast(u32, @round(v[3])),
    };
}

pub const max_u32f: f32 = @floatFromInt(std.math.maxInt(u32));

pub fn Vec4FromUvec4(u: Uvec4) Vec4 {
    return .{
        std.math.lossyCast(f32, u[0]),
        std.math.lossyCast(f32, u[1]),
        std.math.lossyCast(f32, u[2]),
        std.math.lossyCast(f32, u[3]),
    };
}

pub inline fn uniform(comptime T: type, comptime name: []const u8, comptime deco: std.builtin.ExternOptions.Decoration) *addrspace(.uniform) T {
    return externSymbol(T, .uniform, name, deco);
}

pub inline fn input(comptime T: type, comptime name: []const u8, comptime deco: std.builtin.ExternOptions.Decoration) *addrspace(.input) T {
    return externSymbol(T, .input, name, deco);
}

pub inline fn output(comptime T: type, comptime name: []const u8, comptime deco: std.builtin.ExternOptions.Decoration) *addrspace(.output) T {
    return externSymbol(T, .output, name, deco);
}

inline fn externSymbol(comptime T: type, comptime addr_space: std.builtin.AddressSpace, comptime name: []const u8, comptime optional_deco: ?std.builtin.ExternOptions.Decoration) *addrspace(addr_space) T {
    return @extern(*addrspace(addr_space) T, if (optional_deco) |deco| .{
        .name = name,
        .decoration = deco,
    } else .{
        .name = name,
    });
}

pub fn sampler2dArray(comptime deco: std.builtin.ExternOptions.Decoration, uv_layer: Vec3) Vec4 {
    return asm volatile (
        \\%sampler_ptr    = OpTypePointer UniformConstant %ty
        \\%tex            = OpVariable %sampler_ptr UniformConstant
        \\                  OpDecorate %tex DescriptorSet $set
        \\                  OpDecorate %tex Binding $bind
        \\%loaded_sampler = OpLoad %ty %tex
        \\%ret            = OpImageSampleImplicitLod %v4 %loaded_sampler %uv_layer
        : [ret] "" (-> Vec4),
        : [uv_layer] "" (uv_layer),
          [ty] "t" (SampledImageArray),
          [v4] "t" (Vec4),
          [set] "c" (deco.descriptor.set),
          [bind] "c" (deco.descriptor.binding),
    );
}
