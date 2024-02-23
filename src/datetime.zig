const std = @import ("std");

pub fn now (allocator: std.mem.Allocator) ![] const u8
{
  const ns_time = std.time.nanoTimestamp ();
  const instant = @import ("datetime").datetime.Datetime.fromTimestamp (@intCast (@divFloor (ns_time, std.time.ns_per_ms)));

  return try std.fmt.allocPrint (allocator,
    "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>9}",
    .{
       instant.date.year,
       instant.date.month,
       instant.date.day,
       instant.time.hour,
       instant.time.minute,
       instant.time.second,
       @as (u32, @intCast (@mod (ns_time, 1_000_000_000))),
     },
  );
}
