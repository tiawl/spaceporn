const std = @import ("std");

const Profile = @import ("utils.zig").Profile;

pub fn import (builder: *std.Build, profile: *const Profile, c: *std.Build.Module) !*std.Build.Module
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

pub fn lib (builder: *std.Build, profile: *const Profile) *std.Build.Step.Compile
{
  const dep = builder.dependency ("glfw", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  return dep.artifact ("glfw");
}
