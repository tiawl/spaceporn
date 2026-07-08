const std = @import("std");
const c = @import("c");
const js = @import("js");

const malloc_align_bytes = 16;
const alloc_align = std.mem.Alignment.fromByteUnits(malloc_align_bytes);
const alloc_metadata_len = std.mem.alignForward(usize, malloc_align_bytes, @sizeOf(usize));
var allocator = std.heap.wasm_allocator;

// This incomplete libc is implemented for imgui compilation on a wasm-freestanding target.
// It is not aimed to be fully implemented.
// It relies on Zig std libc and on brower capabilities.
// When none of these possibilities allow us to implement a function, it panics

// From https://0xkiire.com/wasm-with-zig/:
//   - The usable stdlib subset is:
//     - std.math,
//     - std.mem,
//     - std.fmt.bufPrint,
//     - std.sort,
//     - std.unicode,
//     - std.json (partially),
//     - std.crypto,
//     - and the built-in types and builtins.
//   - these standard library features work correctly in freestanding WASM:
//     - std.math.* — all math functions
//     - std.mem.* — all memory utilities
//     - std.fmt.bufPrint — format to a fixed-size buffer (does not use std.Io)
//     - std.sort.* — sorting algorithms
//     - std.unicode.* — UTF-8 utilities
//     - std.Io.Writer.fixed(&buf) — fixed-buffer writer (does not use Threaded)
//     - std.crypto.* — cryptographic primitives
//     - @import("builtin") — target information

pub var errno: c_int = 0;

fn tryAppendBuf(writer: *std.Io.Writer, size_opt: ?usize, buf_off: *usize, data: []const c_char) bool {
    if (size_opt) |size| {
        if (buf_off.* + data.len > size - 1) return false; // room to null terminate
    }
    writer.writeAll(@ptrCast(@alignCast(data))) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    buf_off.* += data.len;
    return true;
}

fn format(writer: *std.Io.Writer, size: ?usize, c_fmt: [*:0]const c_char, va_list: *std.lang.VaList) c_int {
    const fmt = std.mem.span(c_fmt);
    if (fmt.len == 0) std.debug.panic("{s}: null fmt", .{@src().fn_name});

    var buf_off: usize = 0;

    var skip_idx: usize = 0;
    for (fmt, 0..) |byte, i| {
        if (skip_idx > 0 or i > 0) {
            if (i <= skip_idx) continue;
        }
        if (byte != '%') {
            if (!tryAppendBuf(writer, size, &buf_off, &.{byte})) {
                writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
                return @intCast(buf_off);
            }
            continue;
        }
        const ch = fmt[i + 1];
        skip_idx = i + 1;
        if (ch == 0) break;

        var buf: [32]u8 = undefined;

        switch (ch) {
            'd' => {
                const s = std.fmt.bufPrint(&buf, "{d}", .{@cVaArg(va_list, c_int)}) catch &.{};
                if (!tryAppendBuf(writer, size, &buf_off, @ptrCast(s))) {
                    writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
                    return @intCast(buf_off);
                }
            },
            'x' => {
                const s = std.fmt.bufPrint(&buf, "{x}", .{@cVaArg(va_list, usize)}) catch &.{};
                if (!tryAppendBuf(writer, size, &buf_off, @ptrCast(s))) {
                    writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
                    return @intCast(buf_off);
                }
            },
            'p' => {
                const s = std.fmt.bufPrint(&buf, "{p}", .{@cVaArg(va_list, *usize)}) catch &.{};
                if (!tryAppendBuf(writer, size, &buf_off, @ptrCast(s))) {
                    writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
                    return @intCast(buf_off);
                }
            },
            's' => {
                const s = std.mem.span(@cVaArg(va_list, [*:0]const u8));
                if (!tryAppendBuf(writer, size, &buf_off, @ptrCast(s))) {
                    writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
                    return @intCast(buf_off);
                }
            },
            '%' => if (!tryAppendBuf(writer, size, &buf_off, &.{'%'})) {
                writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
                return @intCast(buf_off);
            },
            else => std.debug.panic("{s}: unknown %{c} sequence", .{ @src().fn_name, @as(u8, @intCast(ch)) }),
        }
    }
    writer.writeByte(0) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});

    return @intCast(buf_off);
}

