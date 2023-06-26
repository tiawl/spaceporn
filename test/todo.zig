const std = @import ("std");
test "test" {

  const start_time = try std.time.Instant.now();
  //const t: f64 = @intToFloat(f64, std.time.nanoTimestamp()) / 1_000_000_000.0;
  const t = (@floatFromInt(f32, (try std.time.Instant.now()).since(start_time)) / @floatFromInt(f32, std.time.ns_per_s));
  std.debug.print ("{d:.9}\n", .{t});
}
