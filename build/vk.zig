const std = @import ("std");

const utils = @import ("utils.zig");
const digest = utils.digest;
const Profile = utils.Profile;

fn generate_literals (builder: *std.Build) ![] const u8
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

pub fn import (builder: *std.Build, profile: *const Profile, c: *std.Build.Module) !*std.Build.Module
{
  const literals = builder.createModule (.{
    .root_source_file = .{ .path = try generate_literals (builder), },
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