pub fn acos(x: f64) callconv(.c) f64 {
    return std.math.acos(x);
}

pub fn acosf(x: f32) callconv(.c) f32 {
    return std.math.acos(x);
}

pub fn assertFail(expr: [*:0]const c_char, file: [*:0]const c_char, line: c_int, func: [*:0]const c_char) callconv(.c) void {
    js.console.assert(false, .{
        .module = std.mem.span(@as([*:0]const u8, @ptrCast(expr))),
        .file = std.mem.span(@as([*:0]const u8, @ptrCast(file))),
        .fn_name = std.mem.span(@as([*:0]const u8, @ptrCast(func))),
        .line = std.math.cast(u32, line) orelse 0,
        .column = 0,
    });
}

pub fn atan2f(y: f32, x: f32) callconv(.c) f32 {
    return std.math.atan2(y, x);
}

pub fn atof(str_opt: ?[*:0]const c_char) callconv(.c) f64 {
    if (str_opt) |str| {
        const str_u8 = std.mem.span(@as([*:0]const u8, @ptrCast(str)));
        return std.fmt.parseFloat(f64, str_u8) catch std.debug.panic("{s}: parseFloat failed", .{@src().fn_name});
    } else std.debug.panic("{s}: str parameter is null", .{@src().fn_name});
}

pub fn ceilf(x: f32) callconv(.c) f32 {
    return std.math.ceil(x);
}

pub fn cos(x: f64) callconv(.c) f64 {
    return std.math.cos(x);
}

pub fn cosf(x: f32) callconv(.c) f32 {
    return std.math.cos(x);
}

