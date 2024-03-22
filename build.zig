const std = @import ("std");
const zig_version = @import ("builtin").zig_version;

const zon = .{ .name = "spaceporn", .version = "0.1.0", .min_zig_version = "0.11.0", };

const Options = struct
{
  verbose: bool = false,
  turbo:   bool = false,
  logdir:  [] const u8 = "",
  vkminor: [] const u8 = "2",

  const default: @This () = .{};
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
  try run_test (builder, &profile);
}

fn requirements () !void
{
  if (zig_version.order (try std.SemanticVersion.parse (zon.min_zig_version)) == .lt)
    std.debug.panic ("{s} needs at least Zig {s} to be build", .{ zon.name, zon.min_zig_version, });
}

fn turbo (builder: *std.Build, profile: *Profile) !void
{
  profile.optimize = .ReleaseFast;
  profile.variables.addOption ([] const u8, "log_dir", "");
  profile.variables.addOption (u8, "log_level", 0);
  profile.variables.addOption ([] const [] const [] const u8, "vk_optional_extensions", &.{});
  profile.command = &.{ "glslc", "-O", try std.fmt.allocPrint (builder.allocator, "--target-env=vulkan1.{s}", .{ profile.options.vkminor, }), };
}

fn verbose (builder: *std.Build, profile: *Profile) !void
{
  const log_dir = "log";

  // Make log directory if not present only in verbose mode
  builder.build_root.handle.makeDir (log_dir) catch |err|
  {
    // Do not return error if log directory already exists
    if (err != std.fs.File.OpenError.PathAlreadyExists) return err;
  };

  profile.optimize = .Debug;
  profile.variables.addOption ([] const u8, "log_dir", try builder.build_root.join (builder.allocator, &.{ log_dir, }));
  profile.variables.addOption (u8, "log_level", 2);
  profile.variables.addOption ([] const [] const [] const u8, "vk_optional_extensions", &.{
    &.{ "EXT", "DEVICE_ADDRESS_BINDING_REPORT", },
    &.{ "EXT", "VALIDATION_FEATURES", },
    &.{ "KHR", "SHADER_NON_SEMANTIC_INFO", },
  });
  profile.command = &.{ "glslc", try std.fmt.allocPrint (builder.allocator, "--target-env=vulkan1.{s}", .{ profile.options.vkminor, }), };
}

fn default (builder: *std.Build, profile: *Profile) !void
{
  profile.optimize = builder.standardOptimizeOption (.{});
  profile.variables.addOption ([] const u8, "log_dir", profile.options.logdir);
  profile.variables.addOption (u8, "log_level", 1);
  profile.variables.addOption ([] const [] const [] const u8, "vk_optional_extensions", &.{
    &.{ "EXT", "DEVICE_ADDRESS_BINDING_REPORT", },
  });
  profile.command = &.{ "glslc", try std.fmt.allocPrint (builder.allocator, "--target-env=vulkan1.{s}", .{ profile.options.vkminor, }), };
}

