const std = @import ("std");
test "test" {
  const t: f64 = @intToFloat(f64, std.time.nanoTimestamp()) / 1_000_000_000.0;
  std.debug.print ("{d:.9}\n", .{t});
}
