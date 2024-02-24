const std = @import ("std");
const zig_version = @import ("builtin").zig_version;

const zon = .{ .name = "spaceporn", .version = "0.0.0", .min_zig_version = "0.11.0" };

const Options = struct
{
  verbose: bool,
  turbo: bool,
  logdir: [] const u8,
};

const Profile = struct
{
  target: std.Build.ResolvedTarget,
  optimize: std.builtin.OptimizeMode,
  variables: *std.Build.Step.Options,
  options: Options,
};

pub fn build (builder: *std.Build) void
{
  requirements ();
  const profile = parse_options (builder);
  run_exe (builder, &profile);
  run_test (builder, &profile);
}

fn requirements () void
{
  if (zig_version.order (std.SemanticVersion.parse (zon.min_zig_version) catch std.debug.panic ("Failed to parse Zig minimal version requirement", .{})) == .lt)
    std.debug.panic ("{s} needs at least Zig {s} to be build", .{ zon.name, zon.min_zig_version, });
}

fn turbo (profile: *Profile) void
{
  profile.optimize = std.builtin.Mode.ReleaseFast;
  profile.variables.addOption ([] const u8, "log_dir", "");
  profile.variables.addOption (u8, "log_level", 0);
}

fn verbose (builder: *std.Build, profile: *Profile) void
{
  const log_dir = "log";

  // Make log directory if not present
  builder.build_root.handle.makeDir (log_dir) catch |err|
  {
    // Do not return error if log directory already exists
    if (err != std.fs.File.OpenError.PathAlreadyExists)
      std.debug.panic ("failed to build {s}", .{ builder.pathFromRoot (log_dir) });
  };

  profile.optimize = std.builtin.Mode.Debug;
  profile.variables.addOption ([] const u8, "log_dir", builder.pathFromRoot (log_dir));
  profile.variables.addOption (u8, "log_level", 2);
}

fn default (builder: *std.Build, profile: *Profile, options: *const Options) void
{
  profile.optimize = builder.standardOptimizeOption (.{});
  profile.variables.addOption ([] const u8, "log_dir", options.logdir);
  profile.variables.addOption (u8, "log_level", 1);
}

fn parse_options (builder: *std.Build) Profile
{
  const options = Options {
    .verbose = builder.option (bool, std.meta.fieldInfo (Options, .verbose).name, "Build " ++ zon.name ++ " with full logging features.") orelse false,
    .turbo = builder.option (bool, std.meta.fieldInfo (Options, .turbo).name, "Build " ++ zon.name ++ " with optimized features.") orelse false,
    .logdir = builder.option ([] const u8, std.meta.fieldInfo (Options, .logdir).name, "Log directory. If not specified, logs are not registered in a file.") orelse "",
  };

  if (options.turbo and options.verbose)
    std.debug.panic ("-D{s} and -D{s} can not be used together", .{ std.meta.fieldInfo (Options, .turbo).name, std.meta.fieldInfo (Options, .verbose).name, })
  else if (options.turbo and options.logdir.len > 0)
    std.debug.panic ("-D{s} and -D{s} can not be used together", .{ std.meta.fieldInfo (Options, .turbo).name, std.meta.fieldInfo (Options, .logdir).name, });

  var profile: Profile = undefined;
  profile.target = builder.standardTargetOptions (.{});
  profile.variables = builder.addOptions ();
  profile.variables.addOption ([] const u8, std.meta.fieldInfo (@TypeOf (zon), .name).name, zon.name);
  profile.variables.addOption ([] const u8, std.meta.fieldInfo (@TypeOf (zon), .version).name, zon.version);
  profile.options = options;

  if (options.turbo) turbo (&profile)
  else if (options.verbose) verbose (builder, &profile)
  else default (builder, &profile, &options);

  return profile;
}