fn parse_options (builder: *std.Build) !Profile
{
  const options = Options {
    .verbose = builder.option (bool, std.meta.fieldInfo (Options, .verbose).name, "Build " ++ zon.name ++ " with full logging features. Default: " ++ (if (@field (Options.default, std.meta.fieldInfo (Options, .verbose).name)) "enabled" else "disabled") ++ ".")
      orelse @field (Options.default, std.meta.fieldInfo (Options, .verbose).name),
    .turbo = builder.option (bool, std.meta.fieldInfo (Options, .turbo).name, "Build " ++ zon.name ++ " with optimized features. Default: " ++ (if (@field (Options.default, std.meta.fieldInfo (Options, .turbo).name)) "enabled" else "disabled") ++ ".")
      orelse @field (Options.default, std.meta.fieldInfo (Options, .turbo).name),
    .logdir = builder.option ([] const u8, std.meta.fieldInfo (Options, .logdir).name, "Absolute path to log directory. If not specified, logs are not registered in a file.")
      orelse @field (Options.default, std.meta.fieldInfo (Options, .logdir).name),
    .vkminor = builder.option ([] const u8, std.meta.fieldInfo (Options, .vkminor).name, "Vulkan minor version to use: Possible values: 0, 1, 2 or 3. Default value: " ++ @field (Options.default, std.meta.fieldInfo (Options, .vkminor).name) ++ ".")
      orelse @field (Options.default, std.meta.fieldInfo (Options, .vkminor).name),
  };

  _ = std.fmt.parseInt (u2, options.vkminor, 10) catch std.debug.panic ("-D{s} value should be 0, 1, 2 or 3", .{ std.meta.fieldInfo (Options, .vkminor).name, });

  if (options.turbo and options.verbose)
    std.debug.panic ("-D{s} and -D{s} can not be used together", .{ std.meta.fieldInfo (Options, .turbo).name, std.meta.fieldInfo (Options, .verbose).name, })
  else if (options.turbo and options.logdir.len > 0)
    std.debug.panic ("-D{s} and -D{s} can not be used together", .{ std.meta.fieldInfo (Options, .turbo).name, std.meta.fieldInfo (Options, .logdir).name, });

  var profile: Profile = undefined;
  profile.target = builder.standardTargetOptions (.{});
  profile.options = options;
  profile.variables = builder.addOptions ();
  profile.variables.addOption ([] const u8, std.meta.fieldInfo (@TypeOf (zon), .name).name, zon.name);
  profile.variables.addOption ([] const u8, std.meta.fieldInfo (@TypeOf (zon), .version).name, zon.version);
  profile.variables.addOption ([] const u8, "vk_minor", profile.options.vkminor);

  if (profile.options.turbo) try turbo (builder, &profile)
  else if (profile.options.verbose) try verbose (builder, &profile)
  else try default (builder, &profile);

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

  std.debug.print ("{s}\n", .{ path, });
  return path;
}

fn walk_through_shaders (builder: *std.Build, exe: *std.Build.Step.Compile,
  profile: *const Profile, tree: *Node) !void
{
  var glsl = try builder.build_root.handle.openDir ("shaders", .{ .iterate = true, });
  defer glsl.close ();

  var walker = try glsl.walk (builder.allocator);
  defer walker.deinit ();
  var depth: usize = undefined;

  var pointer: *Node = undefined;

  while (try walker.next ()) |*entry|
  {
    if (entry.kind == .file)
    {
      var iterator = try std.fs.path.componentIterator (entry.path);
      pointer = tree;
      depth = 0;
      next: while (iterator.next ()) |*component|
      {
        const dupe = try builder.allocator.dupe (u8, component.name);
        const stem = std.fs.path.stem (dupe);
        for (pointer.nodes.items) |*node|
        {
          if (std.mem.eql (u8, node.name, stem))
          {
            pointer = node;
            try add_shader (builder, exe, profile, &glsl, entry, dupe, pointer, &depth);
            continue :next;
          }
        }
        try pointer.nodes.append (.{ .name = stem, .nodes = std.ArrayList (Node).init (builder.allocator), .depth = depth, });
        pointer = &pointer.nodes.items [pointer.nodes.items.len - 1];
        try add_shader (builder, exe, profile, &glsl, entry, dupe, pointer, &depth);
      }
    }
  }
}

fn compile_shaders (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) ![] const u8
{
  var tree: Node = .{ .name = "shaders", .nodes = std.ArrayList (Node).init (builder.allocator), };

  builder.cache_root.handle.makeDir ("shaders") catch |err|
  {
    if (err != std.fs.File.OpenError.PathAlreadyExists) return err;
  };

  try walk_through_shaders (builder, exe, profile, &tree);
  return try write_index (builder, &tree);
}

