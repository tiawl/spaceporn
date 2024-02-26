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
  command: [] const [] const u8,
};

pub fn build (builder: *std.Build) !void
{
  try requirements ();
  const profile = try parse_options (builder);
  try run_exe (builder, &profile);
  run_test (builder, &profile);
}

fn requirements () !void
{
  if (zig_version.order (try std.SemanticVersion.parse (zon.min_zig_version)) == .lt)
    std.debug.panic ("{s} needs at least Zig {s} to be build", .{ zon.name, zon.min_zig_version, });
}

fn turbo (profile: *Profile) void
{
  profile.optimize = std.builtin.Mode.ReleaseFast;
  profile.variables.addOption ([] const u8, "log_dir", "");
  profile.variables.addOption (u8, "log_level", 0);
  profile.command = &.{ "glslc", "-O", "--target-env=vulkan1.2", };
}

fn verbose (builder: *std.Build, profile: *Profile) !void
{
  const log_dir = "log";

  // Make log directory if not present
  builder.build_root.handle.makeDir (log_dir) catch |err|
  {
    // Do not return error if log directory already exists
    if (err != std.fs.File.OpenError.PathAlreadyExists) return err;
  };

  profile.optimize = std.builtin.Mode.Debug;
  profile.variables.addOption ([] const u8, "log_dir", builder.pathFromRoot (log_dir));
  profile.variables.addOption (u8, "log_level", 2);
  profile.command = &.{ "glslc", "--target-env=vulkan1.2", };
}

fn default (builder: *std.Build, profile: *Profile, options: *const Options) void
{
  profile.optimize = builder.standardOptimizeOption (.{});
  profile.variables.addOption ([] const u8, "log_dir", options.logdir);
  profile.variables.addOption (u8, "log_level", 1);
  profile.command = &.{ "glslc", "--target-env=vulkan1.2", };
}

fn parse_options (builder: *std.Build) !Profile
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
  else if (options.verbose) try verbose (builder, &profile)
  else default (builder, &profile, &options);

  return profile;
}

const Node = struct
{
  name: [] const u8,
  nodes: std.ArrayList (@This ()),
  hash: [64] u8 = undefined,
  depth: usize = 0,
};

// Create a hash from a shader's source contents.
fn digest (profile: ?*const Profile, source: [] u8) [64] u8
{
  var hasher = std.crypto.hash.blake2.Blake2b384.init (.{});

  // Make sure that there is no cache hit if the projet name has changed
  hasher.update (zon.name);
  // Make sure that there is no cache hit if the shader's source has changed.
  hasher.update (source);
  // Not only the shader source must be the same to ensure uniqueness the compile command, too.
  if (profile) |p| for (p.command) |token| hasher.update (token);

  // Create a base-64 hash digest from a hasher, which we can use as file name.
  var hash_digest: [48] u8 = undefined;
  hasher.final (&hash_digest);
  var hash: [64] u8 = undefined;
  _ = std.fs.base64_encoder.encode (&hash, &hash_digest);

  return hash;
}

fn add_shader (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile,
  glsl: *std.fs.Dir, entry: *const std.fs.Dir.Walker.WalkerEntry,
  dupe: [] const u8, ptr: *Node, depth: *usize) !void
{
  depth.* += 1;
  if (std.mem.eql (u8, entry.basename, dupe))
  {
    const path = try builder.allocator.dupe (u8, entry.path);
    const source = try glsl.readFileAlloc (builder.allocator, path, std.math.maxInt (usize));
    try ptr.nodes.append (.{
      .name = std.fs.path.extension (dupe) [1 ..],
      .nodes = std.ArrayList (Node).init (builder.allocator),
      .hash = digest (profile, source),
      .depth = depth.*,
    });

    const out = try std.fs.path.join (builder.allocator, &.{
      try builder.cache_root.join (builder.allocator, &.{ "shaders", }),
      &ptr.nodes.items [ptr.nodes.items.len - 1].hash,
    });
    const in = try std.fs.path.join (builder.allocator, &.{
      try builder.build_root.join (builder.allocator, &.{ "shaders", }), path,
    });

    // If we have a cache hit, we can save some compile time by not invoking the compile command.
    shader_not_found: {
      std.fs.accessAbsolute (out, .{}) catch |err| switch (err)
      {
        error.FileNotFound => break :shader_not_found,
        else => return err,
      };
      return;
    }

    var command = std.ArrayList ([] const u8).init (builder.allocator);
    try command.appendSlice (profile.command);
    try command.appendSlice (&.{ "-o", out, in, });
    std.debug.print ("{s}\n", .{ try std.mem.join (builder.allocator, " ", command.items), });
    try exe.step.evalChildProcess (command.items);
  }
}

