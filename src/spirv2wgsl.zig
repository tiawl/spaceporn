const std = @import("std");
const c = @import("c");

fn optimizeSPIRV(input: []const u32, gpa: std.mem.Allocator) ![]u32 {
    const optimizer = c.spvOptimizerCreate(c.SPV_ENV_UNIVERSAL_1_3);
    if (optimizer == null) return error.SpvOptimizerCreateFailed;
    defer c.spvOptimizerDestroy(optimizer);

    var flags = [_][*c]const u8{
        "-O",
        "--eliminate-dead-code-aggressive",
        "--eliminate-dead-branches",
        "--eliminate-dead-const",
        "--simplify-instructions",
        "--cfg-cleanup",
        "--strip-debug",
    };
    if (!c.spvOptimizerRegisterPassesFromFlags(optimizer, @ptrCast(&flags), flags.len)) return error.SpvRegisterPassesFailed;

    const opts = c.spvOptimizerOptionsCreate();
    if (opts == null) return error.SpvOptionsCreateFailed;
    defer c.spvOptimizerOptionsDestroy(opts);
    c.spvOptimizerOptionsSetRunValidator(opts, false);

    var out_bin: c.spv_binary = null;
    const rc = c.spvOptimizerRun(optimizer, input.ptr, input.len, &out_bin, opts);
    if (rc != c.SPV_SUCCESS or out_bin == null)
        return error.SpvOptimizerRunFailed;
    defer c.spvBinaryDestroy(out_bin);

    const out = try gpa.alloc(u32, out_bin.*.wordCount);
    @memcpy(out, out_bin.*.code[0..out_bin.*.wordCount]);
    return out;
}

fn lastTintError(gpa: std.mem.Allocator) !?[]u8 {
    var ptr: [*c]u8 = null;
    var len: usize = 0;
    const rc = c.tintLastError(&ptr, &len);
    if (rc != 0) return error.TintLastErrorFailed;
    if (ptr == null) return null;
    defer std.c.free(ptr);
    return try gpa.dupe(u8, ptr[0..len]);
}

fn SPIRVToWGSL(spirv: []const u32, gpa: std.mem.Allocator) ![]u8 {
    c.tintInitialize();
    defer c.tintShutdown();

    var ir: ?*anyopaque = null;
    defer if (ir != null) c.tintFreeIR(&ir);
    if (c.tintSPIRVReaderReadIR(spirv.ptr, spirv.len, &ir) != 0) {
        if (try lastTintError(gpa)) |msg| {
            defer gpa.free(msg);
            std.log.err("Tint SPIRV -> IR failed:\n{s}", .{msg});
        }
        return error.TintSPIRVReaderReadIR;
    }

    var out_ptr: [*c]u8 = null;
    var out_len: usize = 0;
    defer if (out_ptr != null) std.c.free(out_ptr);
    if (c.tintWGSLWriterFromIR(&ir, &out_ptr, &out_len) != 0) {
        if (try lastTintError(gpa)) |msg| {
            defer gpa.free(msg);
            std.log.err("Tint IR -> WGSL failed:\n{s}", .{msg});
        }
        return error.TintWGSLWriterFromIR;
    }

    return try gpa.dupe(u8, out_ptr[0..out_len]);
}

const SPIRVDecoration = enum(u32) {
    ArrayStride = 6,
};

const SPIRVInstruction = enum(u32) {
    OpDecorate = 71,
};

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    if (!args.skip()) return error.MissingExeArgument;
    const input = if (args.next()) |arg| arg else return error.MissingInputArgument;
    const output = if (args.next()) |arg| arg else return error.MissingOuputArgument;
    if (args.skip()) return error.UnknownArgument;

    const data = try std.Io.Dir.cwd().readFileAlloc(init.io, input, init.gpa, .unlimited);
    defer init.gpa.free(data);

    if (data.len % 4 != 0) return error.InvalidSPIRV;
    const words: []align(@alignOf(u32)) const u32 = @alignCast(std.mem.bytesAsSlice(u32, data));
    if (words[0] != 0x07230203) return error.InvalidMagic;

    var out = try std.ArrayList(u32).initCapacity(init.gpa, words.len);
    defer out.deinit(init.gpa);

    // Header (5 words)
    try out.appendSlice(init.gpa, words[0..5]);

    var i: usize = 5;
    var removed: usize = 0;
    while (i < words.len) {
        const wc = words[i] >> 16;
        const op = words[i] & 0xFFFF;
        if (wc == 0) return error.InvalidInstruction;

        if (op == @backingInt(SPIRVInstruction.OpDecorate) and wc >= 3 and words[i + 2] == @backingInt(SPIRVDecoration.ArrayStride)) {
            removed += 1;
        } else {
            try out.appendSlice(init.gpa, words[i .. i + wc]);
        }
        i += @max(wc, 1);
    }

    const optimized = try optimizeSPIRV(out.items, init.gpa);
    defer init.gpa.free(optimized);

    const wgsl = try SPIRVToWGSL(optimized, init.gpa);
    defer init.gpa.free(wgsl);
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = output, .data = wgsl });
}