pub fn execvp(path: ?[*:0]const c_char, argv: ?[*:null]const ?[*:0]c_char) callconv(.c) c_int {
    _ = .{ path, argv };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn exit(exit_code: c_int) callconv(.c) noreturn {
    _ = exit_code;
    @panic(@src().fn_name ++ " not implemented");
}

pub fn fabs(x: f64) callconv(.c) f64 {
    return @abs(x);
}

pub fn fabsf(x: f32) callconv(.c) f32 {
    return @abs(x);
}

pub fn fclose(stream: ?*c.FILE) callconv(.c) c_int {
    _ = stream;
    @panic(@src().fn_name ++ " not implemented");
}

pub fn fflush(stream: ?*c.FILE) callconv(.c) c_int {
    _ = stream;
    @panic(@src().fn_name ++ " not implemented");
}

pub fn floorf(x: f32) callconv(.c) f32 {
    return std.math.floor(x);
}

pub fn fmodf(x: f32, y: f32) callconv(.c) f32 {
    return std.math.mod(f32, x, y) catch js.console.err("{s}: denominator is zero or negative", .{@src().fn_name});
}

pub fn fopen(filename: ?[*:0]const c_char, mode: ?[*:0]const c_char) callconv(.c) ?*c.FILE {
    _ = .{ filename, mode };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn fread(noalias ptr: ?[*]c_char, size_of_type: usize, item_count: usize, noalias stream: ?*c.FILE) callconv(.c) usize {
    _ = .{ ptr, size_of_type, item_count, stream };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn fork() callconv(.c) c.pid_t {
    @panic(@src().fn_name ++ " not implemented");
}

pub fn fprintf(stream: ?*c.FILE, c_fmt_opt: ?[*:0]const c_char, ...) callconv(.c) c_int {
    _ = stream;
    if (c_fmt_opt) |c_fmt| {
        var va_list = @cVaStart();
        defer @cVaEnd(&va_list);
        var writer = js.console.log.writer();
        const result = format(writer, null, c_fmt, &va_list);
        writer.flush() catch {};
        return result;
    } else std.debug.panic("{s}: c_fmt parameter is null", .{@src().fn_name});
}

pub fn free(p: ?[*]align(@alignOf(usize)) u8) callconv(.c) void {
    const ptr = p orelse return;
    const start = @intFromPtr(ptr) - alloc_metadata_len;
    const len = @as(*usize, @ptrFromInt(start)).*;
    allocator.free(@as([]align(malloc_align_bytes) u8, @alignCast(@as([*]u8, @ptrFromInt(start))[0..len])));
}

pub fn fseek(stream: ?*c.FILE, offset: c_long, whence: c_int) callconv(.c) c_int {
    _ = .{ stream, offset, whence };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn ftell(stream: ?*c.FILE) callconv(.c) c_long {
    _ = stream;
    @panic(@src().fn_name ++ " not implemented");
}

pub fn fwrite(noalias ptr: ?[*]const u8, size_of_type: usize, item_count: usize, noalias stream: ?*c.FILE) callconv(.c) usize {
    _ = .{ ptr, size_of_type, item_count, stream };
    @panic(@src().fn_name ++ " not implemented");
}

// Number of days before Jan 1st of year
fn daysBeforeYear(year: u32) u32 {
    const y: u32 = year - 1;
    return y * 365 + @divFloor(y, 4) - @divFloor(y, 100) + @divFloor(y, 400);
}

const DAYS_BEFORE_MONTH = [12]u16{ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

// Number of days in year preceding the first day of month
fn daysBeforeMonth(year: u16, month: u32) u32 {
    js.console.assert(month >= 1 and month <= 12, @src());
    var d = DAYS_BEFORE_MONTH[month - 1];
    if (month > 2 and std.time.epoch.isLeapYear(year)) d += 1;
    return d;
}

// Days before 1 Jan 1970
const EPOCH = daysBeforeYear(1970);

// Days before 1 Jan 1900
const NTP_EPOCH = daysBeforeYear(1900);

const MAX_ORDINAL: u32 = 3652059;

fn fromOrdinal(result: *c.tm, ordinal: u32) void {
    // n is a 1-based index, starting at 1-Jan-1. The pattern of leap years
    // repeats exactly every 400 years. The basic strategy is to find the
    // closest 400-year boundary at or before n, then work with the offset
    // from that boundary to n. Life is much clearer if we subtract 1 from
    // n first -- then the values of n at 400-year boundaries are exactly
    // those divisible by DI400Y:
    //
    //     D  M   Y            n              n-1
    //     -- --- ----        ----------     ----------------
    //     31 Dec -400        -DI400Y        -DI400Y -1
    //      1 Jan -399        -DI400Y +1     -DI400Y       400-year boundary
    //     ...
    //     30 Dec  000        -1             -2
    //     31 Dec  000         0             -1
    //      1 Jan  001         1              0            400-year boundary
    //      2 Jan  001         2              1
    //      3 Jan  001         3              2
    //     ...
    //     31 Dec  400         DI400Y        DI400Y -1
    //      1 Jan  401         DI400Y +1     DI400Y        400-year boundary
    js.console.assert(ordinal >= 1 and ordinal <= MAX_ORDINAL, @src());

    var n = ordinal - 1;
    const DI400Y = comptime daysBeforeYear(401); // Num of days in 400 years
    const DI100Y = comptime daysBeforeYear(101); // Num of days in 100 years
    const DI4Y = comptime daysBeforeYear(5); // Num of days in 4 years
    const n400 = @divFloor(n, DI400Y);
    n = @mod(n, DI400Y);
    var year = std.math.cast(u16, n400 * 400 + 1) orelse std.debug.panic("{s}: failed to cast {s} to u16", .{ @src().fn_name, @typeName(@TypeOf(n400)) }); // ..., -399, 1, 401, ...

    // Now n is the (non-negative) offset, in days, from January 1 of year, to
    // the desired date. Now compute how many 100-year cycles precede n.
    // Note that it's possible for n100 to equal 4. In that case 4 full
    // 100-year cycles precede the desired day, which implies the desired
    // day is December 31 at the end of a 400-year cycle.
    const n100 = @divFloor(n, DI100Y);
    n = @mod(n, DI100Y);

    // Now compute how many 4-year cycles precede it.
    const n4 = @divFloor(n, DI4Y);
    n = @mod(n, DI4Y);

    // And now how many single years. Again n1 can be 4, and again meaning
    // that the desired day is December 31 at the end of the 4-year cycle.
    const n1 = @divFloor(n, 365);
    n = @mod(n, 365);

    const year_incr = n100 * 100 + n4 * 4 + n1;
    year += std.math.cast(u16, year_incr) orelse std.debug.panic("{s}: failed to cast {s} to u16", .{ @src().fn_name, @typeName(@TypeOf(year_incr)) });

    if (n1 == 4 or n100 == 4) {
        js.console.assert(n == 0, @src());
        result.tm_year = std.math.cast(c_int, year - 1) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @src().fn_name, @typeName(@TypeOf(year)) });
        result.tm_mon = 11;
        result.tm_mday = 31;
        return;
    }

    // Now the year is correct, and n is the offset from January 1. We find
    // the month via an estimate that's either exact or one too large.
    const leapyear = (n1 == 3) and (n4 != 24 or n100 == 3);
    js.console.assert(leapyear == std.time.epoch.isLeapYear(year), @src());
    var month = (n + 50) >> 5;
    if (month == 0) month = 12; // Loop around
    var preceding = daysBeforeMonth(year, month);

    if (preceding > n) { // estimate is too large
        month -= 1;
        if (month == 0) month = 12; // Loop around
        preceding -= std.time.epoch.getDaysInMonth(year, @fromBackingInt(std.math.cast(u4, month) orelse std.debug.panic("{s}: failed to cast {s} to u4", .{ @src().fn_name, @typeName(@TypeOf(month)) })));
    }
    n -= preceding;

    // Now the year and month are correct, and n is the offset from the
    // start of that month
    result.tm_year = year - 1;
    result.tm_mon = std.math.cast(c_int, month - 1) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @src().fn_name, @typeName(@TypeOf(month)) });
    result.tm_mday = std.math.cast(c_int, n + 1) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @src().fn_name, @typeName(@TypeOf(n)) });
}

