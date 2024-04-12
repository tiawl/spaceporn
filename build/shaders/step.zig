const std = @import ("std");

const utils = @import ("../utils.zig");
const digest = utils.digest;

const Node = struct
{
  name: [] const u8,
  nodes: std.ArrayList (@This ()),
  hash: [64] u8 = undefined,
  depth: usize = 0,
};

pub const Options = struct
{
  pub const Optimization = enum
  {
    Zero,
    Performance,
  };

  pub const VulkanEnvVersion = enum
  {
    @"0", @"1", @"2", @"3",
  };

  optimization: Optimization,
  vulkan_env_version: VulkanEnvVersion,
};

pub const Step = struct
{
  step: std.Build.Step,
  shader_compiler: *std.Build.Step.Run,
  generated_file: std.Build.GeneratedFile,
  options: Options,
  tree: Node,

  pub fn create (dependency: *std.Build.Dependency,
    options: Options) !*@This ()
  {
    const builder = dependency.builder;
    const self = try builder.allocator.create (@This ());
    const shader_compiler = dependency.artifact ("shader_compiler");
    self.* = .{
      .step = std.Build.Step.init (.{
        .id = .custom,
        .name = "shaders compilation",
        .owner = builder,
        .makeFn = make,
      }),
      .shader_compiler = builder.addRunArtifact (shader_compiler),
      .generated_file = undefined,
      .options = options,
      .tree = .{
        .name = "shaders",
        .nodes = std.ArrayList (Node).init (builder.allocator),
      },
    };
    self.generated_file = .{ .step = &self.step, };
    self.step.dependOn (&shader_compiler.step);
    for ([_][] const u8 {
      @tagName (self.options.optimization),
      @tagName (self.options.vulkan_env_version),
    }) |arg| self.shader_compiler.addArg (arg);
    return self;
  }

  fn add (self: @This (), builder: *std.Build, dir: *std.fs.Dir,
    entry: *const std.fs.Dir.Walker.WalkerEntry, dupe: [] const u8,
    ptr: *Node, depth: *usize) !void
  {
    depth.* += 1;
    if (std.mem.eql (u8, entry.basename, dupe))
    {
      const path = builder.dupe (entry.path);
      const source = try dir.readFileAlloc (builder.allocator, path,
        std.math.maxInt (usize));
      try ptr.nodes.append (.{
        .name = std.fs.path.extension (dupe) [1 ..],
        .nodes = std.ArrayList (Node).init (builder.allocator),
        .hash = digest (self.options, source),
        .depth = depth.*,
      });

      const out = try std.fs.path.join (builder.allocator, &.{
        try builder.cache_root.join (builder.allocator, &.{ "shaders", }),
        &ptr.nodes.items [ptr.nodes.items.len - 1].hash,
      });
      const in = try std.fs.path.join (builder.allocator, &.{
        try builder.build_root.join (builder.allocator, &.{ "shaders", }), path,
      });

      // If we have a cache hit, we can save some compile time by not
      // invoking the compiler again
      shader_not_found: {
        std.fs.accessAbsolute (out, .{}) catch |err| switch (err)
        {
          error.FileNotFound => break :shader_not_found,
          else => return err,
        };
        return;
      }

      for ([_][] const u8 { in, out, }) |arg|
        self.shader_compiler.addArg (arg);
    }
  }

  fn walk_through (self: *@This (), builder: *std.Build) !void
  {
    var dir = try builder.build_root.handle.openDir ("shaders",
      .{ .iterate = true, });
    defer dir.close ();

    var walker = try dir.walk (builder.allocator);
    defer walker.deinit ();
    var depth: usize = undefined;

    var pointer: *Node = undefined;

    while (try walker.next ()) |*entry|
    {
      if (entry.kind == .file)
      {
        var iterator = try std.fs.path.componentIterator (entry.path);
        pointer = &self.tree;
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
              try self.add (builder, &dir, entry, dupe, pointer, &depth);
              continue :next;
            }
          }
          try pointer.nodes.append (.{
            .name = stem,
            .nodes = std.ArrayList (Node).init (builder.allocator),
            .depth = depth,
          });
          pointer = &pointer.nodes.items [pointer.nodes.items.len - 1];
          try self.add (builder, &dir, entry, dupe, pointer, &depth);
        }
      }
    }
  }

  fn write_index (self: *@This (), builder: *std.Build) !void
  {
    var buffer = std.ArrayList (u8).init (builder.allocator);
    const writer = buffer.writer ();

    var stack = std.ArrayList (Node).init (builder.allocator);
    try stack.appendSlice (self.tree.nodes.items);
    var node: Node = undefined;

    while (stack.items.len > 0)
    {
      node = stack.pop ();

      try writer.print ("pub const @\"{s}\" ", .{ node.name, });

      if (node.nodes.items.len == 0 and (std.mem.eql (u8, node.name, "frag")
        or std.mem.eql (u8, node.name, "vert")))
      {
        try writer.print ("align(@alignOf(u32)) = @embedFile(\"{s}\").*;\n",
          .{ node.hash, });
      } else try writer.print ("= struct {c}\n", .{ '{', });

      for (node.nodes.items) |*child| try stack.append (child.*);

      if (stack.getLastOrNull ()) |last|
      {
        if (node.depth > last.depth)
          for (0 .. node.depth - last.depth) |_|
            try writer.print ("{c};\n", .{ '}', });
      } else try writer.print ("{c};\n", .{ '}', });
    }

    try buffer.append (0);
    const source = buffer.items [0 .. buffer.items.len - 1 :0];

    const validated = try std.zig.Ast.parse (builder.allocator, source, .zig);
    const formatted = try validated.render (builder.allocator);

    const hash = &digest (null, formatted);
    const path = try std.fs.path.join (builder.allocator, &.{
      try builder.cache_root.join (builder.allocator, &.{ "shaders", }), hash,
    });

    std.fs.accessAbsolute (path, .{}) catch |err| switch (err)
    {
      error.FileNotFound => try builder.cache_root.handle.writeFile (
        path, formatted),
      else => return err,
    };

    self.generated_file.path = path;
    std.debug.print ("[shader module] {s}\n", .{ path, });
  }

  fn make (step: *std.Build.Step, progress_node: *std.Progress.Node) !void
  {
    const builder = step.owner;
    var self: *@This () = @fieldParentPtr ("step", step);

    builder.cache_root.handle.makeDir ("shaders") catch |err|
    {
      if (err != error.PathAlreadyExists) return err;
    };

    try self.walk_through (builder);

    try self.shader_compiler.step.makeFn (&self.shader_compiler.step,
      progress_node);

    try self.write_index (builder);
  }

  pub fn compileModule (dependency: *std.Build.Dependency,
    options: Options) !*std.Build.Module
  {
    const step = try create (dependency, options);
    const builder = dependency.builder;
    return builder.createModule (.{
      .root_source_file = .{ .generated = &step.generated_file, },
      .target = builder.host,
      .optimize = .Debug,
    });
  }
};
