const std = @import("std");

const glfw = @import("libs/mach-glfw/build.zig");
const vkgen = @import("libs/vulkan-zig/generator/index.zig");
const zigvulkan = @import("libs/vulkan-zig/build.zig");

pub fn build(builder: *std.build.Builder) !void
{
  const target = builder.standardTargetOptions(.{});
  const mode = builder.standardOptimizeOption(.{});

  const exe = builder.addExecutable(.{
    .name = "spaceporn",
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = mode,
  });
  builder.installArtifact(exe);

  // vulkan-zig: new step that generates vk.zig (stored in zig-cache) from the provided vulkan registry.
  const gen = vkgen.VkGenerateStep.create(builder, "libs/vulkan-zig/examples/vk.xml");
  exe.addModule("vulkan", gen.getModule());

  // mach-glfw
  exe.addModule("glfw", glfw.module(builder));
  try glfw.link(builder, exe, .{});

  // shader resources, to be compiled using glslc
  const shaders = vkgen.ShaderCompileStep.create(
    builder,
    &[_][]const u8{ "glslc", "--target-env=vulkan1.2" },
    "-o",
  );
  shaders.add("triangle_vert", "shaders/vertex.glsl", .{});
  shaders.add("triangle_frag", "shaders/fragment.glsl", .{});
  exe.addModule("resources", shaders.getModule());

  const run_cmd = builder.addRunArtifact(exe);
  run_cmd.step.dependOn(builder.getInstallStep());
  if (builder.args) |args|
  {
    run_cmd.addArgs(args);
  }

  const run_step = builder.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);
}