fn compile_shaders (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) [] const u8
{
  const glsl_dir = builder.build_root.handle.openDir ("shaders", .{ .iterate = true })
    catch std.debug.panic ("Failed to open glsl shaders directory", .{});

  builder.cache_root.handle.makeDir ("shaders") catch |err|
  {
    // Do not return error if spv shaders directory already exists
    if (err != std.fs.File.OpenError.PathAlreadyExists)
      std.debug.panic ("failed to build spv shaders cache directory", .{});
  };

  var index = std.ArrayList (u8).init (builder.allocator);
  const writer = index.writer ();

  var it = glsl_dir.iterate ();
  while (it.next () catch std.debug.panic ("Failed to iterate shader directory", .{})) |node|
  {
    if (node.kind == .file)
    {
      const zig_name = std.mem.replaceOwned (u8, builder.allocator, node.name, ".", "_")
        catch std.debug.panic ("Failed to replace '.' by '_' in {s}", .{ node.name });
      const glsl = glsl_dir.realpathAlloc (builder.allocator, node.name)
        catch std.debug.panic ("Failed to realpath glsl shaders directory", .{});
      const spv_name = std.fmt.allocPrint (builder.allocator, "{s}.spv", .{ node.name })
        catch std.debug.panic ("Failed to concat spv extension to ${s}", .{ node.name });
      const spv = builder.cache_root.join (builder.allocator, &.{ "shaders", spv_name })
        catch std.debug.panic ("Failed to join spv shaders cache directory", .{});

      writer.print ("pub const {s} align (@alignOf (u32)) = @embedFile (\"{s}.spv\").*;\n", .{
        zig_name, node.name }) catch std.debug.panic ("Writer failed", .{});

      exe.step.evalChildProcess (
        if (profile.options.turbo) &.{ "glslc", "-O", "--target-env=vulkan1.2", "-o", spv, glsl, }
        else &.{ "glslc", "--target-env=vulkan1.2", "-o", spv, glsl, }
      ) catch {};
    }
  }

  const index_path = builder.cache_root.join (builder.allocator, &.{ "shaders", "index.zig" })
    catch std.debug.panic ("Failed to join index shaders path", .{});
  builder.cache_root.handle.writeFile (index_path, index.items)
    catch std.debug.print ("Failed to write {s}", .{ index_path });
  return index_path;
}

fn link (builder: *std.Build, profile: *const Profile) *std.Build.Module
{
  const cimgui_dep = builder.dependency ("cimgui", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  const cimgui = cimgui_dep.artifact ("cimgui");

  const c = builder.createModule (.{
   .root_source_file = .{ .path = "src/binding/import.zig", },
   .target = profile.target,
   .optimize = profile.optimize,
  });
  c.linkSystemLibrary ("glfw", .{});
  c.linkSystemLibrary ("vulkan", .{});
  c.linkLibrary (cimgui);
  c.addIncludePath (cimgui_dep.path ("imgui"));

  return c;
}

fn import (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) void
{
  const datetime_dep = builder.dependency ("zig-datetime", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });

  const modules: [] const struct { ptr: *std.Build.Module, name: [] const u8 } = &.{
    .{
       .name = "build",
       .ptr = profile.variables.createModule (),
     }, .{
       .name = "datetime",
       .ptr = datetime_dep.module ("zig-datetime"),
     }, .{
       .name = "glfw",
       .ptr = builder.createModule (.{
         .root_source_file = .{ .path = "src/binding/glfw.zig", },
         .target = profile.target,
         .optimize = profile.optimize,
       }),
     }, .{
       .name = "vulkan",
       .ptr = builder.createModule (.{
         .root_source_file = .{ .path = "src/binding/vulkan.zig", },
         .target = profile.target,
         .optimize = profile.optimize,
       }),
     }, .{
       .name = "shader",
       .ptr = builder.createModule (.{
         .root_source_file = .{ .path = compile_shaders (builder, exe, profile), },
         .target = profile.target,
         .optimize = profile.optimize,
       }),
     }, .{
       .name = "imgui",
       .ptr = builder.createModule (.{
         .root_source_file = .{ .path = "src/binding/imgui.zig", },
         .target = profile.target,
         .optimize = profile.optimize,
       }),
     },
  };

  const c = link (builder, profile);

  for (modules) |*module|
  {
    module.ptr.addImport ("c", c);
    exe.root_module.addImport (module.name, module.ptr);
  }
}

fn run_exe (builder: *std.Build, profile: *const Profile) void
{
  const exe = builder.addExecutable (.{
    .name = zon.name,
    .root_source_file = .{ .path = "src/main.zig" },
    .target = profile.target,
    .optimize = profile.optimize,
  });

  import (builder, exe, profile);

  builder.installArtifact (exe);

  const run_cmd = builder.addRunArtifact (exe);
  run_cmd.step.dependOn (builder.getInstallStep ());

  const run_step = builder.step ("run", "Run " ++ zon.name);
  run_step.dependOn (&run_cmd.step);
}

fn run_test (builder: *std.Build, profile: *const Profile) void
{
  const unit_tests = builder.addTest (.{
    .target = profile.target,
    .optimize = profile.optimize,
    .test_runner = "test/runner.zig",
    .root_source_file = .{ .path = "test/main.zig" },
  });
  unit_tests.step.dependOn (builder.getInstallStep ());

  const run_unit_tests = builder.addRunArtifact (unit_tests);

  const test_step = builder.step ("test", "Run tests");
  test_step.dependOn (&run_unit_tests.step);
}
