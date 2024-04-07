const std = @import ("std");

const utils = @import ("utils.zig");
const Package = utils.Package;
const Profile = utils.Profile;

pub fn import (builder: *std.Build, profile: *const Profile,
  c: *Package) !*Package
{
  const path = try builder.build_root.join (builder.allocator,
    &.{ "src", "binding", "glfw", });

  var glfw = try Package.init (builder, profile, "glfw",
    try std.fs.path.join (builder.allocator, &.{ path, "glfw.zig", }));
  try glfw.put (c, .{});

  var sub: *Package = undefined;

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
          sub = try Package.init (builder, profile,
            builder.dupe (std.fs.path.stem (entry.name)),
            try std.fs.path.join (builder.allocator, &.{ path, entry.name, }));
          try sub.put (c, .{});
          try glfw.put (sub, .{});
          try sub.put (glfw, .{});
        }
      },
      else  => {},
    }
  }

  return glfw;
}

pub fn lib (builder: *std.Build,
  profile: *const Profile) *std.Build.Step.Compile
{
  const dep = builder.dependency ("glfw", .{
    .target = profile.target,
    .optimize = profile.optimize,
  });
  return dep.artifact ("glfw");
}