fn write_index (builder: *std.Build, tree: *Node) ![] const u8
{
  var buffer = std.ArrayList (u8).init (builder.allocator);
  const writer = buffer.writer ();

  var stack = std.ArrayList (Node).init (builder.allocator);
  try stack.appendSlice (tree.nodes.items);
  var node: Node = undefined;

  while (stack.items.len > 0)
  {
    node = stack.pop ();

    try writer.print ("pub const @\"{s}\" ", .{ node.name, });

    if (node.nodes.items.len == 0 and
       (std.mem.eql (u8, node.name, "frag") or std.mem.eql (u8, node.name, "vert")))
    {
      try writer.print ("align(@alignOf(u32)) = @embedFile(\"{s}\").*;\n", .{ node.hash, });
    } else try writer.print ("= struct {c}\n", .{ '{', });

    for (node.nodes.items) |*child| try stack.append (child.*);

    if (stack.getLastOrNull ()) |last|
    {
      if (node.depth > last.depth)
        for (0 .. node.depth - last.depth) |_| try writer.print ("{c};\n", .{ '}', });
    } else try writer.print ("{c};\n", .{ '}', });
  }

  try buffer.append (0);
  const source = buffer.items [0 .. buffer.items.len - 1 :0];

  const validated = try std.zig.Ast.parse (builder.allocator, source, std.zig.Ast.Mode.zig);
  const formatted = try validated.render (builder.allocator);

  const hash = &digest (null, formatted);
  const path = try std.fs.path.join (builder.allocator, &.{
    try builder.cache_root.join (builder.allocator, &.{ "shaders", }), hash,
  });

  std.fs.accessAbsolute (path, .{}) catch |err| switch (err)
  {
    error.FileNotFound => try builder.cache_root.handle.writeFile (path, formatted),
    else => return err,
  };

  return path;
}

fn walk_through_shaders (builder: *std.Build, exe: *std.Build.Step.Compile,
  profile: *const Profile, tree: *Node) !void
{
  var glsl = try builder.build_root.handle.openDir ("shaders", .{ .iterate = true });
  defer glsl.close ();

  var walker = try glsl.walk (builder.allocator);
  defer walker.deinit ();
  var depth: usize = undefined;

  var ptr: *Node = undefined;

  while (try walker.next ()) |*entry|
  {
    if (entry.kind == .file)
    {
      var it = try std.fs.path.componentIterator (entry.path);
      ptr = tree;
      depth = 0;
      next: while (it.next ()) |*component|
      {
        const dupe = try builder.allocator.dupe (u8, component.name);
        const stem = std.fs.path.stem (dupe);
        for (ptr.nodes.items) |*node|
        {
          if (std.mem.eql (u8, node.name, stem))
          {
            ptr = node;
            try add_shader (builder, exe, profile, &glsl, entry, dupe, ptr, &depth);
            continue :next;
          }
        }
        try ptr.nodes.append (.{ .name = stem, .nodes = std.ArrayList (Node).init (builder.allocator), .depth = depth, });
        ptr = &ptr.nodes.items [ptr.nodes.items.len - 1];
        try add_shader (builder, exe, profile, &glsl, entry, dupe, ptr, &depth);
      }
    }
  }
}

fn compile_shaders (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) ![] const u8
{
  var tree: Node = .{ .name = "shaders", .nodes = std.ArrayList (Node).init (builder.allocator), };

  builder.cache_root.handle.makeDir ("shaders") catch |err|
  {
    // Do not return error if directory already exists
    if (err != std.fs.File.OpenError.PathAlreadyExists) return err;
  };

  try walk_through_shaders (builder, exe, profile, &tree);
  return try write_index (builder, &tree);
}

fn link (builder: *std.Build, profile: *const Profile) *std.Build.Module
{
  const dep = builder.dependency ("cimgui", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  const cimgui = dep.artifact ("cimgui");

  const binding = builder.createModule (.{
   .root_source_file = .{ .path = "src/binding/import.zig", },
   .target = profile.target,
   .optimize = profile.optimize,
  });
  binding.linkSystemLibrary ("glfw", .{});
  binding.linkSystemLibrary ("vulkan", .{});
  binding.linkLibrary (cimgui);
  binding.addIncludePath (dep.path ("imgui"));

  return binding;
}

fn import (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) !void
{
  const dep = builder.dependency ("zig-datetime", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });

  const modules: [] const struct { ptr: *std.Build.Module, name: [] const u8 } = &.{
    .{
       .name = "build",
       .ptr = profile.variables.createModule (),
     }, .{
       .name = "datetime",
       .ptr = dep.module ("zig-datetime"),
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
         .root_source_file = .{ .path = try compile_shaders (builder, exe, profile), },
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

fn run_exe (builder: *std.Build, profile: *const Profile) !void
{
  const exe = builder.addExecutable (.{
    .name = zon.name,
    .root_source_file = .{ .path = "src/main.zig" },
    .target = profile.target,
    .optimize = profile.optimize,
  });

  try import (builder, exe, profile);

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
