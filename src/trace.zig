const std = @import("std");
const c = @import("c");
const log = @import("log");

export fn traceFunctionCall(called: [*:0]const c_char, args: [*:0]const c_char, file: [*:0]const c_char, line: c_int, caller: [*:0]const c_char, ...) callconv(.c) void {
    var va_list: ?std.lang.VaList = @cVaStart();
    defer @cVaEnd(&va_list.?);
    const called_u8: [*:0]const u8 = @ptrCast(called);
    const args_u8: [*:0]const u8 = @ptrCast(args);
    const file_u8: [*:0]const u8 = @ptrCast(file);
    const caller_u8: [*:0]const u8 = @ptrCast(caller);
    log.header.trace();
    log.writer().print("{s}:{d}:{s}: {s}({s})", .{ file_u8, line, caller_u8, called_u8, args_u8 }) catch {};
    log.writer().flush() catch {};
}