// Implementation coming from: https://github.com/frmdstryr/zig-datetime/blob/master/src/datetime.zig
pub fn localtime_r(timep: ?*const c.time_t, result: ?*c.tm) callconv(.c) *c.tm {
    if (timep == null) js.console.err("{s}: timep parameter is null", .{@src().fn_name});
    if (result == null) js.console.err("{s}: result parameter is null", .{@src().fn_name});
    const days = @divFloor(timep.?.*, std.time.s_per_day) + @as(c.time_t, EPOCH) - @as(c.time_t, NTP_EPOCH);
    js.console.assert(days >= 0 and days <= MAX_ORDINAL, @src());
    fromOrdinal(result.?, std.math.cast(u32, days) orelse std.debug.panic("{s}: failed to cast {s} to u32", .{ @src().fn_name, @typeName(@TypeOf(days)) }));
    return result.?;
}

pub fn log(x: f64) callconv(.c) f64 {
    return std.math.log(f64, std.math.e, x);
}

pub fn logf(x: f32) callconv(.c) f32 {
    return std.math.log(f32, std.math.e, x);
}

pub fn malloc(n: usize) callconv(.c) ?[*]align(malloc_align_bytes) u8 {
    if (n == 0) return null;
    const full_len = alloc_metadata_len + n;
    const buf = allocator.alignedAlloc(u8, alloc_align, full_len) catch return null;
    @as(*usize, @ptrCast(buf)).* = full_len;
    const result = @as([*]align(malloc_align_bytes) u8, @ptrFromInt(@intFromPtr(buf.ptr) + alloc_metadata_len));
    return result;
}

