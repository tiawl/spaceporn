const std = @import ("std");

test "iter"
{
   const dir = try std.fs.openDirAbsolute("/home/user/Workspace/spacedream", .{});
   const iter_dir = try dir.openIterableDir(".", .{});

   var iter = iter_dir.iterate();
   while (try iter.next()) |entry|
   {
     std.debug.print ("{s}\n", .{entry.name});
   }

   try std.testing.expect(0 == 0);
}
