const std = @import("std");

test "simple test"
{
  var list = std.ArrayList(i32).init(std.testing.allocator);
  defer list.deinit();
  try list.append(42);
  try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "error test"
{
  var list = std.ArrayList(i32).init(std.testing.allocator);
  defer list.deinit();
  try list.append(42);
  try std.testing.expectEqual(@as(i32, 32), list.pop());
}

test "skipped test"
{
  return error.SkipZigTest;
}

test "memory leak test"
{
  var list = std.ArrayList(i32).init(std.testing.allocator);
  try list.append(42);
  try std.testing.expectEqual(@as(i32, 42), list.pop());
}
