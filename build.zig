const std = @import("std");

const glfw = @import("libs/mach-glfw/build.zig");
const vkgen = @import("libs/vulkan-zig/generator/index.zig");
const zigvulkan = @import("libs/vulkan-zig/build.zig");

pub fn build(builder: *std.build.Builder) !void
{
  const target = builder.standardTargetOptions(.{});
  const mode = builder.standardOptimizeOption(.{});

  const exe = builder.addExecutable(.{
    .name = "spacedream",
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = mode,
  });

  // Init a new install artifact step that will copy exe into destination directory
  const install_exe = builder.addInstallArtifact(exe);

  // Install step must be made after install artifact step is made
  builder.getInstallStep().dependOn(&install_exe.step);

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
  shaders.add("triangle_vert", "shaders/vertex/main.glsl", .{});
  shaders.add("triangle_frag", "shaders/fragment/main.glsl", .{});
  exe.addModule("resources", shaders.getModule());

  // Init a new run artifact step that will run exe (invisible for user)
  const run_cmd = builder.addRunArtifact(exe);

  // Run artifact step must be made after install step is made
  run_cmd.step.dependOn(builder.getInstallStep());

  // Allow to pass arguments from the zig build command line: zig build run -- -o foo.bin foo.asm
  if (builder.args) |args|
  {
    run_cmd.addArgs(args);
  }

  // Init a new step (visible for user)
  const run_step = builder.step("run", "Run the app");

  // New step must be made after run artifact step is made
  run_step.dependOn(&run_cmd.step);
}
