const std = @import ("std");

const build = @import ("build_options");

pub const exe: [*:0] const u8 = build.EXE.ptr[0..build.EXE.len :0];

pub fn debug_vk (comptime format: [] const u8, args: anytype) !void
{
  if (build.DEV)
  {
    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const allocator = gpa.allocator ();

    const expanded_format = std.fmt.allocPrint(allocator, format, args) catch |err|
    {
      std.log.err ("debug_vk expanded_format allocPrint error", .{});
      return err;
    };
    defer allocator.free(expanded_format);

    std.log.debug ("[vulkan] {s}", .{ expanded_format });
  }
}

pub fn debug_spacedream (comptime format: [] const u8, args: anytype) !void
{
  if (build.DEV)
  {
    var gpa = std.heap.GeneralPurposeAllocator (.{}){};
    defer _ = gpa.deinit ();
    const allocator = gpa.allocator ();

    const expanded_format = std.fmt.allocPrint(allocator, format, args) catch |err|
    {
      std.log.err ("debug_spacedream expanded_format allocPrint error", .{});
      return err;
    };
    defer allocator.free(expanded_format);

    std.log.debug ("[spacedream] {s}", .{ expanded_format });
  }
}
