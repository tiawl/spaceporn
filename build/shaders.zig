const std = @import ("std");

const utils = @import ("utils.zig");
const digest = utils.digest;

const Node = struct
{
  name: [] const u8,
  nodes: std.ArrayList (@This ()),
  hash: [64] u8 = undefined,
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
  shaders_compiler: *std.Build.Step.Run,
  generated_file: std.Build.GeneratedFile,
  options: Options,
  tree: Node,

  pub fn create (dependency: *std.Build.Dependency,
    options: Options) !*@This ()
  {
    const builder = dependency.builder;
    const self = try builder.allocator.create (@This ());
    const shaders_compiler = dependency.artifact ("shaders_compiler");
    self.* = .{
      .step = std.Build.Step.init (.{
        .id = .custom,
        .name = "shaders compilation",
        .owner = builder,
        .makeFn = make,
      }),
      .shaders_compiler = builder.addRunArtifact (shaders_compiler),
      .generated_file = undefined,
      .options = options,
      .tree = .{
        .name = "shaders",
        .nodes = std.ArrayList (Node).init (builder.allocator),
      },
    };
    self.generated_file = .{ .step = &self.step, };
    self.step.dependOn (&shaders_compiler.step);
    return self;
  }

  fn add (self: @This (), builder: *std.Build, dir: *std.fs.Dir,
    entry: *const std.fs.Dir.Walker.Entry, dupe: [] const u8,
    ptr: *Node) !void
  {
    if (!std.mem.eql (u8, entry.basename, dupe)) return;

    const path = builder.dupe (entry.path);
    const source = try dir.readFileAlloc (builder.allocator, path,
      std.math.maxInt (usize));

    if (!std.mem.startsWith (u8, source, "#version ")) return;

    try ptr.nodes.append (.{
      .name = std.fs.path.extension (dupe) [1 ..],
      .nodes = std.ArrayList (Node).init (builder.allocator),
      .hash = digest (self.options, source),
    });

    const in = try std.fs.path.join (builder.allocator, &.{
      try builder.build_root.join (builder.allocator, &.{ "shaders", }), path,
    });

    const out = try std.fs.path.join (builder.allocator, &.{
      try builder.cache_root.join (builder.allocator, &.{ "shaders", }),
      &ptr.nodes.items [ptr.nodes.items.len - 1].hash,
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

    for ([_][] const u8 { in, out, }) |arg| self.shaders_compiler.addArg (arg);
  }

  fn walk_through (self: *@This (), builder: *std.Build) !void
  {
    var dir = try builder.build_root.handle.openDir ("shaders",
      .{ .iterate = true, });
    defer dir.close ();

    var walker = try dir.walk (builder.allocator);
    defer walker.deinit ();

    var pointer: *Node = undefined;

    while (try walker.next ()) |*entry|
    {
      if (entry.kind == .file)
      {
        var iterator = try std.fs.path.componentIterator (entry.path);
        pointer = &self.tree;
        next: while (iterator.next ()) |*component|
        {
          const dupe = builder.dupe (component.name);
          const stem = std.fs.path.stem (dupe);
          for (pointer.nodes.items) |*node|
          {
            if (std.mem.eql (u8, node.name, stem))
            {
              pointer = node;
              try self.add (builder, &dir, entry, dupe, pointer);
              continue :next;
            }
          }
          try pointer.nodes.append (.{
            .name = stem,
            .nodes = std.ArrayList (Node).init (builder.allocator),
          });
          pointer = &pointer.nodes.items [pointer.nodes.items.len - 1];
          try self.add (builder, &dir, entry, dupe, pointer);
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

      if (node.name.len == 0)
      {
        try writer.print ("{c};\n", .{ '}', });
      } else if (node.nodes.items.len == 0 and
        (std.mem.eql (u8, node.name, "frag") or
          std.mem.eql (u8, node.name, "vert"))) {
            try writer.print ("pub const @\"{s}\" align(@alignOf(u32)) = @embedFile(\"{s}\").*;\n",
              .{ node.name, node.hash, });
      } else {
        try writer.print ("pub const @\"{s}\" = struct {c}\n",
          .{ node.name, '{', });
        try stack.append (.{
          .name = "",
          .nodes = undefined,
        });
        try stack.appendSlice (node.nodes.items);
      }
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
        .{ .sub_path = path, .data = formatted, }),
      else => return err,
    };

    self.generated_file.path = path;
    std.debug.print ("[shader module] {s}\n", .{ path, });
  }

  fn make (step: *std.Build.Step, progress_node: std.Progress.Node) !void
  {
    const builder = step.owner;
    var self: *@This () = @fieldParentPtr ("step", step);

    builder.cache_root.handle.makeDir ("shaders") catch |err|
    {
      if (err != error.PathAlreadyExists) return err;
    };

    for ([_][] const u8 {
      @tagName (self.options.optimization),
      @tagName (self.options.vulkan_env_version),
    }) |arg| self.shaders_compiler.addArg (arg);

    try self.walk_through (builder);

    try self.shaders_compiler.step.makeFn (&self.shaders_compiler.step,
      progress_node);

    try self.write_index (builder);
  }

  pub fn compileModule (dependency: *std.Build.Dependency,
    options: Options) !*std.Build.Module
  {
    const step = try create (dependency, options);
    const builder = dependency.builder;
    return builder.createModule (.{
      .root_source_file = .{ .generated = .{ .file = &step.generated_file }, },
      .target = builder.host,
      .optimize = .Debug,
    });
  }
};
