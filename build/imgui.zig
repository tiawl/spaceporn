const std = @import ("std");

const utils = @import ("utils.zig");
const Package = utils.Package;
const Profile = utils.Profile;
const zon = utils.zon;

pub fn import (builder: *std.Build, profile: *const Profile,
  c: *Package, glfw: *Package, vk: *Package) !*Package
{
  const path = try builder.build_root.join (builder.allocator,
    &.{ "src", zon.name, "bindings", "imgui", });

  var imgui = try Package.init (builder, profile, "imgui",
    try std.fs.path.join (builder.allocator, &.{ path, "imgui.zig", }));
  try imgui.put (c, .{});
  try imgui.put (vk, .{});
  try imgui.put (glfw, .{});

  var sub: *Package = undefined;

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
          sub = try Package.init (builder, profile,
            builder.dupe (std.fs.path.stem (entry.name)),
              try std.fs.path.join (builder.allocator,
                &.{ path, entry.name, }));
          try sub.put (c, .{});
          try sub.put (vk, .{});
          try sub.put (glfw, .{});
          try imgui.put (sub, .{});
          try sub.put (imgui, .{});
        }
      },
      else  => {},
    }
  }

  return imgui;
}
