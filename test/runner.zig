const std = @import ("std");
const builtin = @import ("builtin");

const Status = enum
{
  succeed,
  fail,
  skip,
  leak,
  text,
};

pub fn main () !void
{
  const printer = Printer.init ();

  printer.fmt ("\r\x1b[0K", .{});

  var succeed: usize = 0;
  var fail: usize = 0;
  var skip: usize = 0;
  var leak: usize = 0;

  for (builtin.test_functions) |@"test"|
  {
    std.testing.allocator_instance = .{};
    var status = Status.succeed;

    const test_name = @"test".name [5 ..];
    const result = @"test".func ();

    if (std.testing.allocator_instance.deinit () == .leak)
    {
      status = .leak;
      leak += 1;
    } else if (result) |_| {
      succeed += 1;
    } else |err| {
      switch (err) {
        error.SkipZigTest => {
                               status = .skip;
                               skip += 1;
                             },
        else => {
                  status = .fail;
                  fail += 1;
                  printer.status (status, "[{s}: {s}] \"{s}\"\n", .{ @tagName (status), @errorName (err), test_name });
                  if (@errorReturnTrace ()) |trace| std.debug.dumpStackTrace (trace.*);
                  continue;
                },
      }
    }
    printer.status (status, "[{s}] \"{s}\"\n", .{ @tagName (status), test_name });
  }

  const total_tests = succeed + fail + skip + leak;
  printer.status (.text, "\x1b[0m" ++ "*" ** 80 ++ "\nFor {d} test{s}:\n", .{ total_tests, if (total_tests > 1) "s" else "" });
  printer.status (.succeed, "- {d} test{s} succeded\n", .{ succeed, if (succeed > 1) "s" else "" });
  printer.status (.fail, "- {d} test{s} failed\n", .{ fail, if (fail > 1) "s" else "" });
  printer.status (.leak, "- {d} test{s} leaked\n", .{ leak, if (leak > 1) "s" else "" });
  printer.status (.skip, "- {d} test{s} skipped\n", .{ skip, if (skip > 1) "s" else "" });
  std.os.exit (if (fail == 0) 0 else 1);
}

const Printer = struct
{
  out: std.fs.File.Writer,

  fn init () Printer
  {
    return .{ .out = std.io.getStdErr ().writer (), };
  }

  fn fmt (self: Printer, comptime format: [] const u8, args: anytype) void
  {
    std.fmt.format (self.out, format, args) catch unreachable;
  }

  fn status (self: Printer, s: Status, comptime format: [] const u8, args: anytype) void
  {
    const color = switch (s)
    {
      .succeed => "\x1b[32m",
      .fail => "\x1b[31m",
      .leak => "\x1b[33m",
      .skip => "\x1b[36m",
      else  => "",
    };
    const out = self.out;
    out.writeAll (color) catch @panic ("writeAll failed?!");
    std.fmt.format (out, format, args) catch @panic ("std.fmt.format failed?!");
    self.fmt ("\x1b[0m", .{});
  }
};
