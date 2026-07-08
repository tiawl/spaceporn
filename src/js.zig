const js = @This();
const std = @import("std");
const c = @import("c");
const build = @import("build");
const shader = @import("shader");
const imports = @import("imports");

pub const StringPtr = imports.StringPtr;
pub const String = imports.String;
pub const Boolean = imports.Boolean;
pub const Int32 = imports.Int32;
pub const Uint32 = imports.Uint32;
pub const BigUint64 = imports.BigUint64;
pub const Float32 = imports.Float32;
pub const Float64 = imports.Float64;
pub const OpaquePtr = imports.OpaquePtr;
pub const Handle = imports.Handle;
pub const Flags = imports.Flags;
pub const Size = imports.Size;
pub const Offset = imports.Offset;

const FlushMode = imports.FlushMode;

const null_handle = imports.null_handle;

var gpa = std.heap.wasm_allocator;

// Module written to provide type safety when interracting with JS functions

fn traceInner(comptime Func: type, func: Func, comptime funcname: []const u8, args: std.meta.ArgsTuple(Func)) @typeInfo(Func).@"fn".return_type.? {
    if (build.trace) {
        js.console.log.header.trace();
        js.console.log.writer().writeAll(funcname) catch {};
        js.console.log.writer().writeByte('(') catch {};
        inline for (args, 0..) |arg, i| {
            switch (@typeInfo(@TypeOf(arg))) {
                .pointer => js.console.log.writer().print("{*}", .{arg}) catch {},
                else => js.console.log.writer().print("{}", .{arg}) catch {},
            }
            if (i < args.len - 1) js.console.log.writer().writeAll(", ") catch {};
        }
        js.console.log.writer().writeByte(')') catch {};
        js.console.log.writer().flush() catch {};
    }
    return @call(.auto, func, args);
}

fn importedFnName(comptime src: std.lang.SourceLocation) []const u8 {
    return "js" ++ .{std.ascii.toUpper(src.fn_name[0])} ++ src.fn_name[1..];
}

fn importedFnType(comptime src: std.lang.SourceLocation) type {
    return @TypeOf(@field(imports, importedFnName(src)));
}

fn trace(comptime src: std.lang.SourceLocation, args: std.meta.ArgsTuple(importedFnType(src))) @typeInfo(importedFnType(src)).@"fn".return_type.? {
    const funcname = comptime importedFnName(src);
    const func = @field(imports, funcname);
    const Func = @TypeOf(func);
    return traceInner(Func, func, funcname, args);
}

fn gpuGetAdapter() js.Handle {
    return trace(@src(), .{});
}

fn gpuGetDevice() js.Handle {
    return trace(@src(), .{});
}

fn gpuContextConfigure(context_handle: js.Handle, device_handle: js.Handle, texture_format_ptr: js.StringPtr, texture_format_len: js.Uint32) void {
    trace(@src(), .{ context_handle, device_handle, texture_format_ptr, texture_format_len });
}

fn gpuContextGetCurrentTexture(context_handle: js.Handle) js.Handle {
    return trace(@src(), .{context_handle});
}

fn gpuRelease(ressource_handle: js.Handle) void {
    trace(@src(), .{ressource_handle});
}

fn gpuInstanceRequestAdapter(instance_handle: js.Handle, cb_handle: js.gpu.Callback) void {
    trace(@src(), .{ instance_handle, cb_handle });
}

fn gpuInstanceGetPreferredSurfaceFormat(instance_handle: js.Handle) js.String {
    return trace(@src(), .{instance_handle});
}

fn gpuAdapterRequestDevice(adapter_handle: js.Handle, cb_handle: js.gpu.Callback) void {
    trace(@src(), .{ adapter_handle, cb_handle });
}

fn gpuDeviceCreateShaderModule(device_handle: js.Handle, source_ptr: js.StringPtr, source_len: js.Uint32) js.Handle {
    return trace(@src(), .{ device_handle, source_ptr, source_len });
}

fn gpuDeviceCreatePipelineLayout(device_handle: js.Handle, bind_group_layouts_ptr: js.OpaquePtr, bind_group_layouts_len: js.Uint32) js.Handle {
    return trace(@src(), .{ device_handle, bind_group_layouts_ptr, bind_group_layouts_len });
}

fn gpuDeviceCreateRenderPipeline(device_handle: js.Handle, pipeline_layout_handle: js.Handle, vertex_state_ptr: js.OpaquePtr, fragment_state_ptr: js.OpaquePtr, primitive_state_ptr: js.OpaquePtr) js.Handle {
    return trace(@src(), .{ device_handle, pipeline_layout_handle, vertex_state_ptr, fragment_state_ptr, primitive_state_ptr });
}

fn gpuDeviceCreateCommandEncoder(device_handle: js.Handle) js.Handle {
    return trace(@src(), .{device_handle});
}

fn gpuDeviceCreateTexture(device_handle: js.Handle, descriptor_ptr: js.OpaquePtr) js.Handle {
    return trace(@src(), .{ device_handle, descriptor_ptr });
}

fn gpuDeviceCreateBuffer(device_handle: js.Handle, size: js.Size, usage: js.Flags) js.Handle {
    return trace(@src(), .{ device_handle, size, usage });
}

fn gpuDestroyBuffer(buffer_handle: js.Handle) void {
    trace(@src(), .{buffer_handle});
}

fn gpuDeviceCreateBindGroup(device_handle: js.Handle, bind_group_layout: js.Handle, entries_ptr: js.OpaquePtr, entries_len: js.Uint32) js.Handle {
    return trace(@src(), .{ device_handle, bind_group_layout, entries_ptr, entries_len });
}

fn gpuDeviceCreateBindGroupLayout(device_handle: js.Handle, entries_ptr: js.OpaquePtr, entries_len: js.Uint32) js.Handle {
    return trace(@src(), .{ device_handle, entries_ptr, entries_len });
}

fn gpuDeviceCreateSampler(device_handle: js.Handle, descriptor_ptr: js.OpaquePtr) js.Handle {
    return trace(@src(), .{ device_handle, descriptor_ptr });
}

fn gpuDeviceGetQueue(device_handle: js.Handle) js.Handle {
    return trace(@src(), .{device_handle});
}

fn gpuDevicePushErrorScope(device_handle: js.Handle, filter_ptr: js.StringPtr, filter_len: js.Uint32) void {
    return trace(@src(), .{ device_handle, filter_ptr, filter_len });
}

fn gpuDevicePopErrorScope(device_handle: js.Handle, cb_handle: js.gpu.Callback) void {
    return trace(@src(), .{ device_handle, cb_handle });
}

fn gpuDeviceThrowErrorScope(device_handle: js.Handle) void {
    return trace(@src(), .{device_handle});
}

fn gpuTextureGetWidth(texture_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{texture_handle});
}

fn gpuTextureGetHeight(texture_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{texture_handle});
}

fn gpuTextureGetDepthOrArrayLayers(texture_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{texture_handle});
}

fn gpuTextureGetMipLevelCount(texture_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{texture_handle});
}

fn gpuTextureGetFormat(texture_handle: js.Handle) js.String {
    return trace(@src(), .{texture_handle});
}

fn gpuTextureGetDimension(texture_handle: js.Handle) js.String {
    return trace(@src(), .{texture_handle});
}

fn gpuTextureCreateView(texture_handle: js.Handle, descriptor_ptr: js.OpaquePtr) js.Handle {
    return trace(@src(), .{ texture_handle, descriptor_ptr });
}

fn gpuCommandEncoderBeginRenderPass(command_encoder_handle: js.Handle, texture_view_handle: js.Handle, descriptor_ptr: js.OpaquePtr) js.Handle {
    return trace(@src(), .{ command_encoder_handle, texture_view_handle, descriptor_ptr });
}

fn gpuCommandEncoderFinish(command_encoder_handle: js.Handle) js.Handle {
    return trace(@src(), .{command_encoder_handle});
}

fn gpuRenderPassEncoderSetPipeline(render_pass_encoder_handle: js.Handle, render_pipeline_handle: js.Handle) void {
    trace(@src(), .{ render_pass_encoder_handle, render_pipeline_handle });
}

fn gpuRenderPassEncoderSetBindGroup(render_pass_encoder_handle: js.Handle, index: js.Uint32, bind_group_handle: js.Handle, dynamic_offsets_ptr: js.OpaquePtr, dynamic_offsets_len: js.Uint32) void {
    trace(@src(), .{ render_pass_encoder_handle, index, bind_group_handle, dynamic_offsets_ptr, dynamic_offsets_len });
}

fn gpuRenderPassEncoderSetVertexBuffer(render_pass_encoder_handle: js.Handle, slot: js.Uint32, vertex_buffer_handle: js.Handle, offset: js.Offset, size: js.Size) void {
    trace(@src(), .{ render_pass_encoder_handle, slot, vertex_buffer_handle, offset, size });
}

fn gpuRenderPassEncoderSetIndexBuffer(render_pass_encoder_handle: js.Handle, index_buffer_handle: js.Handle, index_format_ptr: js.StringPtr, index_format_len: js.Uint32, offset: js.Offset, size: js.Size) void {
    trace(@src(), .{ render_pass_encoder_handle, index_buffer_handle, index_format_ptr, index_format_len, offset, size });
}

fn gpuRenderPassEncoderSetScissorRect(render_pass_encoder_handle: js.Handle, x: js.Uint32, y: js.Uint32, width: js.Uint32, height: js.Uint32) void {
    trace(@src(), .{ render_pass_encoder_handle, x, y, width, height });
}

fn gpuRenderPassEncoderSetViewport(render_pass_encoder_handle: js.Handle, x: js.Float32, y: js.Float32, width: js.Float32, height: js.Float32, min_depth: js.Float32, max_depth: js.Float32) void {
    trace(@src(), .{ render_pass_encoder_handle, x, y, width, height, min_depth, max_depth });
}

fn gpuRenderPassEncoderSetBlendConstant(render_pass_encoder_handle: js.Handle, color_ptr: js.OpaquePtr) void {
    trace(@src(), .{ render_pass_encoder_handle, color_ptr });
}

fn gpuRenderPassEncoderDrawIndexed(render_pass_encoder_handle: js.Handle, index_count: js.Uint32, instance_count: js.Uint32, first_index: js.Uint32, base_vertex: js.Int32, first_instance: js.Uint32) void {
    trace(@src(), .{ render_pass_encoder_handle, index_count, instance_count, first_index, base_vertex, first_instance });
}

fn gpuRenderPassEncoderEnd(render_pass_encoder_handle: js.Handle) void {
    trace(@src(), .{render_pass_encoder_handle});
}

fn gpuQueueSubmit(queue_handle: js.Handle, command_buffers_ptr: js.OpaquePtr, command_buffers_len: js.Uint32) void {
    trace(@src(), .{ queue_handle, command_buffers_ptr, command_buffers_len });
}