fn generate_literals_prototypes (builder: *std.Build) ![] const u8
{
  builder.cache_root.handle.makeDir ("prototypes") catch |err|
  {
    if (err != std.fs.File.OpenError.PathAlreadyExists) return err;
  };

  var binding: struct { path: [] const u8, buffer: std.ArrayList (u8), source: [] u8, } = undefined;

  var vk: struct { path: [] const u8, dir: std.fs.Dir, } = undefined;
  vk.path = try std.fs.path.join (builder.allocator, &.{ "src", "binding", "vk", });

  vk.dir = try builder.build_root.handle.openDir (vk.path, .{ .iterate = true, });
  defer vk.dir.close ();

  var walker = try vk.dir.walk (builder.allocator);
  defer walker.deinit ();

  var prototypes: struct { buffer: std.ArrayList (u8), source: [:0] const u8,
    path: [] const u8, structless: std.ArrayList ([] const u8),
    instance: std.ArrayList ([] const u8), device: std.ArrayList ([] const u8), } = undefined;
  prototypes.structless = std.ArrayList ([] const u8).init (builder.allocator);
  prototypes.instance = std.ArrayList ([] const u8).init (builder.allocator);
  prototypes.device = std.ArrayList ([] const u8).init (builder.allocator);
  prototypes.buffer = std.ArrayList (u8).init (builder.allocator);

  while (try walker.next ()) |*entry|
  {
    if (entry.kind != .file) continue;

    binding.path = try std.fs.path.join (builder.allocator, &.{ vk.path, entry.path, });
    binding.buffer = std.ArrayList (u8).init (builder.allocator);
    binding.source = try builder.build_root.handle.readFileAlloc (builder.allocator, binding.path, std.math.maxInt (usize));

    try binding.buffer.appendSlice (binding.source);
    try binding.buffer.append (0);

    var iterator = std.zig.Tokenizer.init (binding.buffer.items [0 .. binding.buffer.items.len - 1 :0]);
    var token = iterator.next ();
    const size: usize = 6;
    var precedent: [size] ?std.zig.Token = .{ null, } ** size;

    while (token.tag != .eof)
    {
      if (precedent [precedent.len - 1] != null)
      {
        if (std.mem.startsWith (u8, binding.buffer.items [token.loc.start .. token.loc.end], "vk") and
            precedent [0].?.tag == .period and precedent [2].?.tag == .period and precedent [4].?.tag == .period and
            std.mem.eql (u8, binding.buffer.items [precedent [3].?.loc.start .. precedent [3].?.loc.end], "prototypes") and
            std.mem.eql (u8, binding.buffer.items [precedent [5].?.loc.start .. precedent [5].?.loc.end], "raw"))
        {
          inline for (@typeInfo (@TypeOf (prototypes)).Struct.fields) |field|
          {
            if (field.type == std.ArrayList ([] const u8))
            {
              if (std.mem.eql (u8, binding.buffer.items [precedent [1].?.loc.start .. precedent [1].?.loc.end], field.name))
              {
                try @field (prototypes, field.name).append (binding.buffer.items [token.loc.start .. token.loc.end]);
                break;
              }
            }
          }
        }
      }

      for (1 .. precedent.len) |i| precedent [precedent.len - i] = precedent [precedent.len - i - 1];
      precedent [0] = token;
      token = iterator.next ();
    }
  }

  const writer = prototypes.buffer.writer ();

  inline for (@typeInfo (@TypeOf (prototypes)).Struct.fields) |field|
  {
    if (field.type == std.ArrayList ([] const u8))
    {
      try writer.print ("pub const {s} = enum {c}", .{ field.name, '{', });
      for (@field (prototypes, field.name).items) |prototype|
        try writer.print ("  {s},\n", .{ prototype, });
      try writer.print ("{c};", .{ '}', });
    }
  }

  try prototypes.buffer.append (0);
  prototypes.source = prototypes.buffer.items [0 .. prototypes.buffer.items.len - 1 :0];

  const validated = try std.zig.Ast.parse (builder.allocator, prototypes.source, std.zig.Ast.Mode.zig);
  const formatted = try validated.render (builder.allocator);

  const hash = &digest (null, formatted);
  prototypes.path = try std.fs.path.join (builder.allocator, &.{
    try builder.cache_root.join (builder.allocator, &.{ "prototypes", }), hash,
  });

  std.fs.accessAbsolute (prototypes.path, .{}) catch |err| switch (err)
  {
    error.FileNotFound => try builder.cache_root.handle.writeFile (prototypes.path, formatted),
    else => return err,
  };

  std.debug.print ("{s}\n", .{ prototypes.path, });
  return prototypes.path;
}

