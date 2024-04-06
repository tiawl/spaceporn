const std = @import ("std");

const Profile = @import ("utils.zig").Profile;

pub fn import (builder: *std.Build, profile: *const Profile,
  c: *std.Build.Module, glfw: *std.Build.Module,
  vk: *std.Build.Module) !*std.Build.Module
{
  const path = try builder.build_root.join (builder.allocator,
    &.{ "src", "binding", "imgui", });

  var modules = std.ArrayList (*std.Build.Module).init (builder.allocator);

  var dir = try builder.build_root.handle.openDir (path, .{ .iterate = true, });
  defer dir.close ();

  var it = dir.iterate ();
  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => {
        if (!std.mem.eql (u8, entry.name, "imgui.zig"))
        {
          try modules.append (builder.createModule (.{
            .root_source_file = .{ .path = try std.fs.path.join (
              builder.allocator, &.{ path, entry.name, }), },
            .target = profile.target,
            .optimize = profile.optimize,
          }));
          modules.items [modules.items.len - 1].addImport ("c", c);
          modules.items [modules.items.len - 1].addImport ("glfw", glfw);
          modules.items [modules.items.len - 1].addImport ("vk", vk);
        }
      },
      else  => {},
    }
  }

  const imgui = builder.createModule (.{
    .root_source_file = .{ .path = try std.fs.path.join (builder.allocator,
      &.{ path, "imgui.zig", }), },
    .target = profile.target,
    .optimize = profile.optimize,
  });
  imgui.addImport ("c", c);

  for (modules.items) |module|
  {
    const name = std.fs.path.stem (
      std.fs.path.basename (module.root_source_file.?.getPath (builder)));
    imgui.addImport (name, module);
    module.addImport ("imgui", imgui);
    for (modules.items) |other|
    {
      const other_name = std.fs.path.stem (
        std.fs.path.basename (other.root_source_file.?.getPath (builder)));
      if (std.mem.eql (u8, name, other_name)) continue;
      module.addImport (other_name, other);
    }
  }

  return imgui;
}
