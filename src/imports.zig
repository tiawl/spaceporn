const js = @This();
const std = @import("std");

// js types
pub const StringPtr = [*]const u8;
pub const String = [*:0]const u8;
pub const Boolean = bool;
pub const Int32 = i32;
pub const Uint32 = u32;
pub const BigUint64 = u64;
pub const Float32 = f32;
pub const Float64 = f64;
pub const Pointer = js.Uint32;
pub const Handle = js.Uint32;
pub const Flags = js.BigUint64;
pub const Size = js.BigUint64;
pub const Offset = js.BigUint64;

pub const null_handle: js.Handle = std.math.minInt(js.Handle);

pub const FlushMode = enum(js.Uint32) {
    normal = std.math.minInt(js.Uint32),
    dev_null,
    js_err,
    zig_err,
    zig_panic,
    zig_assertion_failure,
};

pub const GpuCallback = enum(js.Uint32) {
    null_handle = null_handle,
    request_adapter,
    request_device,
    pop_error_scope,
};

extern "env" fn jsConsoleWrite(js.StringPtr, js.Uint32) void;
extern "env" fn jsConsoleFlush(FlushMode) void;
extern "env" fn jsRequestAnimationFrame() void;
extern "env" fn jsTimeNow() js.Float64;
pub extern "env" fn jsGpuGetAdapter() js.Handle;
pub extern "env" fn jsGpuGetDevice() js.Handle;
pub extern "env" fn jsGpuSurfaceGetWidth(js.Handle) js.Uint32;
pub extern "env" fn jsGpuSurfaceGetHeight(js.Handle) js.Uint32;
pub extern "env" fn jsGpuSurfaceGetContext(js.Handle) js.Handle;
pub extern "env" fn jsGpuSurfaceResize(js.Handle, js.Uint32, js.Uint32) void;
pub extern "env" fn jsGpuContextConfigure(js.Handle, js.Handle, js.StringPtr, js.Uint32) void;
pub extern "env" fn jsGpuContextGetCurrentTexture(js.Handle) js.Handle;
pub extern "env" fn jsGpuRelease(js.Handle) void;
pub extern "env" fn jsGpuInstanceRequestAdapter(js.Handle, js.GpuCallback) void;
pub extern "env" fn jsGpuInstanceGetPreferredSurfaceFormat(js.Handle) js.String;
pub extern "env" fn jsGpuAdapterRequestDevice(js.Handle, js.GpuCallback) void;
pub extern "env" fn jsGpuDeviceCreateShaderModule(js.Handle, js.StringPtr, js.Uint32) js.Handle;
pub extern "env" fn jsGpuDeviceCreatePipelineLayout(js.Handle, js.Pointer, js.Uint32) js.Handle;
pub extern "env" fn jsGpuDeviceCreateRenderPipeline(js.Handle, js.Handle, js.Pointer, js.Pointer, js.Pointer) js.Handle;
pub extern "env" fn jsGpuDeviceCreateCommandEncoder(js.Handle) js.Handle;
pub extern "env" fn jsGpuDeviceCreateTexture(js.Handle, js.Pointer) js.Handle;
pub extern "env" fn jsGpuDeviceCreateBuffer(js.Handle, js.Size, js.Flags) js.Handle;
pub extern "env" fn jsGpuDestroyBuffer(buffer_handle: js.Handle) void;
pub extern "env" fn jsGpuDeviceCreateBindGroup(js.Handle, js.Handle, js.Pointer, js.Uint32) js.Handle;
pub extern "env" fn jsGpuDeviceCreateBindGroupLayout(js.Handle, js.Pointer, js.Uint32) js.Handle;
pub extern "env" fn jsGpuDeviceCreateSampler(js.Handle, js.Pointer) js.Handle;
pub extern "env" fn jsGpuDevicePushErrorScope(js.Handle, js.StringPtr, js.Uint32) void;
pub extern "env" fn jsGpuDevicePopErrorScope(js.Handle, js.GpuCallback) void;
pub extern "env" fn jsGpuDeviceThrowErrorScope(js.Handle) void;
pub extern "env" fn jsGpuDeviceGetQueue(js.Handle) js.Handle;
pub extern "env" fn jsGpuTextureGetWidth(js.Handle) js.Uint32;
pub extern "env" fn jsGpuTextureGetHeight(js.Handle) js.Uint32;
pub extern "env" fn jsGpuTextureGetDepthOrArrayLayers(js.Handle) js.Uint32;
pub extern "env" fn jsGpuTextureGetMipLevelCount(js.Handle) js.Uint32;
pub extern "env" fn jsGpuTextureGetFormat(js.Handle) js.String;
pub extern "env" fn jsGpuTextureGetDimension(js.Handle) js.String;
pub extern "env" fn jsGpuTextureCreateView(js.Handle, js.Pointer) js.Handle;
pub extern "env" fn jsGpuCommandEncoderBeginRenderPass(js.Handle, js.Handle, js.Pointer) js.Handle;
pub extern "env" fn jsGpuCommandEncoderFinish(js.Handle) js.Handle;
pub extern "env" fn jsGpuRenderPassEncoderSetPipeline(js.Handle, js.Handle) void;
pub extern "env" fn jsGpuRenderPassEncoderSetBindGroup(js.Handle, js.Uint32, js.Handle, js.Pointer, js.Uint32) void;
pub extern "env" fn jsGpuRenderPassEncoderSetVertexBuffer(js.Handle, js.Uint32, js.Handle, js.Offset, js.Size) void;
pub extern "env" fn jsGpuRenderPassEncoderSetIndexBuffer(js.Handle, js.Handle, js.StringPtr, js.Uint32, js.Offset, js.Size) void;
pub extern "env" fn jsGpuRenderPassEncoderSetScissorRect(js.Handle, js.Uint32, js.Uint32, js.Uint32, js.Uint32) void;
pub extern "env" fn jsGpuRenderPassEncoderSetViewport(js.Handle, js.Float32, js.Float32, js.Float32, js.Float32, js.Float32, js.Float32) void;
pub extern "env" fn jsGpuRenderPassEncoderSetBlendConstant(js.Handle, js.Pointer) void;
pub extern "env" fn jsGpuRenderPassEncoderDrawIndexed(js.Handle, js.Uint32, js.Uint32, js.Uint32, js.Int32, js.Uint32) void;
pub extern "env" fn jsGpuRenderPassEncoderEnd(js.Handle) void;
pub extern "env" fn jsGpuQueueSubmit(js.Handle, js.Pointer, js.Uint32) void;
pub extern "env" fn jsGpuQueueWriteBuffer(js.Handle, js.Handle, js.Offset, js.StringPtr, js.Uint32, js.Offset, js.Size) void;
pub extern "env" fn jsGpuQueueWriteTexture(js.Handle, js.Pointer, js.StringPtr, js.Uint32, js.Pointer, js.Pointer) void;
pub extern "env" fn jsPlatformGetWindow() js.Handle;
pub extern "env" fn jsPlatformWindowGetGpuSurface(js.Handle) js.Handle;
pub extern "env" fn jsPlatformWindowGetGpuInstance(js.Handle) js.Handle;
pub extern "env" fn jsPlatformWindowListenEvent(js.Handle, js.StringPtr, js.Uint32) void;
pub extern "env" fn jsPlatformWindowGetDevicePixelRatio(js.Handle) js.Float32;
pub extern "env" fn jsPlatformGetClipboard() js.Handle;
pub extern "env" fn jsPlatformClipboardWriteText(js.Handle, js.StringPtr, js.Uint32) void;

pub const consoleWrite = jsConsoleWrite;
pub const consoleFlush = jsConsoleFlush;
pub const requestAnimationFrame = jsRequestAnimationFrame;
pub const timeNow = jsTimeNow;
