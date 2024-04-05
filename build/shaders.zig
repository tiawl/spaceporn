const std = @import ("std");

const utils = @import ("utils.zig");
const digest = utils.digest;
const Profile = utils.Profile;

const Node = struct
{
  name: [] const u8,
  nodes: std.ArrayList (@This ()),
  hash: [64] u8 = undefined,
  depth: usize = 0,
};

fn add (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile,
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

fn walk_through (builder: *std.Build, exe: *std.Build.Step.Compile,
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
            try add (builder, exe, profile, &glsl, entry, dupe, pointer, &depth);
            continue :next;
          }
        }
        try pointer.nodes.append (.{ .name = stem, .nodes = std.ArrayList (Node).init (builder.allocator), .depth = depth, });
        pointer = &pointer.nodes.items [pointer.nodes.items.len - 1];
        try add (builder, exe, profile, &glsl, entry, dupe, pointer, &depth);
      }
    }
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

  std.debug.print ("[shader module] {s}\n", .{ path, });
  return path;
}

fn compile (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) ![] const u8
{
  var tree: Node = .{ .name = "shaders", .nodes = std.ArrayList (Node).init (builder.allocator), };

  builder.cache_root.handle.makeDir ("shaders") catch |err|
  {
    if (err != std.fs.File.OpenError.PathAlreadyExists) return err;
  };

  try walk_through (builder, exe, profile, &tree);
  return try write_index (builder, &tree);
}

pub fn import (builder: *std.Build, exe: *std.Build.Step.Compile, profile: *const Profile) !*std.Build.Module
{
  return builder.createModule (.{
    .root_source_file = .{ .path = try compile (builder, exe, profile), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
}
