const version         = @import ("builtin").zig_version;
const min_zig_version = "0.10.1";

const std = @import ("std");

const glfw   = @import ("libs/mach-glfw/build.zig");
const vk_gen = @import ("libs/vulkan-zig/generator/index.zig");

fn gen_imgui_binding (allocator: std.mem.Allocator) !void
{
  var child = std.ChildProcess.init (&[_][] const u8
                                     {
                                       "./generator.sh", "-c", "glfw vulkan",
                                     }, allocator);
  child.stdin_behavior = .Ignore;
  child.stdout_behavior = .Pipe;
  child.stderr_behavior = .Pipe;
  child.cwd = "libs/cimgui/generator";

  var stdout = std.ArrayList (u8).init (allocator);
  var stderr = std.ArrayList (u8).init (allocator);

  try child.spawn ();
  try child.collectOutput (&stdout, &stderr, 50 * 1024);

  var term = try child.wait ();

  std.debug.print ("STDOUT: {s}\nSTDERR: {s}\n", .{ try stdout.toOwnedSlice (), try stderr.toOwnedSlice (), });

  if (term != std.ChildProcess.Term.Exited)
  {
    std.log.err ("cimgui generator failed\n", .{});
    std.process.exit (1);
  }

  child = std.ChildProcess.init (&[_][] const u8 { "./gen_binding.sh", }, allocator);
  child.stdin_behavior = .Ignore;
  child.stdout_behavior = .Pipe;
  child.stderr_behavior = .Pipe;
  child.cwd = "libs";

  stdout = std.ArrayList (u8).init (allocator);
  stderr = std.ArrayList (u8).init (allocator);

  try child.spawn ();
  try child.collectOutput (&stdout, &stderr, 50 * 1024);

  term = try child.wait ();

  std.debug.print ("STDOUT: {s}\nSTDERR: {s}\n", .{ try stdout.toOwnedSlice (), try stderr.toOwnedSlice (), });

  if (term != std.ChildProcess.Term.Exited)
  {
    std.log.err ("script failed\n", .{});
    std.process.exit (1);
  }
}

fn git_reset (allocator: std.mem.Allocator) !void
{
  var child = std.ChildProcess.init (&[_][] const u8
                                     {
                                       "git", "reset", "--hard",
                                     }, allocator);
  child.stdin_behavior = .Ignore;
  child.stdout_behavior = .Pipe;
  child.stderr_behavior = .Pipe;
  child.cwd = "libs/cimgui";

  var stdout = std.ArrayList (u8).init (allocator);
  var stderr = std.ArrayList (u8).init (allocator);

  try child.spawn ();
  try child.collectOutput (&stdout, &stderr, 50 * 1024);

  const term = try child.wait ();

  std.debug.print ("STDOUT: {s}\nSTDERR: {s}\n", .{ try stdout.toOwnedSlice (), try stderr.toOwnedSlice (), });

  if (term != std.ChildProcess.Term.Exited)
  {
    std.log.err ("git reset --hard failed\n", .{});
    std.process.exit (1);
  }
}

fn git_clean (allocator: std.mem.Allocator) !void
{
  var child = std.ChildProcess.init (&[_][] const u8
                                     {
                                       "git", "clean", "-f", "-x", "-d", ":/",
                                     }, allocator);
  child.stdin_behavior = .Ignore;
  child.stdout_behavior = .Pipe;
  child.stderr_behavior = .Pipe;
  child.cwd = "libs/cimgui";

  var stdout = std.ArrayList (u8).init (allocator);
  var stderr = std.ArrayList (u8).init (allocator);

  try child.spawn ();
  try child.collectOutput (&stdout, &stderr, 50 * 1024);

  const term = try child.wait ();

  std.debug.print ("STDOUT: {s}\nSTDERR: {s}\n", .{ try stdout.toOwnedSlice (), try stderr.toOwnedSlice (), });

  if (term != std.ChildProcess.Term.Exited)
  {
    std.log.err ("git clean -f -x -d :/ failed\n", .{});
    std.process.exit (1);
  }
}

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

  if (version.order (std.SemanticVersion.parse (min_zig_version) catch unreachable) != .gt)
  {
    std.log.err ("{s} needs at least Zig {s} to be build", .{ EXE, min_zig_version, });
    std.process.exit (1);
  }

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
        std.log.err ("failed to build {s}", .{ LOG_DIR });
        std.process.exit (1);
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
  glfw.link (builder, exe, .{}) catch
  {
    std.log.err ("failed to link GLFW", .{});
    std.process.exit (1);
  };

  // cimgui
  if (DEV)
  {
    //try gen_imgui_binding (builder.allocator);
    try git_reset (builder.allocator);
    try git_clean (builder.allocator);

    exe.linkLibC ();
    exe.linkLibCpp ();
    exe.linkSystemLibrary ("glfw");
    exe.linkSystemLibrary ("vulkan");
    const cflags = &.{ "-fno-sanitize=undefined" };

    exe.addIncludePath ("libs");
    exe.addIncludePath ("libs/cimgui/imgui");
    exe.addIncludePath ("libs/cimgui/imgui/backends");

    exe.addCSourceFile ("libs/cimgui.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/imgui.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/imgui_demo.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/imgui_draw.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/imgui_tables.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/imgui_widgets.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/backends/imgui_impl_glfw.cpp", cflags);
    exe.addCSourceFile ("libs/cimgui/imgui/backends/imgui_impl_vulkan.cpp", cflags);
  }

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
  run_cmd.step.dependOn (builder.getInstallStep ());

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