fn gpuQueueWriteBuffer(queue_handle: js.Handle, buffer_handle: js.Handle, buffer_offset: js.Offset, data_ptr: js.StringPtr, data_len: js.Uint32, data_offset: js.Offset, size: js.Size) void {
    trace(@src(), .{ queue_handle, buffer_handle, buffer_offset, data_ptr, data_len, data_offset, size });
}

fn gpuQueueWriteTexture(queue_handle: js.Handle, info_ptr: js.OpaquePtr, data_ptr: js.StringPtr, data_len: js.Uint32, data_layout_ptr: js.OpaquePtr, size_extent_ptr: js.OpaquePtr) void {
    trace(@src(), .{ queue_handle, info_ptr, data_ptr, data_len, data_layout_ptr, size_extent_ptr });
}

fn platformGetWindow() js.Handle {
    return trace(@src(), .{});
}

fn platformWindowGetCanvas(window_handle: js.Handle) js.Handle {
    return trace(@src(), .{window_handle});
}

fn platformWindowGetGpuInstance(window_handle: js.Handle) js.Handle {
    return trace(@src(), .{window_handle});
}

fn platformWindowListenEvent(window_handle: js.Handle, event_ptr: js.StringPtr, event_len: js.Uint32) void {
    trace(@src(), .{ window_handle, event_ptr, event_len });
}

fn platformWindowGetDevicePixelRatio(window_handle: js.Handle) js.Float32 {
    return trace(@src(), .{window_handle});
}

fn platformCanvasGetBoundingClientRectWidth(canvas_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{canvas_handle});
}

fn platformCanvasGetBoundingClientRectHeight(canvas_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{canvas_handle});
}

fn platformCanvasGetBoundingClientRectLeft(canvas_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{canvas_handle});
}

fn platformCanvasGetBoundingClientRectTop(canvas_handle: js.Handle) js.Uint32 {
    return trace(@src(), .{canvas_handle});
}

fn platformCanvasGetGpuContext(canvas_handle: js.Handle) js.Handle {
    return trace(@src(), .{canvas_handle});
}

fn platformCanvasResize(canvas_handle: js.Handle, width: js.Uint32, height: js.Uint32, dpr: js.Float32) void {
    trace(@src(), .{ canvas_handle, width, height, dpr });
}

fn platformCanvasListenEvent(canvas_handle: js.Handle, event_ptr: js.StringPtr, event_len: js.Uint32) void {
    trace(@src(), .{ canvas_handle, event_ptr, event_len });
}

fn platformGetClipboard() js.Handle {
    return trace(@src(), .{});
}

fn platformClipboardWriteText(clipboard_handle: js.Handle, text_ptr: js.StringPtr, text_len: js.Uint32) void {
    trace(@src(), .{ clipboard_handle, text_ptr, text_len });
}

fn platformKeyboardEventGetCodepoint() js.Uint32 {
    return trace(@src(), .{});
}

fn platformKeyboardEventGetCode() js.String {
    return trace(@src(), .{});
}

fn platformKeyboardEventGetModifierBits() js.Uint32 {
    return trace(@src(), .{});
}

fn platformMouseButtonEventGetButton() js.Uint32 {
    return trace(@src(), .{});
}

fn platformMouseMoveEventGetClientX() js.Uint32 {
    return trace(@src(), .{});
}

fn platformMouseMoveEventGetClientY() js.Uint32 {
    return trace(@src(), .{});
}

fn platformWheelEventGetDeltaMode() js.platform.DeltaMode {
    return trace(@src(), .{});
}

fn platformWheelEventGetDeltaX() js.Float32 {
    return trace(@src(), .{});
}

fn platformWheelEventGetDeltaY() js.Float32 {
    return trace(@src(), .{});
}

pub const requestAnimationFrame = js.imports.requestAnimationFrame;

pub const time = struct {
    pub const now = js.imports.timeNow;
};

pub const console = struct {
    const term_writer: std.Io.Terminal = .{
        .writer = js.console.log.writer(),
        .mode = .no_color,
    };

    pub const log = @import("log");

    pub fn assert(ok: bool, src: std.lang.SourceLocation) void {
        if (!ok) {
            js.console.log.flusher = .dev_null;
            js.console.log.writer().flush() catch {};
            const expr: []const u8 = if (src.column == 0) src.module else "";
            js.console.log.writer().print("{s}:{d}: into {s}(): \"{s}\"", .{ src.file, src.line, src.fn_name, expr }) catch {}; // std.Io.Writer.Error won't happen when writing to the JS console
            js.console.log.flusher = .zig_assertion_failure;
            js.console.log.writer().flush() catch {};
        }
    }

    pub fn throwErr(flusher: FlushMode) noreturn {
        js.console.assert(flusher == .zig_err or flusher == .js_err, @src());
        js.console.log.flusher = flusher;
        js.console.log.writer().flush() catch {};
        unreachable;
    }

    pub fn err(comptime fmt: []const u8, args: anytype) noreturn {
        js.console.log.flusher = .dev_null;
        js.console.log.writer().flush() catch {};
        if (@errorReturnTrace()) |err_trace| {
            if (err_trace.index > 0) {
                trace: {
                    js.console.log.header.err();
                    std.debug.writeErrorReturnTrace(err_trace, term_writer) catch break :trace;
                }
                js.console.log.writer().flush() catch {};
            }
        }
        js.console.log.err(fmt, args);
        js.console.throwErr(.zig_err);
    }

    pub fn panic(msg: []const u8, first_trace_addr: ?usize) noreturn {
        @branchHint(.cold);
        js.console.log.flusher = .dev_null;
        js.console.log.writer().flush() catch {};
        trace: {
            js.console.log.writer().writeAll("panic: ") catch break :trace; // std.Io.Writer.Error won't happen when writing to the JS console
            js.console.log.writer().writeAll(msg) catch break :trace;
            js.console.log.writer().writeByte('\n') catch break :trace;
            if (@errorReturnTrace()) |err_trace| if (err_trace.index > 0) {
                js.console.log.writer().writeAll("error return context:\n") catch break :trace;
                std.debug.writeErrorReturnTrace(err_trace, term_writer) catch break :trace;
                js.console.log.writer().writeAll("\nstack trace:\n") catch break :trace;
            };
            std.debug.writeCurrentStackTrace(.{
                .first_address = first_trace_addr orelse @returnAddress(),
                .allow_unsafe_unwind = true, // we're crashing anyway, give it our all!
            }, term_writer) catch break :trace;
        }
        js.console.log.flusher = .zig_panic;
        js.console.log.writer().flush() catch {};
        unreachable;
    }
};

pub const wgsl = struct {
    fn sizeOfPrimitive(comptime T: type) js.Uint32 {
        return switch (T) {
            i32 => 4,
            u32 => 4,
            f32 => 4,
            f16 => 2,
            shader.Vec2 => 2 * js.wgsl.sizeOfPrimitive(f32),
            shader.Vec3 => 3 * js.wgsl.sizeOfPrimitive(f32),
            shader.Vec4 => 4 * js.wgsl.sizeOfPrimitive(f32),
            else => std.debug.panic("{s}: unknown WGSL Primitive type: {s}", .{ @src().fn_name, @typeName(T) }),
        };
    }

    fn alignOfPrimitive(comptime T: type) js.Uint32 {
        return std.math.ceilPowerOfTwo(js.Uint32, js.wgsl.sizeOfPrimitive(T)) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    }

    fn alignUp(offset: js.Uint32, alignment: js.Uint32) js.Uint32 {
        return (offset + alignment - 1) & ~(alignment - 1);
    }

    fn alignOf(comptime T: type) js.Uint32 {
        return switch (@typeInfo(T)) {
            .@"struct" => 16, // conservative; structs in uniform are 16-byte aligned
            .array => |arr| alignOf(arr.child),
            else => alignOfPrimitive(T),
        };
    }

    pub fn sizeOf(comptime T: type) js.Uint32 {
        return switch (@typeInfo(T)) {
            .@"struct" => blk: {
                var offset: js.Uint32 = 0;
                inline for (@typeInfo(T).@"struct".field_types) |FieldType| {
                    const field_align = alignOf(FieldType);
                    offset = alignUp(offset, field_align);
                    offset += sizeOf(FieldType);
                }
                // Uniform buffers are required to be a multiple of 16 bytes
                break :blk alignUp(offset, 16);
            },
            .array => |arr| sizeOf(arr.child) * arr.len,
            else => sizeOfPrimitive(T),
        };
    }
};

