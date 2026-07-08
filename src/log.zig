const std = @import("std");
const build = @import("build");
const js = struct {
    const imports = @import("imports");
    const types = imports;
};

pub var flusher: js.types.FlushMode = .normal;

pub const pages = struct {
    var writer: std.Io.Writer = .{
        .vtable = &.{
            .drain = pages.drain,
            .flush = pages.flush,
            .rebase = std.Io.Writer.failingRebase,
        },
        .buffer = &.{},
        .end = 0,
    };

    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        _ = .{ w, splat };
        var size: usize = 0;
        for (data) |bytes| {
            js.imports.consoleWrite(bytes.ptr, bytes.len);
            size += bytes.len;
        }
        return size;
    }

    fn flush(w: *std.Io.Writer) std.Io.Writer.Error!void {
        _ = w;
        js.imports.consoleFlush(flusher);
    }
};

const native = struct {
    var buffer: [1024]u8 = undefined;
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    var writer = std.Io.File.stderr().writer(io, &buffer);
};

pub fn writer() *std.Io.Writer {
    return if (build.pages_build) &pages.writer else &native.writer.interface;
}

const ansi = struct {
    const esc = "\x1B";
    const bold = esc ++ "[1m";
    const reset = esc ++ "[m";

    fn fg(comptime r: u8, comptime g: u8, comptime b: u8) []const u8 {
        return std.fmt.comptimePrint(esc ++ "[38;2;{d};{d};{d}m", .{ r, g, b });
    }
};

pub const header = struct {
    fn write(comptime level: []const u8, comptime r: u8, comptime g: u8, comptime b: u8) void {
        writer().print("{s}[{s}{s}{s}{s}]{s} ", .{ ansi.bold, ansi.fg(r, g, b), level, ansi.reset, ansi.bold, ansi.reset }) catch {};
    }

    pub fn err() void {
        return header.write("error", 255, 173, 173);
    }

    pub fn orange() void {
        return header.write("orange", 255, 214, 165);
    }

    pub fn warn() void {
        return header.write("warn", 253, 255, 182);
    }

    pub fn info() void {
        return header.write("info", 202, 255, 191);
    }

    pub fn note() void {
        return header.write("note", 155, 246, 255);
    }

    pub fn debug() void {
        return header.write("debug", 194, 160, 239);
    }

    pub fn trace() void {
        return header.write("trace", 247, 174, 248);
    }
};

fn log(comptime fmt: []const u8, args: anytype) void {
    writer().print(fmt, args) catch {}; // std.Io.Writer.Error won't happen when writing to the JS console or with stderr
    writer().writeByte('\n') catch {};
    writer().flush() catch {};
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    header.err();
    log(fmt, args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    header.warn();
    log(fmt, args);
}

pub fn info(comptime fmt: []const u8, args: anytype) void {
    header.info();
    log(fmt, args);
}

pub fn note(comptime fmt: []const u8, args: anytype) void {
    header.note();
    log(fmt, args);
}

pub fn debug(comptime fmt: []const u8, args: anytype) void {
    header.debug();
    log(fmt, args);
}

pub fn trace(comptime fmt: []const u8, args: anytype) void {
    header.trace();
    log(fmt, args);
}
