const std = @import ("std");

const glfw = @import ("libs/mach-glfw/build.zig");
// const glfw = @import ("libs/mach-glfw/sdk.zig").Sdk (.{ .xcode_frameworks = @import("libs/mach-glfw/libs/xcode-frameworks/build.zig"), });
const vk_gen = @import ("libs/vulkan-zig/generator/index.zig");

pub fn build (builder: *std.Build) !void
{
  const modules = [_] struct { name: [] const u8, ptr: *std.build.Module, }
                  {
                    .{
                      .name = "datetime",
                      .ptr = builder.addModule ("datetime", .{ .source_file = .{ .path = "libs/zig-datetime/src/main.zig", },}),
                     },
                    .{
                      .name = "vulkan",
                      .ptr = vk_gen.VkGenerateStep.create (builder, "libs/vulkan-zig/examples/vk.xml").getModule (),
                     },
                    .{
                      .name = "glfw",
                      .ptr = glfw.module (builder),
                     },
                  };

  const build_options = builder.addOptions ();
  const EXE = "spaceporn";
  const VERSION = std.os.getenv ("VERSION").?;
  const DEV = builder.option (bool, "DEV", "Build " ++ EXE ++ " in verbose mode.") orelse false;
  const TURBO = builder.option (bool, "TURBO", "Build " ++ EXE ++ " without logging feature. LOG build option is ignored.") orelse false;

  if (TURBO and DEV)
  {
    std.log.err ("TURBO and DEV can not be used together.", .{});
    std.process.exit (1);
  }

  build_options.addOption ([] const u8, "EXE", EXE);
  build_options.addOption ([] const u8, "VERSION", VERSION);

  var mode: std.builtin.Mode = undefined;

  // Turbo profile
  if (TURBO)
  {

    // No logging
    mode = std.builtin.Mode.ReleaseFast;
    build_options.addOption ([] const u8, "LOG_DIR", "");
    build_options.addOption (u8, "LOG_LEVEL", 0);

  // Dev profile
  } else if (DEV) {
    const LOG_DIR = "./log";

    // Make log directory if not present
    std.fs.cwd ().makeDir (LOG_DIR) catch |err|
    {

      // Do not return error if log directory already exists
      if (err != std.fs.File.OpenError.PathAlreadyExists)
      {
        std.log.err ("filed to build {s}", .{ LOG_DIR });
        return err;
      }
    };

    // Full logging
    mode = std.builtin.Mode.Debug;
    build_options.addOption ([] const u8, "LOG_DIR", LOG_DIR);
    build_options.addOption (u8, "LOG_LEVEL", 2);

  // Default profile
  } else {

    // No logfile by default except if user specify it
    const LOG_DIR = builder.option ([] const u8, "LOG", "Log directory. If not specified, log are not registered in a file.") orelse "";

    build_options.addOption ([] const u8, "LOG_DIR", LOG_DIR);
    build_options.addOption (u8, "LOG_LEVEL", 1);

    mode = builder.standardOptimizeOption (.{});
  }

  const target = builder.standardTargetOptions (.{});

  const exe = builder.addExecutable (.{
    .name = EXE,
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = mode,
  });

  exe.addOptions ("build_options", build_options);

  // Init a new install artifact step that will copy exe into destination directory
  const install_exe = builder.addInstallArtifact (exe);

  // Install step must be made after install artifact step is made
  builder.getInstallStep ().dependOn (&install_exe.step);

  for (modules) |module|
  {
    exe.addModule (module.name, module.ptr);
  }

  // mach-glfw
  try glfw.link (builder, exe, .{});

  // shader resources, to be compiled using glslc
  const shaders = vk_gen.ShaderCompileStep.create (builder, &[_][] const u8 { "glslc", "--target-env=vulkan1.2" }, "-o");
  shaders.add ("vert", "shaders/main.vert", .{});
  shaders.add ("frag", "shaders/main.frag", .{});
  shaders.add ("offscreen_frag", "shaders/offscreen.frag", .{});
  exe.addModule ("resources", shaders.getModule ());

  const test_cmd = builder.addTest(.{ .root_source_file = .{ .path = "src/tests.zig" }, .optimize = .Debug, });
  test_cmd.addOptions ("build_options", build_options);

  for (modules) |module|
  {
    test_cmd.addModule (module.name, module.ptr);
  }

  const test_step = builder.step("test", "Run tests");
  test_step.dependOn(&test_cmd.step);

  // Init a new run artifact step that will run exe (invisible for user)
  const run_cmd = builder.addRunArtifact (exe);

  // Run artifact step must be made after install step is made
  run_cmd.step.dependOn (builder.getInstallStep());

  // Allow to pass arguments from the zig build command line: zig build run -- -o foo.bin foo.asm
  if (builder.args) |args|
  {
    run_cmd.addArgs (args);
  }

  // Init a new step (visible for user)
  const run_step = builder.step ("run", "Run the app");

  // New step must be made after run artifact step is made
  run_step.dependOn (&run_cmd.step);
}