fn link (builder: *std.Build, profile: *const Profile) !*std.Build.Module
{
  const glfw_dep = builder.dependency ("glfw", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  const glfw = glfw_dep.artifact ("glfw");

  const imgui_dep = builder.dependency ("cimgui", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  const cimgui = imgui_dep.artifact ("cimgui");

  const binding = builder.createModule (.{
    .root_source_file = .{ .path = try builder.build_root.join (builder.allocator, &.{ "src", "binding", "raw.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  binding.linkLibrary (glfw);
  binding.linkLibrary (cimgui);
  binding.addIncludePath (imgui_dep.path ("imgui"));

  return binding;
}

fn import_glfw (builder: *std.Build, profile: *const Profile, c: *std.Build.Module) !*std.Build.Module
{
  const path = try builder.build_root.join (builder.allocator, &.{ "src", "binding", "glfw", });

  var modules = std.ArrayList (*std.Build.Module).init (builder.allocator);

  var dir = try builder.build_root.handle.openDir (path, .{ .iterate = true, });
  defer dir.close ();

  var it = dir.iterate ();
  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => {
                 if (!std.mem.eql (u8, entry.name, "glfw.zig"))
                 {
                   try modules.append (builder.createModule (.{
                     .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, entry.name, }), },
                     .target = profile.target,
                     .optimize = profile.optimize,
                   }));
                   modules.items [modules.items.len - 1].addImport ("c", c);
                 }
               },
      else  => {},
    }
  }

  const glfw = builder.createModule (.{
    .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, "glfw.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  glfw.addImport ("c", c);

  for (modules.items) |module|
  {
    const name = std.fs.path.stem (std.fs.path.basename (module.root_source_file.?.getPath (builder)));
    glfw.addImport (name, module);
    module.addImport ("glfw", glfw);
    for (modules.items) |other|
    {
      const other_name = std.fs.path.stem (std.fs.path.basename (other.root_source_file.?.getPath (builder)));
      if (std.mem.eql (u8, name, other_name)) continue;
      module.addImport (other_name, other);
    }
  }

  return glfw;
}

fn import_vk (builder: *std.Build, profile: *const Profile, c: *std.Build.Module) !*std.Build.Module
{
  const literals = builder.createModule (.{
    .root_source_file = .{ .path = try generate_literals_prototypes (builder), },
    .target = profile.target,
    .optimize = profile.optimize,
  });

  const path = try builder.build_root.join (builder.allocator, &.{ "src", "binding", "vk", });

  const raw = builder.createModule (.{
    .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, "raw.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  raw.addImport ("c", c);
  raw.addImport ("literals", literals);

  var modules = std.ArrayList (*std.Build.Module).init (builder.allocator);

  var dir = try builder.build_root.handle.openDir (path, .{ .iterate = true, });
  defer dir.close ();

  var it = dir.iterate ();
  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => {
                 if (!std.mem.eql (u8, entry.name, "vk.zig") and !std.mem.eql (u8, entry.name, "raw.zig") and
                     !std.mem.eql (u8, entry.name, "ext.zig") and !std.mem.eql (u8, entry.name, "khr.zig"))
                 {
                   try modules.append (builder.createModule (.{
                     .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, entry.name, }), },
                     .target = profile.target,
                     .optimize = profile.optimize,
                   }));
                   modules.items [modules.items.len - 1].addImport ("c", c);
                   modules.items [modules.items.len - 1].addImport ("raw", raw);
                 }
               },
      else  => {},
    }
  }

  const ext = builder.createModule (.{
    .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, "ext.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  ext.addImport ("c", c);
  ext.addImport ("raw", raw);

  var ext_subs = std.ArrayList (*std.Build.Module).init (builder.allocator);

  const ext_path = try std.fs.path.join (builder.allocator, &.{ path, "ext", });
  var ext_dir = try builder.build_root.handle.openDir (ext_path, .{ .iterate = true, });
  defer ext_dir.close ();

  var walker = try ext_dir.walk (builder.allocator);
  defer walker.deinit();

  while (try walker.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => {
                 try ext_subs.append (builder.createModule (.{
                   .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ ext_path, entry.path, }), },
                   .target = profile.target,
                   .optimize = profile.optimize,
                 }));
                 ext_subs.items [ext_subs.items.len - 1].addImport ("c", c);
                 ext_subs.items [ext_subs.items.len - 1].addImport ("raw", raw);
                 ext.addImport (std.fs.path.stem (entry.basename), ext_subs.items [ext_subs.items.len - 1]);
               },
      else  => {},
    }
  }

  try modules.append (ext);

  const khr = builder.createModule (.{
    .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, "khr.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  khr.addImport ("c", c);
  khr.addImport ("raw", raw);

  var khr_subs = std.ArrayList (*std.Build.Module).init (builder.allocator);

  const khr_path = try std.fs.path.join (builder.allocator, &.{ path, "khr", });
  var khr_dir = try builder.build_root.handle.openDir (khr_path, .{ .iterate = true, });
  defer khr_dir.close ();

  walker = try khr_dir.walk (builder.allocator);
  defer walker.deinit();

  while (try walker.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => {
                 try khr_subs.append (builder.createModule (.{
                   .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ khr_path, entry.path, }), },
                   .target = profile.target,
                   .optimize = profile.optimize,
                 }));
                 khr_subs.items [khr_subs.items.len - 1].addImport ("c", c);
                 khr_subs.items [khr_subs.items.len - 1].addImport ("raw", raw);
                 khr.addImport (std.fs.path.stem (entry.basename), khr_subs.items [khr_subs.items.len - 1]);
               },
      else  => {},
    }
  }

  try modules.append (khr);

  const vk = builder.createModule (.{
    .root_source_file = .{ .path = try std.fs.path.join (builder.allocator, &.{ path, "vk.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  vk.addImport ("c", c);
  vk.addImport ("raw", raw);
  raw.addImport ("vk", vk);
  for (modules.items) |module|
  {
    vk.addImport (std.fs.path.stem (std.fs.path.basename (module.root_source_file.?.getPath (builder))), module);
    module.addImport ("vk", vk);
  }
  for (khr_subs.items) |khr_sub| khr_sub.addImport ("vk", vk);
  for (ext_subs.items) |ext_sub| ext_sub.addImport ("vk", vk);

  return vk;
}

fn import (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) !void
{
  const datetime_dep = builder.dependency ("zig-datetime", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  const datetime = datetime_dep.module ("zig-datetime");

  const shader = builder.createModule (.{
    .root_source_file = .{ .path = try compile_shaders (builder, exe, profile), },
    .target = profile.target,
    .optimize = profile.optimize,
  });

  const c = try link (builder, profile);

  const glfw = try import_glfw (builder, profile, c);
  const vk = try import_vk (builder, profile, c);

  const imgui = builder.createModule (.{
    .root_source_file = .{ .path = try builder.build_root.join (builder.allocator, &.{ "src", "binding", "imgui.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  imgui.addImport ("c", c);
  imgui.addImport ("glfw", glfw);

  const build_options = profile.variables.createModule ();
  const logger = builder.createModule (.{
    .root_source_file = .{ .path = try builder.build_root.join (builder.allocator, &.{ "src", "logger.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  logger.addImport ("build", build_options);
  logger.addImport ("datetime", datetime);

  const instance = builder.createModule (.{
    .root_source_file = .{ .path = try builder.build_root.join (builder.allocator,
      &.{ "src", "vk", "instance", if (profile.options.turbo) "turbo.zig" else "default.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  instance.addImport ("logger", logger);
  instance.addImport ("vk", vk);

  for ([_] struct { name: [] const u8, ptr: *std.Build.Module, } {
    .{ .name = "datetime", .ptr = datetime, }, .{ .name = "shader", .ptr = shader, },
    .{ .name = "glfw", .ptr = glfw, }, .{ .name = "vk", .ptr = vk, },
    .{ .name = "imgui", .ptr = imgui, }, .{ .name = "logger", .ptr = logger, },
    .{ .name = "instance", .ptr = instance, },
  }) |module| exe.root_module.addImport (module.name, module.ptr);
}

fn run_exe (builder: *std.Build, profile: *const Profile) !void
{
  const exe = builder.addExecutable (.{
    .name = zon.name,
    .root_source_file = .{ .path = try builder.build_root.join (builder.allocator, &.{ "src", "main.zig", }), },
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

fn run_test (builder: *std.Build, profile: *const Profile) !void
{
  const unit_tests = builder.addTest (.{
    .target = profile.target,
    .optimize = profile.optimize,
    .test_runner = try builder.build_root.join (builder.allocator, &.{ "test", "runner.zig", }),
    .root_source_file = .{ .path = try builder.build_root.join (builder.allocator, &.{ "test", "main.zig", }), },
  });
  unit_tests.step.dependOn (builder.getInstallStep ());

  const run_unit_tests = builder.addRunArtifact (unit_tests);

  const test_step = builder.step ("test", "Run tests");
  test_step.dependOn (&run_unit_tests.step);
}