pub fn memchr(ptr: ?*const anyopaque, value: c_int, len: usize) callconv(.c) ?*anyopaque {
    if (ptr == null) return null;
    const idx = std.mem.findScalar(u8, @as([*]const u8, @ptrCast(ptr.?))[0..len], @truncate(@as(c_uint, @bitCast(value)))) orelse return null;
    return @constCast(@as([*]const u8, @ptrCast(ptr.?)) + idx);
}

pub fn memcmp(vl: ?*const anyopaque, vr: ?*const anyopaque, n: usize) callconv(.c) c_int {
    if (vl == null) js.console.err("{s}: vl parameter is null", .{@src().fn_name});
    if (vr == null) js.console.err("{s}: vr parameter is null", .{@src().fn_name});
    var i: usize = 0;
    while (i < n) : (i += 1) {
        const compared = @as(c_int, @as([*]const u8, @ptrCast(vl.?))[i]) -% @as(c_int, @as([*]const u8, @ptrCast(vr.?))[i]);
        if (compared != 0) return compared;
    }
    return 0;
}

pub fn memcpy(noalias dst: ?*anyopaque, noalias src: ?*const anyopaque, len: usize) callconv(.c) ?[*]c_char {
    if (dst == null) js.console.err("{s}: dst parameter is null", .{@src().fn_name});
    if (src == null) js.console.err("{s}: src parameter is null", .{@src().fn_name});
    @memcpy(@as([*]c_char, @ptrCast(dst.?))[0..@intCast(len)], @as([*]const c_char, @ptrCast(src.?))[0..@intCast(len)]);
    return @ptrCast(dst);
}

pub fn memmove(dst: ?*anyopaque, src: ?*const anyopaque, len: usize) callconv(.c) ?[*]c_char {
    if (dst == null) js.console.err("{s}: dst parameter is null", .{@src().fn_name});
    if (src == null) js.console.err("{s}: src parameter is null", .{@src().fn_name});
    @memmove(@as([*]c_char, @ptrCast(dst.?))[0..@intCast(len)], @as([*]const c_char, @ptrCast(src.?))[0..@intCast(len)]);
    return @ptrCast(dst);
}

pub fn memset(dst: ?*anyopaque, ch: c_char, len: usize) callconv(.c) ?[*]c_char {
    if (dst == null) js.console.err("{s}: dst parameter is null", .{@src().fn_name});
    @memset(@as([*]c_char, @ptrCast(dst.?))[0..@intCast(len)], ch);
    return @ptrCast(dst);
}

pub fn pow(x: f64, y: f64) callconv(.c) f64 {
    return std.math.pow(f64, x, y);
}

pub fn powf(x: f32, y: f32) callconv(.c) f32 {
    return std.math.pow(f32, x, y);
}

fn qsort_r(base: *anyopaque, n: usize, size: usize, compare: *const fn (a: *const anyopaque, b: *const anyopaque, arg: ?*anyopaque) callconv(.c) c_int, arg: ?*anyopaque) void {
    const Context = struct {
        base: [*]u8,
        size: usize,
        compare: *const fn (a: *const anyopaque, b: *const anyopaque, arg: ?*anyopaque) callconv(.c) c_int,
        arg: ?*anyopaque,

        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            return ctx.compare(&ctx.base[a * ctx.size], &ctx.base[b * ctx.size], ctx.arg) < 0;
        }

        pub fn swap(ctx: @This(), a: usize, b: usize) void {
            const a_bytes: []u8 = ctx.base[a * ctx.size ..][0..ctx.size];
            const b_bytes: []u8 = ctx.base[b * ctx.size ..][0..ctx.size];

            for (a_bytes, b_bytes) |*ab, *bb| {
                const tmp = ab.*;
                ab.* = bb.*;
                bb.* = tmp;
            }
        }
    };

    std.mem.sortUnstableContext(0, n, Context{
        .base = @ptrCast(base),
        .size = size,
        .compare = compare,
        .arg = arg,
    });
}

