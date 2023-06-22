const std = @import ("std");

const glfw = @import ("libs/mach-glfw/build.zig");
const vkgen = @import ("libs/vulkan-zig/generator/index.zig");
const zigvulkan = @import ("libs/vulkan-zig/build.zig");

pub fn build (builder: *std.build.Builder) !void
{
  const build_options = builder.addOptions ();
  const EXE = "spaceporn";
  const DEV = builder.option (bool, "DEV", "Build " ++ EXE ++ " in verbose mode.") orelse false;
  const TURBO = builder.option (bool, "TURBO", "Build " ++ EXE ++ " without logging feature. LOG build option is ignored.") orelse false;

  if (TURBO and DEV)
  {
    std.log.err ("TURBO and DEV can not be used together.", .{});
    std.process.exit (1);
  }

  build_options.addOption ([] const u8, "EXE", EXE);

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

  // vulkan-zig: new step that generates vk.zig (stored in zig-cache) from the provided vulkan registry.
  const gen = vkgen.VkGenerateStep.create (builder, "libs/vulkan-zig/examples/vk.xml");
  exe.addModule ("vulkan", gen.getModule ());

  // mach-glfw
  exe.addModule ("glfw", glfw.module (builder));
  try glfw.link (builder, exe, .{});

  // shader resources, to be compiled using glslc
  const shaders = vkgen.ShaderCompileStep.create (builder, &[_][] const u8 { "glslc", "--target-env=vulkan1.2" }, "-o");
  shaders.add ("vert", "shaders/main.vert", .{});
  shaders.add ("frag", "shaders/main.frag", .{});
  exe.addModule ("resources", shaders.getModule ());

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