pub const gpu = struct {
    pub const Callback = imports.GpuCallback;

    pub fn triggerCallback(self: js.gpu.Callback) void {
        switch (self) {
            .request_adapter => {
                js.gpu.Adapter.init();
                if (js.gpu.Instance.requestAdapterCallback) |cb| cb();
            },
            .request_device => {
                js.gpu.Device.init();
                if (js.gpu.Adapter.requestDeviceCallback) |cb| cb();
            },
            .pop_error_scope => js.gpu.Device.throwErrorScope(),
            .null_handle => |captured| std.debug.panic("{s}: called with {s}", .{ @src().fn_name, @tagName(captured) }),
        }
    }

    pub const Context = struct {
        handle: js.Handle = null_handle,

        var instance: @This() = .{};

        fn init(handle: js.Handle) void {
            js.console.assert(handle != null_handle, @src());
            instance = .{ .handle = handle };
        }

        pub fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn configure(texture_format: TextureFormat) void {
            js.console.assert(isInit(), @src());
            js.console.assert(js.gpu.Device.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuContextConfigure(instance.handle, js.gpu.Device.instance.handle, texture_format.tagName().ptr, texture_format.tagName().len);
        }

        pub fn getCurrentTexture() Texture {
            js.console.assert(isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            const texture_handle = js.gpuContextGetCurrentTexture(instance.handle);
            const texture_width = js.gpuTextureGetWidth(texture_handle);
            const texture_height = js.gpuTextureGetHeight(texture_handle);
            const texture_depth_or_array_layers = js.gpuTextureGetDepthOrArrayLayers(texture_handle);
            const texture_mip_level_count = js.gpuTextureGetMipLevelCount(texture_handle);
            const texture_format_str: [:0]const u8 = std.mem.span(js.gpuTextureGetFormat(texture_handle));
            defer gpa.free(texture_format_str); // Allocated into jsGpuTextureGetFormat
            const texture_format = std.meta.stringToEnum(TextureFormat, texture_format_str) orelse std.debug.panic("Unknown TextureFormat", .{});
            const dimension_str = std.mem.span(js.gpuTextureGetDimension(texture_handle));
            defer gpa.free(dimension_str); // Allocated into jsGpuTextureGetDimension
            const texture_dimension = std.meta.stringToEnum(TextureDimension, dimension_str) orelse std.debug.panic("Unknown TextureDimension", .{});
            return Texture.init(texture_handle, texture_width, texture_height, texture_depth_or_array_layers, texture_format, texture_dimension, texture_mip_level_count);
        }
    };

    pub const Instance = struct {
        handle: js.Handle = null_handle,

        var instance: @This() = .{};
        var requestAdapterCallback: ?*const fn () void = null;

        fn init(handle: js.Handle) void {
            js.console.assert(handle != null_handle, @src());
            instance = .{ .handle = handle };
        }

        pub fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn requestAdapter(callback: ?*const fn () void) void {
            js.console.assert(isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            requestAdapterCallback = callback;
            js.gpuInstanceRequestAdapter(instance.handle, .request_adapter);
        }

        pub fn getPreferredSurfaceFormat() TextureFormat {
            js.console.assert(isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            const str: [:0]const u8 = std.mem.span(js.gpuInstanceGetPreferredSurfaceFormat(instance.handle));
            defer gpa.free(str); // Allocated into jsGpuInstanceGetPreferredSurfaceFormat
            return std.meta.stringToEnum(TextureFormat, str) orelse std.debug.panic("Unknown TextureFormat", .{});
        }
    };

    pub const Adapter = struct {
        handle: js.Handle = null_handle,
        info: AdapterInfo = .{},

        var instance: @This() = .{};
        var requestDeviceCallback: ?*const fn () void = null;

        pub fn init() void {
            const handle = js.gpuGetAdapter();
            js.console.assert(handle != null_handle, @src());
            instance = .{ .handle = handle };
        }

        pub fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn requestDevice(callback: ?*const fn () void) void {
            js.console.assert(isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            requestDeviceCallback = callback;
            js.gpuAdapterRequestDevice(instance.handle, .request_device);
        }
    };

    pub const AdapterType = enum(js.Uint32) {
        unknown = c.WGPUAdapterType_Unknown,
    };

    pub const BackendType = enum(js.Uint32) {
        WebGPU = c.WGPUBackendType_WebGPU,
    };

    pub const AdapterInfo = struct {
        description: []const u8 = "",
        vendor: []const u8 = "",
        vendor_id: u32 = 0,
        architecture: []const u8 = "",
        device: []const u8 = "",
        device_id: u32 = 0,
        adapter_type: AdapterType = .unknown,
        backend_type: BackendType = .WebGPU,
    };

    pub const Device = struct {
        handle: js.Handle = null_handle,

        var instance: @This() = .{};

        pub fn init() void {
            const handle = js.gpuGetDevice();
            js.console.assert(handle != null_handle, @src());
            instance = .{
                .handle = handle,
            };
            pushErrorScope(.validation);
            defer popErrorScope();
            Queue.init(js.gpuDeviceGetQueue(handle));
        }

        pub fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn createShaderModule(source: []const u8) ShaderModule {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            return ShaderModule.init(js.gpuDeviceCreateShaderModule(instance.handle, source.ptr, source.len));
        }

        pub fn createPipelineLayout(bind_group_layouts: []const BindGroupLayout) PipelineLayout {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            for (bind_group_layouts) |bind_group_layout| js.console.assert(bind_group_layout.isInit(), @src());
            return PipelineLayout.init(js.gpuDeviceCreatePipelineLayout(instance.handle, @intFromPtr(bind_group_layouts.ptr), bind_group_layouts.len));
        }

        pub fn createRenderPipeline(pipeline_layout: PipelineLayout, vertex_state: VertexState, fragment_state: FragmentState, primitive_state: PrimitiveState) RenderPipeline {
            js.console.assert(isInit(), @src());
            js.console.assert(pipeline_layout.isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            return RenderPipeline.init(js.gpuDeviceCreateRenderPipeline(instance.handle, pipeline_layout.handle, @intFromPtr(&vertex_state), @intFromPtr(&fragment_state), @intFromPtr(&primitive_state)));
        }

        pub fn createCommandEncoder() CommandEncoder {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            return CommandEncoder.init(js.gpuDeviceCreateCommandEncoder(instance.handle));
        }

        pub fn createTexture(descriptor: TextureDescriptor) Texture {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            const texture_format_ptr = descriptor.texture_format_ptr;
            const texture_format = std.meta.stringToEnum(TextureFormat, texture_format_ptr[0..descriptor.texture_format_len]) orelse std.debug.panic("Unknown TextureFormat", .{});
            const dimension_ptr = descriptor.dimension_ptr;
            const dimension = std.meta.stringToEnum(TextureDimension, dimension_ptr[0..descriptor.dimension_len]) orelse std.debug.panic("Unknown TextureDimension", .{});
            return Texture.init(
                js.gpuDeviceCreateTexture(instance.handle, @intFromPtr(&descriptor)),
                descriptor.width,
                descriptor.height,
                descriptor.depth_or_array_layers,
                texture_format,
                dimension,
                descriptor.mip_level_count,
            );
        }

        pub fn createBuffer(size: js.Size, usage: js.Flags) Buffer {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            return Buffer.init(js.gpuDeviceCreateBuffer(instance.handle, size, usage));
        }

        pub fn createBindGroup(bind_group_layout: BindGroupLayout, entries: []const BindGroupEntry) BindGroup {
            js.console.assert(isInit(), @src());
            js.console.assert(bind_group_layout.isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            for (entries) |entry| js.console.assert(entry.isInit(), @src());
            return BindGroup.init(js.gpuDeviceCreateBindGroup(instance.handle, bind_group_layout.handle, @intFromPtr(entries.ptr), entries.len));
        }

        pub fn createBindGroupLayout(entries: []const BindGroupLayoutEntry) BindGroupLayout {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            return BindGroupLayout.init(js.gpuDeviceCreateBindGroupLayout(instance.handle, @intFromPtr(entries.ptr), entries.len));
        }

        pub fn createSampler(descriptor: SamplerDescriptor) Sampler {
            js.console.assert(isInit(), @src());
            pushErrorScope(.validation);
            defer popErrorScope();
            return Sampler.init(js.gpuDeviceCreateSampler(instance.handle, @intFromPtr(&descriptor)));
        }

        fn pushErrorScope(comptime filter: ErrorFilter) void {
            js.console.assert(isInit(), @src());
            js.gpuDevicePushErrorScope(instance.handle, @tagName(filter).ptr, @tagName(filter).len);
        }

        fn popErrorScope() void {
            js.console.assert(isInit(), @src());
            js.gpuDevicePopErrorScope(instance.handle, .pop_error_scope);
        }

        fn throwErrorScope() void {
            js.console.assert(isInit(), @src());
            js.gpuDeviceThrowErrorScope(instance.handle);
        }
    };

    pub const ErrorFilter = enum(js.Uint32) {
        validation = c.WGPUErrorFilter_Validation,
    };

    pub const TextureDimension = enum(js.Uint32) {
        @"2d" = c.WGPUTextureDimension_2D,
    };

    pub const TextureDescriptor = extern struct {
        usage: js.Flags,
        width: js.Uint32,
        height: js.Uint32,
        depth_or_array_layers: js.Uint32,
        sample_count: js.Uint32,
        mip_level_count: js.Uint32,
        texture_format_ptr: js.StringPtr,
        texture_format_len: js.Uint32,
        dimension_ptr: js.StringPtr,
        dimension_len: js.Uint32,

        pub fn init(texture_format: TextureFormat, dimension: TextureDimension, width: js.Uint32, height: js.Uint32, depth_or_array_layers: js.Uint32, sample_count: js.Uint32, mip_level_count: js.Uint32, usage: js.Flags) @This() {
            return .{
                .usage = usage,
                .width = width,
                .height = height,
                .depth_or_array_layers = depth_or_array_layers,
                .sample_count = sample_count,
                .mip_level_count = mip_level_count,
                .texture_format_ptr = texture_format.tagName().ptr,
                .texture_format_len = texture_format.tagName().len,
                .dimension_ptr = @tagName(dimension).ptr,
                .dimension_len = @tagName(dimension).len,
            };
        }
    };

    pub const AddressMode = enum(js.Uint32) {
        @"clamp-to-edge" = c.WGPUAddressMode_ClampToEdge,
    };

    pub const FilterMode = enum(js.Uint32) {
        nearest = c.WGPUFilterMode_Nearest,
        linear = c.WGPUFilterMode_Linear,
    };

    pub const MipmapFilterMode = enum(js.Uint32) {
        nearest = c.WGPUMipmapFilterMode_Nearest,
        linear = c.WGPUMipmapFilterMode_Linear,
    };

    pub const SamplerDescriptor = extern struct {
        address_mode_u_ptr: js.StringPtr = @tagName(DEFAULT_ADDRESS_MODE).ptr,
        address_mode_u_len: js.Uint32 = @tagName(DEFAULT_ADDRESS_MODE).len,
        address_mode_v_ptr: js.StringPtr = @tagName(DEFAULT_ADDRESS_MODE).ptr,
        address_mode_v_len: js.Uint32 = @tagName(DEFAULT_ADDRESS_MODE).len,
        address_mode_w_ptr: js.StringPtr = @tagName(DEFAULT_ADDRESS_MODE).ptr,
        address_mode_w_len: js.Uint32 = @tagName(DEFAULT_ADDRESS_MODE).len,
        mag_filter_ptr: js.StringPtr = @tagName(DEFAULT_FILTER_MODE).ptr,
        mag_filter_len: js.Uint32 = @tagName(DEFAULT_FILTER_MODE).len,
        min_filter_ptr: js.StringPtr = @tagName(DEFAULT_FILTER_MODE).ptr,
        min_filter_len: js.Uint32 = @tagName(DEFAULT_FILTER_MODE).len,
        mipmap_filter_ptr: js.StringPtr = @tagName(DEFAULT_MIPMAP_FILTER_MODE).ptr,
        mipmap_filter_len: js.Uint32 = @tagName(DEFAULT_MIPMAP_FILTER_MODE).len,
        max_anisotropy: js.Uint32 = 1,

        const DEFAULT_ADDRESS_MODE: AddressMode = .@"clamp-to-edge";
        const DEFAULT_FILTER_MODE: FilterMode = .nearest;
        const DEFAULT_MIPMAP_FILTER_MODE: MipmapFilterMode = .nearest;
    };

    pub const VertexFormat = enum(js.Uint32) {
        float32x2 = c.WGPUVertexFormat_Float32x2,
        unorm8x4 = c.WGPUVertexFormat_Unorm8x4,
    };

    pub const VertexStepMode = enum(js.Uint32) {
        vertex = c.WGPUVertexStepMode_Vertex,
    };

    pub const VertexAttribute = extern struct {
        offset: js.Offset,
        shader_location: js.Uint32,
        vertex_format_ptr: js.StringPtr,
        vertex_format_len: js.Uint32,

        pub fn init(shader_location: js.Uint32, vertex_format: VertexFormat, offset: js.Offset) @This() {
            return .{
                .offset = offset,
                .shader_location = shader_location,
                .vertex_format_ptr = @tagName(vertex_format).ptr,
                .vertex_format_len = @tagName(vertex_format).len,
            };
        }
    };

    pub const VertexBufferLayout = extern struct {
        array_stride: js.BigUint64,
        step_mode_ptr: js.StringPtr = @tagName(DEFAULT_VERTEX_STEP_MODE).ptr,
        step_mode_len: js.Uint32 = @tagName(DEFAULT_VERTEX_STEP_MODE).len,
        vertex_attributes_ptr: js.OpaquePtr,
        vertex_attributes_len: js.Uint32,

        const DEFAULT_VERTEX_STEP_MODE: VertexStepMode = .vertex;

        pub fn init(array_stride: js.BigUint64, vertex_attributes: []const VertexAttribute) @This() {
            return .{
                .array_stride = array_stride,
                .vertex_attributes_ptr = @intFromPtr(vertex_attributes.ptr),
                .vertex_attributes_len = vertex_attributes.len,
            };
        }
    };

    pub const VertexState = extern struct {
        buffers_ptr: js.OpaquePtr,
        buffers_len: js.Uint32,
        module_handle: js.Handle,

        pub fn init(module: ShaderModule, buffers: []const VertexBufferLayout) @This() {
            js.console.assert(module.handle != null_handle, @src());
            return .{
                .buffers_ptr = @intFromPtr(buffers.ptr),
                .buffers_len = buffers.len,
                .module_handle = module.handle,
            };
        }
    };

    pub const BlendOperation = enum(js.Uint32) {
        add = c.WGPUBlendOperation_Add,
    };

    pub const BlendFactor = enum(js.Uint32) {
        zero = c.WGPUBlendFactor_Zero,
        one = c.WGPUBlendFactor_One,
        @"src-alpha" = c.WGPUBlendFactor_SrcAlpha,
        @"one-minus-src-alpha" = c.WGPUBlendFactor_OneMinusSrcAlpha,
    };

    pub const BlendComponent = struct {
        operation: BlendOperation,
        src_factor: BlendFactor,
        dst_factor: BlendFactor,
    };

    pub const ColorWriteMask = struct {
        pub const all: js.Flags = c.WGPUColorWriteMask_All;
    };

    pub const ColorTargetState = extern struct {
        color_write_mask: js.Flags,
        blend_color_operation_ptr: js.StringPtr,
        blend_color_operation_len: js.Uint32,
        blend_color_src_factor_ptr: js.StringPtr,
        blend_color_src_factor_len: js.Uint32,
        blend_color_dst_factor_ptr: js.StringPtr,
        blend_color_dst_factor_len: js.Uint32,
        blend_alpha_operation_ptr: js.StringPtr,
        blend_alpha_operation_len: js.Uint32,
        blend_alpha_src_factor_ptr: js.StringPtr,
        blend_alpha_src_factor_len: js.Uint32,
        blend_alpha_dst_factor_ptr: js.StringPtr,
        blend_alpha_dst_factor_len: js.Uint32,
        texture_format_ptr: js.StringPtr,
        texture_format_len: js.Uint32,

        pub fn init(texture_format: TextureFormat, color: BlendComponent, alpha: BlendComponent, color_write_mask: js.Flags) @This() {
            return .{
                .color_write_mask = color_write_mask,
                .blend_color_operation_ptr = @tagName(color.operation).ptr,
                .blend_color_operation_len = @tagName(color.operation).len,
                .blend_color_src_factor_ptr = @tagName(color.src_factor).ptr,
                .blend_color_src_factor_len = @tagName(color.src_factor).len,
                .blend_color_dst_factor_ptr = @tagName(color.dst_factor).ptr,
                .blend_color_dst_factor_len = @tagName(color.dst_factor).len,
                .blend_alpha_operation_ptr = @tagName(alpha.operation).ptr,
                .blend_alpha_operation_len = @tagName(alpha.operation).len,
                .blend_alpha_src_factor_ptr = @tagName(alpha.src_factor).ptr,
                .blend_alpha_src_factor_len = @tagName(alpha.src_factor).len,
                .blend_alpha_dst_factor_ptr = @tagName(alpha.dst_factor).ptr,
                .blend_alpha_dst_factor_len = @tagName(alpha.dst_factor).len,
                .texture_format_ptr = texture_format.tagName().ptr,
                .texture_format_len = texture_format.tagName().len,
            };
        }
    };

    pub const FragmentState = extern struct {
        targets_ptr: js.OpaquePtr,
        targets_len: js.Uint32,
        module_handle: js.Handle,

        pub fn init(module: ShaderModule, targets: []const ColorTargetState) @This() {
            js.console.assert(module.handle != null_handle, @src());
            return .{
                .targets_ptr = @intFromPtr(targets.ptr),
                .targets_len = targets.len,
                .module_handle = module.handle,
            };
        }
    };

    pub const PrimitiveTopology = enum(js.Uint32) {
        @"triangle-list" = c.WGPUPrimitiveTopology_TriangleList,
    };

    pub const FrontFace = enum(js.Uint32) {
        ccw = c.WGPUFrontFace_CCW,
        cw = c.WGPUFrontFace_CW,
    };

    pub const CullMode = enum(js.Uint32) {
        none = c.WGPUCullMode_None,
    };

    pub const PrimitiveState = extern struct {
        topology_ptr: js.StringPtr = @tagName(DEFAULT_TOPOLOGY).ptr,
        topology_len: js.Uint32 = @tagName(DEFAULT_TOPOLOGY).len,
        front_face_ptr: js.StringPtr = @tagName(DEFAULT_FRONT_FACE).ptr,
        front_face_len: js.Uint32 = @tagName(DEFAULT_FRONT_FACE).len,
        cull_mode_ptr: js.StringPtr = @tagName(DEFAULT_CULL_MODE).ptr,
        cull_mode_len: js.Uint32 = @tagName(DEFAULT_CULL_MODE).len,
        strip_index_format_ptr: js.StringPtr = DEFAULT_STRIP_INDEX_FORMAT.tagName().ptr,
        strip_index_format_len: js.Uint32 = DEFAULT_STRIP_INDEX_FORMAT.tagName().len,

        const DEFAULT_TOPOLOGY: PrimitiveTopology = .@"triangle-list";
        const DEFAULT_FRONT_FACE: FrontFace = .ccw;
        const DEFAULT_CULL_MODE: CullMode = .none;
        const DEFAULT_STRIP_INDEX_FORMAT: IndexFormat = .undefined;
    };

    pub const TextureFormat = enum(js.Uint32) {
        undefined = c.WGPUTextureFormat_Undefined,
        r8unorm = c.WGPUTextureFormat_R8Unorm,
        r8snorm = c.WGPUTextureFormat_R8Snorm,
        r8uint = c.WGPUTextureFormat_R8Uint,
        r8sint = c.WGPUTextureFormat_R8Sint,
        r16unorm = c.WGPUTextureFormat_R16Unorm,
        r16snorm = c.WGPUTextureFormat_R16Snorm,
        r16uint = c.WGPUTextureFormat_R16Uint,
        r16sint = c.WGPUTextureFormat_R16Sint,
        r16float = c.WGPUTextureFormat_R16Float,
        rg8unorm = c.WGPUTextureFormat_RG8Unorm,
        rg8snorm = c.WGPUTextureFormat_RG8Snorm,
        rg8uint = c.WGPUTextureFormat_RG8Uint,
        rg8sint = c.WGPUTextureFormat_RG8Sint,
        r32uint = c.WGPUTextureFormat_R32Uint,
        r32sint = c.WGPUTextureFormat_R32Sint,
        r32float = c.WGPUTextureFormat_R32Float,
        rg16unorm = c.WGPUTextureFormat_RG16Unorm,
        rg16snorm = c.WGPUTextureFormat_RG16Snorm,
        rg16uint = c.WGPUTextureFormat_RG16Uint,
        rg16sint = c.WGPUTextureFormat_RG16Sint,
        rg16float = c.WGPUTextureFormat_RG16Float,
        rgba8unorm = c.WGPUTextureFormat_RGBA8Unorm,
        @"rgba8unorm-srgb" = c.WGPUTextureFormat_RGBA8UnormSrgb,
        rgba8snorm = c.WGPUTextureFormat_RGBA8Snorm,
        rgba8uint = c.WGPUTextureFormat_RGBA8Uint,
        rgba8sint = c.WGPUTextureFormat_RGBA8Sint,
        bgra8unorm = c.WGPUTextureFormat_BGRA8Unorm,
        @"bgra8unorm-srgb" = c.WGPUTextureFormat_BGRA8UnormSrgb,
        rgb9e5ufloat = c.WGPUTextureFormat_RGB10A2Uint,
        rgb10a2uint = c.WGPUTextureFormat_RGB10A2Unorm,
        rgb10a2unorm = c.WGPUTextureFormat_RG11B10Ufloat,
        rg11b10ufloat = c.WGPUTextureFormat_RGB9E5Ufloat,
        rg32uint = c.WGPUTextureFormat_RG32Float,
        rg32sint = c.WGPUTextureFormat_RG32Uint,
        rg32float = c.WGPUTextureFormat_RG32Sint,
        rgba16unorm = c.WGPUTextureFormat_RGBA16Unorm,
        rgba16snorm = c.WGPUTextureFormat_RGBA16Snorm,
        rgba16uint = c.WGPUTextureFormat_RGBA16Uint,
        rgba16sint = c.WGPUTextureFormat_RGBA16Sint,
        rgba16float = c.WGPUTextureFormat_RGBA16Float,
        rgba32uint = c.WGPUTextureFormat_RGBA32Float,
        rgba32sint = c.WGPUTextureFormat_RGBA32Uint,
        rgba32float = c.WGPUTextureFormat_RGBA32Sint,
        stencil8 = c.WGPUTextureFormat_Stencil8,
        depth16unorm = c.WGPUTextureFormat_Depth16Unorm,
        depth24plus = c.WGPUTextureFormat_Depth24Plus,
        @"depth24plus-stencil8" = c.WGPUTextureFormat_Depth24PlusStencil8,
        depth32float = c.WGPUTextureFormat_Depth32Float,
        @"depth32float-stencil8" = c.WGPUTextureFormat_Depth32FloatStencil8,
        @"bc1-rgba-unorm" = c.WGPUTextureFormat_BC1RGBAUnorm,
        @"bc1-rgba-unorm-srgb" = c.WGPUTextureFormat_BC1RGBAUnormSrgb,
        @"bc2-rgba-unorm" = c.WGPUTextureFormat_BC2RGBAUnorm,
        @"bc2-rgba-unorm-srgb" = c.WGPUTextureFormat_BC2RGBAUnormSrgb,
        @"bc3-rgba-unorm" = c.WGPUTextureFormat_BC3RGBAUnorm,
        @"bc3-rgba-unorm-srgb" = c.WGPUTextureFormat_BC3RGBAUnormSrgb,
        @"bc4-r-unorm" = c.WGPUTextureFormat_BC4RUnorm,
        @"bc4-r-snorm" = c.WGPUTextureFormat_BC4RSnorm,
        @"bc5-rg-unorm" = c.WGPUTextureFormat_BC5RGUnorm,
        @"bc5-rg-snorm" = c.WGPUTextureFormat_BC5RGSnorm,
        @"bc6h-rgb-ufloat" = c.WGPUTextureFormat_BC6HRGBUfloat,
        @"bc6h-rgb-float" = c.WGPUTextureFormat_BC6HRGBFloat,
        @"bc7-rgba-unorm" = c.WGPUTextureFormat_BC7RGBAUnorm,
        @"bc7-rgba-unorm-srgb" = c.WGPUTextureFormat_BC7RGBAUnormSrgb,
        @"etc2-rgb8unorm" = c.WGPUTextureFormat_ETC2RGB8Unorm,
        @"etc2-rgb8unorm-srgb" = c.WGPUTextureFormat_ETC2RGB8UnormSrgb,
        @"etc2-rgb8a1unorm" = c.WGPUTextureFormat_ETC2RGB8A1Unorm,
        @"etc2-rgb8a1unorm-srgb" = c.WGPUTextureFormat_ETC2RGB8A1UnormSrgb,
        @"etc2-rgba8unorm" = c.WGPUTextureFormat_ETC2RGBA8Unorm,
        @"etc2-rgba8unorm-srgb" = c.WGPUTextureFormat_ETC2RGBA8UnormSrgb,
        @"eac-r11unorm" = c.WGPUTextureFormat_EACR11Unorm,
        @"eac-r11snorm" = c.WGPUTextureFormat_EACR11Snorm,
        @"eac-rg11unorm" = c.WGPUTextureFormat_EACRG11Unorm,
        @"eac-rg11snorm" = c.WGPUTextureFormat_EACRG11Snorm,
        @"astc-4x4-unorm" = c.WGPUTextureFormat_ASTC4x4Unorm,
        @"astc-4x4-unorm-srgb" = c.WGPUTextureFormat_ASTC4x4UnormSrgb,
        @"astc-5x4-unorm" = c.WGPUTextureFormat_ASTC5x4Unorm,
        @"astc-5x4-unorm-srgb" = c.WGPUTextureFormat_ASTC5x4UnormSrgb,
        @"astc-5x5-unorm" = c.WGPUTextureFormat_ASTC5x5Unorm,
        @"astc-5x5-unorm-srgb" = c.WGPUTextureFormat_ASTC5x5UnormSrgb,
        @"astc-6x5-unorm" = c.WGPUTextureFormat_ASTC6x5Unorm,
        @"astc-6x5-unorm-srgb" = c.WGPUTextureFormat_ASTC6x5UnormSrgb,
        @"astc-6x6-unorm" = c.WGPUTextureFormat_ASTC6x6Unorm,
        @"astc-6x6-unorm-srgb" = c.WGPUTextureFormat_ASTC6x6UnormSrgb,
        @"astc-8x5-unorm" = c.WGPUTextureFormat_ASTC8x5Unorm,
        @"astc-8x5-unorm-srgb" = c.WGPUTextureFormat_ASTC8x5UnormSrgb,
        @"astc-8x6-unorm" = c.WGPUTextureFormat_ASTC8x6Unorm,
        @"astc-8x6-unorm-srgb" = c.WGPUTextureFormat_ASTC8x6UnormSrgb,
        @"astc-8x8-unorm" = c.WGPUTextureFormat_ASTC8x8Unorm,
        @"astc-8x8-unorm-srgb" = c.WGPUTextureFormat_ASTC8x8UnormSrgb,
        @"astc-10x5-unorm" = c.WGPUTextureFormat_ASTC10x5Unorm,
        @"astc-10x5-unorm-srgb" = c.WGPUTextureFormat_ASTC10x5UnormSrgb,
        @"astc-10x6-unorm" = c.WGPUTextureFormat_ASTC10x6Unorm,
        @"astc-10x6-unorm-srgb" = c.WGPUTextureFormat_ASTC10x6UnormSrgb,
        @"astc-10x8-unorm" = c.WGPUTextureFormat_ASTC10x8Unorm,
        @"astc-10x8-unorm-srgb" = c.WGPUTextureFormat_ASTC10x8UnormSrgb,
        @"astc-10x10-unorm" = c.WGPUTextureFormat_ASTC10x10Unorm,
        @"astc-10x10-unorm-srgb" = c.WGPUTextureFormat_ASTC10x10UnormSrgb,
        @"astc-12x10-unorm" = c.WGPUTextureFormat_ASTC12x10Unorm,
        @"astc-12x10-unorm-srgb" = c.WGPUTextureFormat_ASTC12x10UnormSrgb,
        @"astc-12x12-unorm" = c.WGPUTextureFormat_ASTC12x12Unorm,
        @"astc-12x12-unorm-srgb" = c.WGPUTextureFormat_ASTC12x12UnormSrgb,

        pub fn tagName(self: @This()) []const u8 {
            return switch (self) {
                .undefined => "",
                else => @tagName(self),
            };
        }
    };

    pub const ShaderModule = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const BindGroupLayout = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const PipelineLayout = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const RenderPipeline = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const CommandEncoder = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }

        pub fn beginRenderPass(self: @This(), texture_view: TextureView, descriptor: RenderPassDescriptor) RenderPassEncoder {
            js.console.assert(self.isInit(), @src());
            js.console.assert(texture_view.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            return RenderPassEncoder.init(js.gpuCommandEncoderBeginRenderPass(self.handle, texture_view.handle, @intFromPtr(&descriptor)));
        }

        pub fn finish(self: @This()) CommandBuffer {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            return CommandBuffer.init(js.gpuCommandEncoderFinish(self.handle));
        }
    };

    pub const LoadOp = enum(js.Uint32) {
        load = c.WGPULoadOp_Load,
        clear = c.WGPULoadOp_Clear,
    };

    pub const StoreOp = enum(js.Uint32) {
        store = c.WGPUStoreOp_Store,
    };

    pub const RenderPassDescriptor = extern struct {
        load_op_ptr: js.StringPtr = @tagName(DEFAULT_LOAD_OP).ptr,
        load_op_len: js.Uint32 = @tagName(DEFAULT_LOAD_OP).len,
        store_op_ptr: js.StringPtr = @tagName(DEFAULT_STORE_OP).ptr,
        store_op_len: js.Uint32 = @tagName(DEFAULT_STORE_OP).len,

        const DEFAULT_LOAD_OP: LoadOp = .clear;
        const DEFAULT_STORE_OP: StoreOp = .store;

        pub fn fromLoadOp(load_op: LoadOp) @This() {
            return .{
                .load_op_ptr = @tagName(load_op).ptr,
                .load_op_len = @tagName(load_op).len,
            };
        }
    };

    pub const CommandBuffer = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const RenderPassEncoder = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }

        pub fn setPipeline(self: @This(), render_pipeline: RenderPipeline) void {
            js.console.assert(self.isInit(), @src());
            js.console.assert(render_pipeline.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetPipeline(self.handle, render_pipeline.handle);
        }

        pub fn setVertexBuffer(self: @This(), slot: js.Uint32, vertex_buffer: Buffer, offset: js.Offset, size: js.Size) void {
            js.console.assert(self.isInit(), @src());
            js.console.assert(vertex_buffer.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetVertexBuffer(self.handle, slot, vertex_buffer.handle, offset, size);
        }

        pub fn setIndexBuffer(self: @This(), index_buffer: Buffer, index_format: IndexFormat, offset: js.Offset, size: js.Size) void {
            js.console.assert(self.isInit(), @src());
            js.console.assert(index_buffer.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetIndexBuffer(self.handle, index_buffer.handle, index_format.tagName().ptr, index_format.tagName().len, offset, size);
        }

        pub fn setBindGroup(self: @This(), group_index: js.Uint32, bind_group: BindGroup, dynamic_offsets: []const js.Uint32) void {
            js.console.assert(self.isInit(), @src());
            js.console.assert(bind_group.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetBindGroup(self.handle, group_index, bind_group.handle, @intFromPtr(dynamic_offsets.ptr), dynamic_offsets.len);
        }

        pub fn setScissorRect(self: @This(), x: js.Uint32, y: js.Uint32, width: js.Uint32, height: js.Uint32) void {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetScissorRect(self.handle, x, y, width, height);
        }

        pub fn setViewport(self: @This(), x: js.Float32, y: js.Float32, width: js.Float32, height: js.Float32, min_depth: js.Float32, max_depth: js.Float32) void {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetViewport(self.handle, x, y, width, height, min_depth, max_depth);
        }

        pub fn setBlendConstant(self: @This(), color: Color) void {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderSetBlendConstant(self.handle, @intFromPtr(&color));
        }

        pub fn drawIndexed(self: @This(), index_count: js.Uint32, instance_count: js.Uint32, first_index: js.Uint32, base_vertex: js.Int32, first_instance: js.Uint32) void {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderDrawIndexed(self.handle, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        pub fn end(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuRenderPassEncoderEnd(self.handle);
            self.deinit();
        }
    };

    pub const IndexFormat = enum(js.Uint32) {
        undefined = c.WGPUIndexFormat_Undefined,
        uint16 = c.WGPUIndexFormat_Uint16,
        uint32 = c.WGPUIndexFormat_Uint32,

        pub fn tagName(self: @This()) []const u8 {
            return switch (self) {
                .undefined => "",
                else => @tagName(self),
            };
        }
    };

    pub const Color = extern struct {
        r: js.Float64,
        g: js.Float64,
        b: js.Float64,
        a: js.Float64,
    };

    pub const Queue = struct {
        handle: js.Handle = null_handle,

        var instance: @This() = .{};

        pub fn init(handle: js.Handle) void {
            js.console.assert(handle != null_handle, @src());
            instance = .{ .handle = handle };
        }

        pub fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn submit(command_buffers: []const CommandBuffer) void {
            js.console.assert(isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            for (command_buffers) |command_buffer| js.console.assert(command_buffer.isInit(), @src());
            js.gpuQueueSubmit(instance.handle, @intFromPtr(command_buffers.ptr), command_buffers.len);
        }

        pub fn writeBuffer(comptime T: type, buffer: Buffer, buffer_offset: js.Offset, data: []const T, data_offset: js.Offset, size: js.Size) void {
            js.console.assert(isInit(), @src());
            js.console.assert(buffer.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            const bytes = std.mem.sliceAsBytes(data);
            js.gpuQueueWriteBuffer(instance.handle, buffer.handle, buffer_offset, bytes.ptr, bytes.len, data_offset, size);
        }

        pub fn writeTexture(info: TexelCopyTextureInfo, data: []const u8, data_layout: TexelCopyBufferLayout, size_extent: Extent3D) void {
            js.console.assert(isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuQueueWriteTexture(instance.handle, @intFromPtr(&info), data.ptr, data.len, @intFromPtr(&data_layout), @intFromPtr(&size_extent));
        }
    };

    pub const TexelCopyTextureInfo = extern struct {
        texture_handle: js.Handle,
        mip_level: js.Uint32,
        origin_x: js.Uint32,
        origin_y: js.Uint32,
        origin_z: js.Uint32,
        aspect_ptr: js.StringPtr,
        aspect_len: js.Uint32,

        pub fn init(texture: Texture, mip_level: js.Uint32, x: js.Uint32, y: js.Uint32, z: js.Uint32, aspect: TextureAspect) @This() {
            js.console.assert(texture.handle != null_handle, @src());
            return .{
                .texture_handle = texture.handle,
                .mip_level = mip_level,
                .origin_x = x,
                .origin_y = y,
                .origin_z = z,
                .aspect_ptr = @tagName(aspect).ptr,
                .aspect_len = @tagName(aspect).len,
            };
        }
    };

    pub const TexelCopyBufferLayout = extern struct {
        offset: js.Offset,
        bytes_per_row: js.Uint32,
        rows_per_image: js.Uint32,
    };

    pub const Extent3D = extern struct {
        width: js.Uint32,
        height: js.Uint32,
        depth_or_array_layers: js.Uint32,
    };

    pub const Texture = struct {
        handle: js.Handle = null_handle,
        width: js.Uint32,
        height: js.Uint32,
        depth_or_array_layers: js.Uint32,
        texture_format: TextureFormat,
        dimension: TextureDimension,
        mip_level_count: js.Uint32 = 1,

        pub fn init(handle: js.Handle, width: js.Uint32, height: js.Uint32, depth_or_array_layers: js.Uint32, texture_format: TextureFormat, dimension: TextureDimension, mip_level_count: js.Uint32) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{
                .handle = handle,
                .width = width,
                .height = height,
                .depth_or_array_layers = depth_or_array_layers,
                .texture_format = texture_format,
                .dimension = dimension,
                .mip_level_count = mip_level_count,
            };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }

        pub fn createView(self: @This(), descriptor: TextureViewDescriptor, omitted_fields: TextureViewDescriptorOmittedFields) TextureView {
            js.console.assert(self.isInit(), @src());

            var new_descriptor = descriptor;
            if (descriptor.texture_format_len == 0) {
                new_descriptor.texture_format_ptr = self.texture_format.tagName().ptr;
                new_descriptor.texture_format_len = self.texture_format.tagName().len;
            }
            if (descriptor.dimension_len == 0) {
                const dimension: TextureViewDimension = if (descriptor.array_layer_count > 1) .@"2d-array" else .@"2d";
                new_descriptor.dimension_ptr = @tagName(dimension).ptr;
                new_descriptor.dimension_len = @tagName(dimension).len;
            }

            if (omitted_fields.mip_level_count) new_descriptor.mip_level_count = self.mip_level_count - descriptor.base_mip_level;
            if (omitted_fields.array_layer_count) {
                const dimension_ptr = new_descriptor.dimension_ptr;
                const dimension = std.meta.stringToEnum(TextureViewDimension, dimension_ptr[0..new_descriptor.dimension_len]) orelse std.debug.panic("Unknown TextureDimension", .{});
                new_descriptor.array_layer_count = switch (dimension) {
                    .@"2d" => 1,
                    .@"2d-array" => self.depth_or_array_layers - descriptor.base_array_layer,
                };
            }

            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            return TextureView.init(js.gpuTextureCreateView(self.handle, @intFromPtr(&new_descriptor)));
        }
    };

    pub const TextureView = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const TextureViewDimension = enum(js.Uint32) {
        @"2d" = c.WGPUTextureViewDimension_2D,
        @"2d-array" = c.WGPUTextureViewDimension_2DArray,
    };

    pub const TextureAspect = enum(js.Uint32) {
        all = c.WGPUTextureAspect_All,
    };

    pub const TextureViewDescriptorOmittedFields = struct {
        mip_level_count: bool = true,
        array_layer_count: bool = true,
    };

    pub const TextureViewDescriptor = extern struct {
        base_mip_level: js.Uint32 = 0,
        mip_level_count: js.Uint32 = 1,
        base_array_layer: js.Uint32 = 0,
        array_layer_count: js.Uint32 = 1,
        texture_format_ptr: js.StringPtr = "",
        texture_format_len: js.Uint32 = 0,
        dimension_ptr: js.StringPtr = "",
        dimension_len: js.Uint32 = 0,
        aspect_ptr: js.StringPtr = @tagName(DEFAULT_ASPECT).ptr,
        aspect_len: js.Uint32 = @tagName(DEFAULT_ASPECT).len,

        const DEFAULT_ASPECT: TextureAspect = .all;

        pub fn init(texture_format: TextureFormat, dimension: TextureViewDimension, aspect: TextureAspect, base_mip_level: js.Uint32, mip_level_count: js.Uint32, base_array_layer: js.Uint32, array_layer_count: js.Uint32) @This() {
            return .{
                .base_mip_level = base_mip_level,
                .mip_level_count = mip_level_count,
                .base_array_layer = base_array_layer,
                .array_layer_count = array_layer_count,
                .texture_format_ptr = texture_format.tagName().ptr,
                .texture_format_len = texture_format.tagName().len,
                .dimension_ptr = @tagName(dimension).ptr,
                .dimension_len = @tagName(dimension).len,
                .aspect_ptr = @tagName(aspect).ptr,
                .aspect_len = @tagName(aspect).len,
            };
        }

        pub fn fromDimension(dimension: TextureViewDimension) @This() {
            return .{
                .dimension_ptr = @tagName(dimension).ptr,
                .dimension_len = @tagName(dimension).len,
            };
        }
    };

    pub const TextureUsage = struct {
        pub const copy_dst: js.Flags = c.WGPUTextureUsage_CopyDst;
        pub const texture_binding: js.Flags = c.WGPUTextureUsage_TextureBinding;
        pub const render_attachment: js.Flags = c.WGPUTextureUsage_RenderAttachment;
    };

    pub const Buffer = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }

        pub fn destroy(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            if (js.gpu.Device.isInit()) js.gpu.Device.pushErrorScope(.validation);
            defer if (js.gpu.Device.isInit()) js.gpu.Device.popErrorScope();
            js.gpuDestroyBuffer(self.handle);
        }
    };

    pub const BufferUsage = struct {
        pub const copy_dst: js.Flags = c.WGPUBufferUsage_CopyDst;
        pub const index: js.Flags = c.WGPUBufferUsage_Index;
        pub const vertex: js.Flags = c.WGPUBufferUsage_Vertex;
        pub const uniform: js.Flags = c.WGPUBufferUsage_Uniform;
    };

    pub const BindGroup = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };

    pub const ShaderStage = struct {
        pub const vertex: js.Flags = c.WGPUShaderStage_Vertex;
        pub const fragment: js.Flags = c.WGPUShaderStage_Fragment;
    };

    pub const BindingType = enum(js.Uint32) {
        uniform_buffer = std.math.minInt(js.Uint32),
        texture_2d,
        texture_2d_array,
        sampler,
    };

    pub const BindGroupLayoutEntry = extern struct {
        visibility: js.Flags,
        binding: js.Uint32,
        entry_type: js.gpu.BindingType, // 0 = uniform buffer, 1 = 2D texture, 2 = 2D array texture, 3 = sampler

        pub fn initUniformBuffer(binding: js.Uint32, visibility: js.Flags) @This() {
            return .{
                .visibility = visibility,
                .binding = binding,
                .entry_type = .uniform_buffer,
            };
        }

        pub fn initSampler(binding: js.Uint32, visibility: js.Flags) BindGroupLayoutEntry {
            return .{
                .visibility = visibility,
                .binding = binding,
                .entry_type = .sampler,
            };
        }

        pub fn init2DTexture(binding: js.Uint32, visibility: js.Flags) BindGroupLayoutEntry {
            return .{
                .visibility = visibility,
                .binding = binding,
                .entry_type = .texture_2d,
            };
        }

        pub fn init2DArrayTexture(binding: js.Uint32, visibility: js.Flags) BindGroupLayoutEntry {
            return .{
                .visibility = visibility,
                .binding = binding,
                .entry_type = .texture_2d_array,
            };
        }
    };

    pub const BindGroupEntry = extern struct {
        offset: js.Offset,
        size: js.Size,
        binding: js.Uint32,
        entry_type: js.Uint32, // 0 = buffer, 1 = texture_view, 2 = sampler
        resource_handle: js.Uint32, // Buffer handle, TextureView handle or Sampler handle

        pub fn isInit(self: @This()) bool {
            return self.resource_handle != null_handle;
        }

        pub fn initBuffer(binding: js.Uint32, buffer: Buffer, offset: js.Offset, size: js.Size) @This() {
            js.console.assert(buffer.isInit(), @src());
            return .{
                .offset = offset,
                .size = size,
                .binding = binding,
                .entry_type = 0, // buffer
                .resource_handle = buffer.handle,
            };
        }

        pub fn initTextureView(binding: js.Uint32, texture_view: TextureView) @This() {
            js.console.assert(texture_view.isInit(), @src());
            return .{
                .offset = 0,
                .size = 0,
                .binding = binding,
                .entry_type = 1, // texture_view
                .resource_handle = texture_view.handle,
            };
        }

        pub fn initSampler(binding: js.Uint32, sampler: Sampler) @This() {
            js.console.assert(sampler.isInit(), @src());
            return .{
                .offset = 0,
                .size = 0,
                .binding = binding,
                .entry_type = 2, // sampler
                .resource_handle = sampler.handle,
            };
        }
    };

    pub const Sampler = struct {
        handle: js.Handle = null_handle,

        pub fn init(handle: js.Handle) @This() {
            js.console.assert(handle != null_handle, @src());
            return .{ .handle = handle };
        }

        pub fn isInit(self: @This()) bool {
            return self.handle != null_handle;
        }

        pub fn deinit(self: *@This()) void {
            js.console.assert(self.isInit(), @src());
            js.gpuRelease(self.handle);
            self.handle = null_handle;
        }
    };
};

pub const platform = struct {
    var is_init = false;

    pub const DeltaMode = imports.PlatformDeltaMode;

    pub fn init() void {
        js.console.assert(!is_init, @src());
        defer is_init = true;
        Clipboard.init();
        Window.init();
    }

    pub const MouseButton = enum(c_int) {
        left = c.GLFW_MOUSE_BUTTON_LEFT,
        right = c.GLFW_MOUSE_BUTTON_RIGHT,
        middle = c.GLFW_MOUSE_BUTTON_MIDDLE,

        pub fn fromDOM(code: c_int) @This() {
            return switch (code) {
                0 => .left,
                1 => .middle,
                2 => .right,
                else => std.debug.panic("{s}.{s}: unknown code ({d})", .{ @typeName(@This()), @src().fn_name, code }),
            };
        }
    };

    pub const Action = enum(c_int) {
        release = c.GLFW_RELEASE,
        press = c.GLFW_PRESS,
    };

    pub const Mod = enum(c_int) {
        shift = c.GLFW_MOD_SHIFT,
        control = c.GLFW_MOD_CONTROL,
        alt = c.GLFW_MOD_ALT,
        super = c.GLFW_MOD_SUPER,
        caps_lock = c.GLFW_MOD_CAPS_LOCK,
        num_lock = c.GLFW_MOD_NUM_LOCK,
    };

    pub const Key = blk: {
        @setEvalBranchQuota(100_000);
        const c_decl_names = @typeInfo(c).@"struct".decl_names;
        var i = 0;
        for (c_decl_names) |c_decl_name| {
            if (std.mem.eql(u8, c_decl_name, "GLFW_KEY_LAST")) continue;
            if (std.mem.startsWith(u8, c_decl_name, "GLFW_KEY_")) i += 1;
        }
        var field_names: [i][]const u8 = @splat("");
        var field_values: [i]c_int = @splat(0);
        i = 0;
        for (c_decl_names) |c_decl_name| {
            if (std.mem.eql(u8, c_decl_name, "GLFW_KEY_LAST")) continue;
            if (std.mem.startsWith(u8, c_decl_name, "GLFW_KEY_")) {
                var buffer: [c_decl_name.len - 9]u8 = undefined;
                _ = std.ascii.lowerString(&buffer, c_decl_name[9..]);
                field_names[i] = &buffer;
                field_values[i] = @field(c, c_decl_name);
                i += 1;
            }
        }
        break :blk @Enum(c_int, .exhaustive, &field_names, &field_values);
    };

    // Agnostic DOM Scancode
    // Coming from: https://github.com/emscripten-core/emscripten/blob/main/tools/maint/create_dom_pk_codes.py
    pub const Scancode = enum(c_int) {
        unknown = 0x0000,
        space = 0x0039,

        fn fromKey(key: Key) @This() {
            js.console.assert(js.platform.is_init, @src());
            return switch (key) {
                .space => .space,
                else => .unknown,
            };
        }

        fn fromStr(str: [*:0]const u8) @This() {
            var hash: u32 = 0;
            var ptr = str;
            while (ptr[0] != 0) : (ptr += 1) {
                hash = ((hash ^ 0x7E057D79) << 3) ^ @as(u32, ptr[0]);
            }

            return switch (hash) {
                0x92E09CB5 => .space,
                else => .unknown,
            };
        }

        fn toKey(self: @This()) Key {
            js.console.assert(js.platform.is_init, @src());
            return switch (self) {
                .unknown => .unknown,
                .space => .space,
            };
        }
    };

    pub const KeyState = enum(c_int) {
        release = c.GLFW_RELEASE,
        press = c.GLFW_PRESS,
    };

    pub const Cursor = struct {
        const Shape = enum(c_int) {
            arrow = c.GLFW_ARROW_CURSOR,
            ibeam = c.GLFW_IBEAM_CURSOR,
            crosshair = c.GLFW_CROSSHAIR_CURSOR,
            pointing_hand = c.GLFW_POINTING_HAND_CURSOR,
            resize_ew = c.GLFW_RESIZE_EW_CURSOR,
            resize_ns = c.GLFW_RESIZE_NS_CURSOR,
            resize_nesw = c.GLFW_RESIZE_NESW_CURSOR,
            resize_nwse = c.GLFW_RESIZE_NWSE_CURSOR,
            resize_all = c.GLFW_RESIZE_ALL_CURSOR,
            not_allowed = c.GLFW_NOT_ALLOWED_CURSOR,
        };

        const Mode = enum(c_int) {
            normal = c.GLFW_CURSOR_NORMAL,
            hidden = c.GLFW_CURSOR_HIDDEN,
            disabled = c.GLFW_CURSOR_DISABLED,
        };

        shape: Shape,

        const default: @This() = .{ .shape = .arrow };
    };

    pub const Mouse = struct {
        var instance: @This() = undefined;

        cursor: Cursor,
        visible_cursor: Cursor,
        cursor_mode: Cursor.Mode,
        cursor_pos_x: f64,
        cursor_pos_y: f64,
        buttons: std.enums.EnumMap(MouseButton, KeyState),

        fn init() void {
            instance = .{
                .cursor = .default,
                .visible_cursor = .default,
                .cursor_mode = .normal,
                .cursor_pos_x = 0.0,
                .cursor_pos_y = 0.0,
                .buttons = .initFull(.release),
            };
        }

        pub fn getCursorPosX() f64 {
            return instance.cursor_pos_x;
        }

        pub fn getCursorPosY() f64 {
            return instance.cursor_pos_y;
        }

        pub fn getCursorMode() Cursor.Mode {
            return instance.cursor_mode;
        }

        pub fn setCursor(cursor: *js.platform.Cursor) void {
            js.console.assert(js.platform.is_init, @src());
            if (isPointerLock() or isCursorHidden()) {
                instance.visible_cursor = cursor.*;
            } else {
                instance.cursor = cursor.*;
            }
        }

        pub fn setCursorPosX(x: f64) void {
            instance.cursor_pos_x = x;
        }

        pub fn setCursorPosY(y: f64) void {
            instance.cursor_pos_y = y;
        }

        pub fn setCursorMode(cursor_mode: Cursor.Mode) void {
            instance.cursor_mode = cursor_mode;
        }

        fn isPointerLock() bool {
            js.console.assert(js.platform.is_init, @src());
            return instance.cursor_mode == .disabled;
        }

        fn isCursorHidden() bool {
            js.console.assert(js.platform.is_init, @src());
            return instance.cursor_mode == .hidden;
        }

        fn press(button: MouseButton) void {
            js.console.assert(js.platform.is_init, @src());
            instance.buttons.put(button, .press);
        }

        fn release(button: MouseButton) void {
            js.console.assert(js.platform.is_init, @src());
            instance.buttons.put(button, .release);
        }
    };

    pub const Keyboard = struct {
        var instance: @This() = undefined;

        keys: std.enums.EnumMap(Key, KeyState),

        fn init() void {
            reset();
        }

        fn reset() void {
            instance.keys = .initFull(.release);
        }

        pub fn getKeyState(key: Key) KeyState {
            js.console.assert(js.platform.is_init, @src());
            return instance.keys.get(key) orelse std.debug.panic("{s}.{s}: unknown Key", .{ @typeName(@This()), @src().fn_name });
        }

        pub fn getKeyName(key: Key, scancode: Scancode) [:0]const u8 {
            js.console.assert(js.platform.is_init, @src());
            const input = if (key == .unknown) scancode else Scancode.fromKey(key);
            return @tagName(input);
        }

        fn press(key: Key) void {
            js.console.assert(js.platform.is_init, @src());
            instance.keys.put(key, .press);
        }

        fn release(key: Key) void {
            js.console.assert(js.platform.is_init, @src());
            instance.keys.put(key, .release);
        }

        fn isShiftPressed() bool {
            js.console.assert(js.platform.is_init, @src());
            return getKeyState(.left_shift) != .release or getKeyState(.right_shift) != .release;
        }

        fn isControlPressed() bool {
            js.console.assert(js.platform.is_init, @src());
            return getKeyState(.left_control) != .release or getKeyState(.right_control) != .release;
        }

        fn isAltPressed() bool {
            js.console.assert(js.platform.is_init, @src());
            return getKeyState(.left_alt) != .release or getKeyState(.right_alt) != .release;
        }

        fn isSuperPressed() bool {
            js.console.assert(js.platform.is_init, @src());
            return getKeyState(.left_super) != .release or getKeyState(.right_super) != .release;
        }

        // Here we ignore caps_lock and num_lock modifiers for simplicity
        pub fn computeModifierBits() c_int {
            js.console.assert(js.platform.is_init, @src());
            var bits: c_int = 0;
            if (isShiftPressed()) bits |= @backingInt(Mod.shift);
            if (isControlPressed()) bits |= @backingInt(Mod.control);
            if (isAltPressed()) bits |= @backingInt(Mod.alt);
            if (isSuperPressed()) bits |= @backingInt(Mod.super);
            return bits;
        }
    };

    pub const Event = enum(u32) {
        windowresize,
        windowfocus,
        cursorpos,
        cursorenter,
        mousebutton,
        scroll,
        char,
        key,
    };

    var windowresizeCallback: ?*const fn (f32, f32) void = null;
    var windowfocusCallback: ?*const fn (bool) void = null;
    var cursorenterCallback: ?*const fn (bool) void = null;
    var cursorposCallback: ?*const fn (f32, f32) void = null;
    var mousebuttonCallback: ?*const fn (MouseButton, bool) void = null;
    var scrollCallback: ?*const fn (f32, f32) void = null;
    var charCallback: ?*const fn (js.Uint32) void = null;
    var keyCallback: ?*const fn (Key, Scancode, Action, js.Uint32) void = null;

    fn getCodepointFromKeyboardEvent() js.Uint32 {
        js.console.assert(js.platform.is_init, @src());
        return js.platformKeyboardEventGetCodepoint();
    }

    fn getCodeFromKeyboardEvent() js.String {
        js.console.assert(js.platform.is_init, @src());
        return js.platformKeyboardEventGetCode();
    }

    fn getModifierBitsFromKeyboardEvent() js.Uint32 {
        js.console.assert(js.platform.is_init, @src());
        return js.platformKeyboardEventGetModifierBits();
    }

    fn getButtonFromMouseButtonEvent() c_int {
        js.console.assert(js.platform.is_init, @src());
        return @intCast(js.platformMouseButtonEventGetButton());
    }

    fn getClientXFromMouseMoveEvent() js.Uint32 {
        js.console.assert(js.platform.is_init, @src());
        return js.platformMouseMoveEventGetClientX();
    }

    fn getClientYFromMouseMoveEvent() js.Uint32 {
        js.console.assert(js.platform.is_init, @src());
        return js.platformMouseMoveEventGetClientY();
    }

    fn getDeltaModeFromWheelEvent() DeltaMode {
        js.console.assert(js.platform.is_init, @src());
        return js.platformWheelEventGetDeltaMode();
    }

    fn getDeltaXFromWheelEvent() js.Float32 {
        js.console.assert(js.platform.is_init, @src());
        return js.platformWheelEventGetDeltaX();
    }

    fn getDeltaYFromWheelEvent() js.Float32 {
        js.console.assert(js.platform.is_init, @src());
        return js.platformWheelEventGetDeltaY();
    }

    pub fn listenEvent(comptime event: Event, callback: @TypeOf(@field(@This(), @tagName(event) ++ "Callback"))) void {
        js.console.assert(js.platform.is_init, @src());
        switch (event) {
            .windowresize => Window.listenEvent(.resize),
            .windowfocus => {
                Window.listenEvent(.focus);
                Window.listenEvent(.blur);
            },
            .cursorpos => {
                Canvas.listenEvent(.mousemove);
                Canvas.listenEvent(.mousedown);
                Canvas.listenEvent(.mouseup);
            },
            .cursorenter => {
                Canvas.listenEvent(.mouseenter);
                Canvas.listenEvent(.mouseleave);
            },
            .mousebutton => {
                Canvas.listenEvent(.mousedown);
                Canvas.listenEvent(.mouseup);
            },
            .scroll => Canvas.listenEvent(.wheel),
            .char => Window.listenEvent(.keydown),
            .key => {
                Window.listenEvent(.keydown);
                Window.listenEvent(.keyup);
            },
        }
        @field(@This(), @tagName(event) ++ "Callback") = callback;
    }

    fn onWindowResize() void {
        js.console.assert(js.platform.is_init, @src());
        if (windowresizeCallback) |cb| cb(std.math.lossyCast(f32, Canvas.getWidth()), std.math.lossyCast(f32, Canvas.getHeight()));
    }

    fn onWindowFocus(focused: bool) void {
        js.console.assert(js.platform.is_init, @src());
        if (windowfocusCallback) |cb| cb(focused);
    }

    fn onCursorEnter(entered: bool) void {
        js.console.assert(js.platform.is_init, @src());
        if (cursorenterCallback) |cb| cb(entered);
    }

    fn onCursorPos(x: f32, y: f32) void {
        js.console.assert(js.platform.is_init, @src());
        if (cursorposCallback) |cb| cb(x, y);
    }

    fn onMouseButton(button: MouseButton, pressed: bool) void {
        js.console.assert(js.platform.is_init, @src());
        if (mousebuttonCallback) |cb| cb(button, pressed);
    }

    fn onScroll(xoffset: f32, yoffset: f32) void {
        js.console.assert(js.platform.is_init, @src());
        if (scrollCallback) |cb| cb(xoffset, yoffset);
    }

    fn onChar(codepoint: js.Uint32) void {
        js.console.assert(js.platform.is_init, @src());
        if (charCallback) |cb| {
            if (codepoint != 0) cb(codepoint);
        }
    }

    fn onKey(key: js.platform.Key, scancode: js.platform.Scancode, action: js.platform.Action, mods: js.Uint32) void {
        js.console.assert(js.platform.is_init, @src());
        if (keyCallback) |cb| {
            if (scancode != .unknown) cb(key, scancode, action, mods);
        }
    }

    pub const Window = struct {
        var instance: @This() = undefined;

        const Event = enum(u32) {
            resize,
            focus,
            blur,
            keydown,
            keyup,
        };

        handle: js.Handle,
        focused: bool,
        monitor_scale: js.Float32,

        fn init() void {
            js.console.assert(!js.platform.is_init, @src());
            const handle = js.platformGetWindow();
            js.console.assert(handle != null_handle, @src());
            instance = .{
                .handle = handle,
                .focused = true,
                .monitor_scale = js.platformWindowGetDevicePixelRatio(handle),
            };
            Canvas.init(js.platformWindowGetCanvas(handle));
            Mouse.init();
            Keyboard.init();
        }

        fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn isFocused() bool {
            js.console.assert(isInit(), @src());
            return instance.focused;
        }

        pub fn getMonitorScale() js.Float32 {
            js.console.assert(isInit(), @src());
            return instance.monitor_scale;
        }

        fn onResize() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            Canvas.syncSize();
            onWindowResize();
        }

        fn onFocus() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            instance.focused = true;
            onWindowFocus(instance.focused);
        }

        fn onBlur() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            instance.focused = false;
            Keyboard.reset();
            onWindowFocus(instance.focused);
        }

        fn onKeyDown() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            const codepoint = getCodepointFromKeyboardEvent();
            onChar(codepoint);
            const str: [:0]const u8 = std.mem.span(getCodeFromKeyboardEvent());
            defer gpa.free(str); // Allocated into jsPlatformKeyboardEventGetCode
            const scancode: Scancode = .fromStr(str);
            const key = scancode.toKey();
            Keyboard.press(key);
            onKey(key, scancode, .press, getModifierBitsFromKeyboardEvent());
        }

        fn onKeyUp() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            const str: [:0]const u8 = std.mem.span(getCodeFromKeyboardEvent());
            defer gpa.free(str); // Allocated into jsPlatformKeyboardEventGetCode
            const scancode: Scancode = .fromStr(str);
            const key = scancode.toKey();
            Keyboard.release(key);
            onKey(key, scancode, .release, getModifierBitsFromKeyboardEvent());
        }

        pub fn onEvent(event_type: js.String) void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            defer gpa.free(std.mem.span(event_type)); // Allocated into jsPlatformWindowListenEvent
            switch (std.meta.stringToEnum(js.platform.Window.Event, std.mem.span(event_type)) orelse std.debug.panic("{s}: Unknown js.platform.Window.Event: {s}", .{ @src().fn_name, event_type })) {
                .resize => onResize(),
                .focus => onFocus(),
                .blur => onBlur(),
                .keydown => onKeyDown(),
                .keyup => onKeyUp(),
            }
        }

        fn listenEvent(comptime event: @This().Event) void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            js.platformWindowListenEvent(instance.handle, @tagName(event).ptr, @tagName(event).len);
        }

        pub fn getGpuInstance() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            js.gpu.Instance.init(js.platformWindowGetGpuInstance(instance.handle));
        }
    };

    pub const Canvas = struct {
        var instance: @This() = undefined;

        const Event = enum(u32) {
            mouseup,
            mousedown,
            mousemove,
            mouseenter,
            mouseleave,
            wheel,
        };

        handle: js.Handle = null_handle,
        width: js.Uint32,
        height: js.Uint32,
        left: js.Uint32,
        top: js.Uint32,

        fn init(handle: js.Handle) void {
            js.console.assert(handle != null_handle, @src());
            instance = .{
                .handle = handle,
                .width = undefined,
                .height = undefined,
                .left = undefined,
                .top = undefined,
            };
            syncSize();
        }

        fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn getGpuContext() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            js.gpu.Context.init(js.platformCanvasGetGpuContext(instance.handle));
        }

        pub fn getWidth() js.Uint32 {
            js.console.assert(isInit(), @src());
            return instance.width;
        }

        pub fn getHeight() js.Uint32 {
            js.console.assert(isInit(), @src());
            return instance.height;
        }

        fn syncSize() void {
            js.console.assert(isInit(), @src());
            instance.width = js.platformCanvasGetBoundingClientRectWidth(instance.handle);
            instance.height = js.platformCanvasGetBoundingClientRectHeight(instance.handle);
            instance.left = js.platformCanvasGetBoundingClientRectLeft(instance.handle);
            instance.top = js.platformCanvasGetBoundingClientRectTop(instance.handle);
            js.platformCanvasResize(instance.handle, instance.width, instance.height, Window.getMonitorScale());
        }

        fn transformCoords() struct { f32, f32 } {
            const client_x = getClientXFromMouseMoveEvent();
            const client_y = getClientYFromMouseMoveEvent();
            const dpr = Window.getMonitorScale();
            const x = std.math.lossyCast(f32, client_x - instance.left) * dpr;
            const y = std.math.lossyCast(f32, client_y - instance.top) * dpr;
            return .{ x, y };
        }

        fn onMouseUp() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            const button: MouseButton = .fromDOM(getButtonFromMouseButtonEvent());
            const x, const y = transformCoords();
            Mouse.setCursorPosX(x);
            Mouse.setCursorPosY(y);
            Mouse.release(button);
            onMouseButton(button, false);
            onCursorPos(x, y);
        }

        fn onMouseDown() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            const button: MouseButton = .fromDOM(getButtonFromMouseButtonEvent());
            const x, const y = transformCoords();
            Mouse.setCursorPosX(x);
            Mouse.setCursorPosY(y);
            Mouse.press(button);
            Window.onFocus();
            onMouseButton(button, true);
            onCursorPos(x, y);
        }

        fn onMouseMove() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            const x, const y = transformCoords();
            Mouse.setCursorPosX(x);
            Mouse.setCursorPosY(y);
            onCursorPos(x, y);
        }

        fn onMouseEnter() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            onCursorEnter(true);
        }

        fn onMouseLeave() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            onCursorEnter(false);
        }

        fn onWheel() void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            const multiplier: f32 = switch (getDeltaModeFromWheelEvent()) {
                .pixel => -0.01,
                .line => -1.0 / 3.0,
                .page => -80.0,
            };
            const delta_x = getDeltaXFromWheelEvent();
            const delta_y = getDeltaYFromWheelEvent();
            onScroll(delta_x * multiplier, delta_y * multiplier);
        }

        pub fn onEvent(event_type: js.String) void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            defer gpa.free(std.mem.span(event_type)); // Allocated into jsPlatformCanvasListenEvent
            switch (std.meta.stringToEnum(js.platform.Canvas.Event, std.mem.span(event_type)) orelse std.debug.panic("{s}: Unknown js.platform.Canvas.Event: {s}", .{ @src().fn_name, event_type })) {
                .mouseup => onMouseUp(),
                .mousedown => onMouseDown(),
                .mousemove => onMouseMove(),
                .mouseenter => onMouseEnter(),
                .mouseleave => onMouseLeave(),
                .wheel => onWheel(),
            }
        }

        fn listenEvent(comptime event: @This().Event) void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            js.platformCanvasListenEvent(instance.handle, @tagName(event).ptr, @tagName(event).len);
        }
    };

    pub const Clipboard = struct {
        var instance: @This() = .{};

        handle: js.Handle = null_handle,
        text: [:0]const u8 = "",

        fn init() void {
            const handle = js.platformGetClipboard();
            js.console.assert(handle != null_handle, @src());
            instance = .{
                .handle = handle,
                .text = "",
            };
        }

        fn isInit() bool {
            return instance.handle != null_handle;
        }

        pub fn getText() [:0]const u8 {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            return instance.text;
        }

        pub fn setText(str: [:0]const u8) void {
            js.console.assert(js.platform.is_init, @src());
            js.console.assert(isInit(), @src());
            instance.text = str;
            js.platformClipboardWriteText(instance.handle, str.ptr, str.len);
        }
    };
};
