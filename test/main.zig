const std = @import ("std");

const this = struct
{
  pub const sample = @import ("sample.zig");
};

comptime
{
  std.testing.refAllDeclsRecursive (this);
}