pub fn qsort(base: ?*anyopaque, n: usize, size: usize, compare: ?*const fn (a: *const anyopaque, b: *const anyopaque) callconv(.c) c_int) callconv(.c) void {
    if (base == null) js.console.err("{s}: base parameter is null", .{@src().fn_name});
    if (compare == null) js.console.err("{s}: compare parameter is null", .{@src().fn_name});
    return qsort_r(base.?, n, size, (struct {
        fn wrap(a: *const anyopaque, b: *const anyopaque, arg: ?*anyopaque) callconv(.c) c_int {
            return @as(*const fn (a: *const anyopaque, b: *const anyopaque) callconv(.c) c_int, @ptrCast(@alignCast(arg.?)))(a, b);
        }
    }).wrap, @constCast(compare.?));
}

pub fn sinf(x: f32) callconv(.c) f32 {
    return std.math.sin(x);
}

pub fn snprintf(str: ?[*:0]c_char, size: usize, c_fmt: ?[*:0]const c_char, ...) callconv(.c) c_int {
    var va_list = @cVaStart();
    defer @cVaEnd(&va_list);
    const result = vsnprintf(str, size, c_fmt, va_list);
    return result;
}

pub fn sprintf(str: ?[*:0]c_char, c_fmt: ?[*:0]const c_char, ...) callconv(.c) c_int {
    var va_list = @cVaStart();
    defer @cVaEnd(&va_list);
    const result = vsprintf(str, c_fmt, va_list);
    return result;
}

pub fn sqrt(x: f64) callconv(.c) f64 {
    return std.math.sqrt(x);
}

pub fn sqrtf(x: f32) callconv(.c) f32 {
    return std.math.sqrt(x);
}

pub fn sscanf(str: ?[*:0]c_char, fmt: ?[*:0]const c_char, ...) callconv(.c) c_int {
    _ = .{ str, fmt };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn stpcpy(noalias dst: ?[*]c_char, noalias src: ?[*:0]const c_char) callconv(.c) ?[*]c_char {
    if (dst == null) std.debug.panic("{s}: dst parameter is null", .{@src().fn_name});
    if (src == null) std.debug.panic("{s}: src parameter is null", .{@src().fn_name});
    const src_len = std.mem.len(@as([*:0]const u8, @ptrCast(src.?)));
    @memcpy(dst.?[0 .. src_len + 1], src.?[0 .. src_len + 1]);
    return dst.? + src_len;
}

pub fn stpncpy(noalias dst: ?[*]c_char, noalias src: ?[*:0]const c_char, max: usize) callconv(.c) ?[*]c_char {
    if (dst == null) std.debug.panic("{s}: dst parameter is null", .{@src().fn_name});
    if (src == null) std.debug.panic("{s}: src parameter is null", .{@src().fn_name});
    const src_len = strnlen(src.?, max);
    const copying_len = @min(max, src_len);
    @memcpy(dst.?[0..copying_len], src.?[0..copying_len]);
    @memset(dst.?[copying_len..][0 .. max - copying_len], 0x00);
    return dst.? + copying_len;
}

pub fn strchr(str: ?[*:0]const c_char, value: c_int) callconv(.c) ?[*:0]c_char {
    if (str == null) return null;
    const len = std.mem.len(@as([*:0]const u8, @ptrCast(str.?)));

    if (value == 0) return @constCast(str.? + len);
    const idx = std.mem.findScalar(u8, @as([*:0]const u8, @ptrCast(str.?))[0..len], @truncate(@as(c_uint, @bitCast(value)))) orelse return null;
    return @constCast(str.? + idx);
}

pub fn strcmp(a: ?[*:0]const c_char, b: ?[*:0]const c_char) callconv(.c) c_int {
    return strncmp(a, b, std.math.maxInt(usize));
}

pub fn strcpy(noalias dst: ?[*]c_char, noalias src: ?[*:0]const c_char) callconv(.c) ?[*]c_char {
    _ = stpcpy(dst, src);
    return dst;
}

pub fn strlen(s: ?[*:0]const c_char) callconv(.c) usize {
    if (s == null) return 0;
    return std.mem.len(s.?);
}

pub fn strncmp(a: ?[*:0]const c_char, b: ?[*:0]const c_char, max: usize) callconv(.c) c_int {
    if (a == null) std.debug.panic("{s}: a parameter is null", .{@src().fn_name});
    if (b == null) std.debug.panic("{s}: b parameter is null", .{@src().fn_name});
    return switch (std.mem.boundedOrderZ(u8, @ptrCast(a), @ptrCast(b), max)) {
        .eq => 0,
        .gt => 1,
        .lt => -1,
    };
}

pub fn strncpy(noalias dst: ?[*]c_char, noalias src: ?[*:0]const c_char, max: usize) callconv(.c) ?[*]c_char {
    _ = stpncpy(dst, src, max);
    return dst;
}

pub fn strnlen(str: ?[*:0]const c_char, max: usize) callconv(.c) usize {
    if (str == null) return 0;
    return std.mem.findScalar(u8, @ptrCast(str.?[0..max]), 0) orelse max;
}

pub fn strstr(haystack: ?[*:0]const c_char, needle: ?[*:0]const c_char) callconv(.c) ?[*:0]c_char {
    if (haystack == null) std.debug.panic("{s}: haystack parameter is null", .{@src().fn_name});
    if (needle == null) std.debug.panic("{s}: needle parameter is null", .{@src().fn_name});
    const hay = std.mem.span(@as([*:0]const u8, @ptrCast(haystack.?)));
    const ndl = std.mem.span(@as([*:0]const u8, @ptrCast(needle.?)));
    const idx = std.mem.find(u8, hay, ndl) orelse return null;
    return @constCast(haystack.? + idx);
}

pub fn time(tloc: ?*c.time_t) callconv(.c) c.time_t {
    if (tloc != null) std.debug.panic("{s} not implemented when tloc parameter isn't null", .{@src().fn_name});
    return @trunc(js.time.now() / std.time.ms_per_s);
}

pub fn toupper(ch: c_int) callconv(.c) c_int {
    return std.ascii.toUpper(@truncate(@as(c_uint, @bitCast(ch))));
}

pub fn usleep(usec: c.useconds_t) callconv(.c) c_int {
    _ = usec;
    @panic(@src().fn_name ++ " not implemented");
}

pub fn vsnprintf(str_opt: ?[*:0]c_char, size: usize, c_fmt_opt: ?[*:0]const c_char, ap: std.lang.VaList) callconv(.c) c_int {
    if (str_opt) |str| {
        if (c_fmt_opt) |c_fmt| {
            var va_list = ap;
            var writer: std.Io.Writer = .fixed(@ptrCast(@alignCast(str[0..size])));
            const result = format(&writer, size, c_fmt, &va_list);
            return result;
        } else std.debug.panic("{s}: c_fmt parameter is null", .{@src().fn_name});
    } else return 0;
}

pub fn vsprintf(str_opt: ?[*:0]c_char, c_fmt_opt: ?[*:0]const c_char, ap: std.lang.VaList) callconv(.c) c_int {
    if (str_opt) |str| {
        if (c_fmt_opt) |c_fmt| {
            var va_list = ap;
            var writer: std.Io.Writer = .fixed(@ptrCast(@alignCast(str[0..std.math.maxInt(usize)])));
            const result = format(&writer, null, c_fmt, &va_list);
            return result;
        } else std.debug.panic("{s}: c_fmt parameter is null", .{@src().fn_name});
    } else return 0;
}

pub fn waitpid(pid: c.pid_t, status: ?*c_int, options: c_int) callconv(.c) c.pid_t {
    _ = .{ pid, status, options };
    @panic(@src().fn_name ++ " not implemented");
}
