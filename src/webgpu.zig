const std = @import("std");
const c = @import("c");
const js = @import("js");

var allocator = std.heap.wasm_allocator;

// This WebGPU implementation is minimal. It aims to allow imgui compilation with WebGPU backend on a wasm-freestanding target.
// It is not aimed to be fully implemented.

fn jsBindGroupEntryFromC(c_bind_group_entry: *allowzero const c.WGPUBindGroupEntry) js.gpu.BindGroupEntry {
    if (@intFromPtr(c_bind_group_entry) == 0) std.debug.panic("{s}: c_bind_group_entry is null", .{@src().fn_name});
    const binding = c_bind_group_entry.binding;
    if (@intFromPtr(c_bind_group_entry.buffer) != 0) {
        return .initBuffer(binding, @as(*js.gpu.Buffer, @ptrCast(@alignCast(c_bind_group_entry.buffer))).*, c_bind_group_entry.offset, c_bind_group_entry.size);
    } else if (@intFromPtr(c_bind_group_entry.sampler) != 0) {
        return .initSampler(binding, @as(*js.gpu.Sampler, @ptrCast(@alignCast(c_bind_group_entry.sampler))).*);
    } else if (@intFromPtr(c_bind_group_entry.textureView) != 0) {
        return .initTextureView(binding, @as(*js.gpu.TextureView, @ptrCast(@alignCast(c_bind_group_entry.textureView))).*);
    } else std.debug.panic("{s}: Unknown WGPUBindGroupEntry type", .{@src().fn_name});
}

fn jsBindGroupLayoutEntryFromC(c_bind_group_layout_entry: *allowzero const c.WGPUBindGroupLayoutEntry) js.gpu.BindGroupLayoutEntry {
    if (@intFromPtr(c_bind_group_layout_entry) == 0) std.debug.panic("{s}: c_bind_group_layout_entry is null", .{@src().fn_name});
    const binding = c_bind_group_layout_entry.binding;
    const visibility = c_bind_group_layout_entry.visibility;
    if (c_bind_group_layout_entry.buffer.type == c.WGPUBufferBindingType_Uniform) {
        return .initUniformBuffer(binding, visibility);
    } else if (c_bind_group_layout_entry.texture.viewDimension == c.WGPUTextureViewDimension_2D) {
        return .init2DTexture(binding, visibility);
    } else if (c_bind_group_layout_entry.sampler.type == c.WGPUSamplerBindingType_Filtering) {
        return .initSampler(binding, visibility);
    } else std.debug.panic("{s}: Unknown WGPUBindGroupLayoutEntry type", .{@src().fn_name});
}

fn jsVertexFormatFromC(c_vertex_format: u32) js.gpu.VertexFormat {
    return @fromBackingInt(c_vertex_format);
}

fn jsVertexStepModeFromC(c_vertex_step_mode: u32) js.gpu.VertexStepMode {
    return @fromBackingInt(c_vertex_step_mode);
}

fn jsTextureFormatFromC(c_texture_format: u32) js.gpu.TextureFormat {
    return @fromBackingInt(c_texture_format);
}

fn jsBlendOperationFromC(c_blend_operation: u32) js.gpu.BlendOperation {
    return @fromBackingInt(c_blend_operation);
}

fn jsBlendFactorFromC(c_blend_factor: u32) js.gpu.BlendFactor {
    return @fromBackingInt(c_blend_factor);
}

fn jsIndexFormatFromC(c_index_format: u32) js.gpu.IndexFormat {
    return @fromBackingInt(c_index_format);
}

fn jsPrimitiveTopologyFromC(c_primitive_topology: u32) js.gpu.PrimitiveTopology {
    return @fromBackingInt(c_primitive_topology);
}

fn jsFrontFaceFromC(c_front_face: u32) js.gpu.FrontFace {
    return @fromBackingInt(c_front_face);
}

fn jsCullModeFromC(c_cull_mode: u32) js.gpu.CullMode {
    return @fromBackingInt(c_cull_mode);
}

fn jsVertexAttributeFromC(c_vertex_attribute: *allowzero const c.WGPUVertexAttribute) js.gpu.VertexAttribute {
    if (@intFromPtr(c_vertex_attribute) == 0) std.debug.panic("{s}: c_vertex_attribute is null", .{@src().fn_name});
    const vertex_format = jsVertexFormatFromC(c_vertex_attribute.format);
    return .{
        .shader_location = c_vertex_attribute.shaderLocation,
        .vertex_format_ptr = @tagName(vertex_format).ptr,
        .vertex_format_len = @tagName(vertex_format).len,
        .offset = c_vertex_attribute.offset,
    };
}

fn jsVertexBufferLayoutFromC(a: std.mem.Allocator, c_vertex_buffer_layout: *allowzero const c.WGPUVertexBufferLayout) js.gpu.VertexBufferLayout {
    if (@intFromPtr(c_vertex_buffer_layout) == 0) std.debug.panic("{s}: c_vertex_buffer_layout is null", .{@src().fn_name});
    var vertex_attributes = a.alloc(js.gpu.VertexAttribute, c_vertex_buffer_layout.attributeCount) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    for (0..c_vertex_buffer_layout.attributeCount) |i| vertex_attributes[i] = jsVertexAttributeFromC(&c_vertex_buffer_layout.attributes[i]);
    const step_mode = jsVertexStepModeFromC(c_vertex_buffer_layout.stepMode);
    return .{
        .array_stride = c_vertex_buffer_layout.arrayStride,
        .step_mode_ptr = @tagName(step_mode).ptr,
        .step_mode_len = @tagName(step_mode).len,
        .vertex_attributes_ptr = @intFromPtr(vertex_attributes.ptr),
        .vertex_attributes_len = vertex_attributes.len,
    };
}

fn jsBlendComponentFromC(c_blend_component: *allowzero const c.WGPUBlendComponent) js.gpu.BlendComponent {
    if (@intFromPtr(c_blend_component) == 0) std.debug.panic("{s}: c_blend_component is null", .{@src().fn_name});
    return .{
        .operation = jsBlendOperationFromC(c_blend_component.operation),
        .src_factor = jsBlendFactorFromC(c_blend_component.srcFactor),
        .dst_factor = jsBlendFactorFromC(c_blend_component.dstFactor),
    };
}

fn jsColorTargetStateFromC(c_color_target_state: *allowzero const c.WGPUColorTargetState) js.gpu.ColorTargetState {
    if (@intFromPtr(c_color_target_state) == 0) std.debug.panic("{s}: c_color_target_state is null", .{@src().fn_name});
    return js.gpu.ColorTargetState.init(jsTextureFormatFromC(c_color_target_state.format), jsBlendComponentFromC(&c_color_target_state.blend.*.color), jsBlendComponentFromC(&c_color_target_state.blend.*.alpha), c_color_target_state.writeMask);
}

fn jsVertexStateFromC(a: std.mem.Allocator, c_vertex_state: *allowzero const c.WGPUVertexState) js.gpu.VertexState {
    if (@intFromPtr(c_vertex_state) == 0) std.debug.panic("{s}: c_vertex_state is null", .{@src().fn_name});
    var vertex_buffer_layouts = a.alloc(js.gpu.VertexBufferLayout, c_vertex_state.bufferCount) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    for (0..c_vertex_state.bufferCount) |i| vertex_buffer_layouts[i] = jsVertexBufferLayoutFromC(a, &c_vertex_state.buffers[i]);
    return .init(@as(*js.gpu.ShaderModule, @ptrCast(@alignCast(c_vertex_state.module))).*, vertex_buffer_layouts);
}

fn jsFragmentStateFromC(a: std.mem.Allocator, c_fragment_state: *allowzero const c.WGPUFragmentState) js.gpu.FragmentState {
    if (@intFromPtr(c_fragment_state) == 0) std.debug.panic("{s}: c_fragment_state is null", .{@src().fn_name});
    var color_target_states = a.alloc(js.gpu.ColorTargetState, c_fragment_state.targetCount) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    for (0..c_fragment_state.targetCount) |i| color_target_states[i] = jsColorTargetStateFromC(&c_fragment_state.targets[i]);
    return .init(@as(*js.gpu.ShaderModule, @ptrCast(@alignCast(c_fragment_state.module))).*, color_target_states);
}

fn jsPrimitiveStateFromC(c_primitive_state: *allowzero const c.WGPUPrimitiveState) js.gpu.PrimitiveState {
    if (@intFromPtr(c_primitive_state) == 0) std.debug.panic("{s}: c_primitive_state is null", .{@src().fn_name});
    const primitive_topology = jsPrimitiveTopologyFromC(c_primitive_state.topology);
    const front_face = jsFrontFaceFromC(c_primitive_state.frontFace);
    const cull_mode = jsCullModeFromC(c_primitive_state.cullMode);
    const index_format = jsIndexFormatFromC(c_primitive_state.stripIndexFormat);
    return .{
        .topology_ptr = @tagName(primitive_topology).ptr,
        .topology_len = @tagName(primitive_topology).len,
        .front_face_ptr = @tagName(front_face).ptr,
        .front_face_len = @tagName(front_face).len,
        .cull_mode_ptr = @tagName(cull_mode).ptr,
        .cull_mode_len = @tagName(cull_mode).len,
        .strip_index_format_ptr = index_format.tagName().ptr,
        .strip_index_format_len = index_format.tagName().len,
    };
}

fn jsAddressModeFromC(c_address_mode: u32) js.gpu.AddressMode {
    return @fromBackingInt(c_address_mode);
}

fn jsFilterModeFromC(c_filter_mode: u32) js.gpu.FilterMode {
    return @fromBackingInt(c_filter_mode);
}

fn jsMipmapFilterModeFromC(c_mipmap_filter_mode: u32) js.gpu.MipmapFilterMode {
    return @fromBackingInt(c_mipmap_filter_mode);
}

fn jsSamplerDescriptorFromC(c_descriptor: *const c.WGPUSamplerDescriptor) js.gpu.SamplerDescriptor {
    const address_mode_u = jsAddressModeFromC(c_descriptor.addressModeU);
    const address_mode_v = jsAddressModeFromC(c_descriptor.addressModeV);
    const address_mode_w = jsAddressModeFromC(c_descriptor.addressModeW);
    const mag_filter = jsFilterModeFromC(c_descriptor.magFilter);
    const min_filter = jsFilterModeFromC(c_descriptor.minFilter);
    const mipmap_filter = jsMipmapFilterModeFromC(c_descriptor.mipmapFilter);
    return .{
        .address_mode_u_ptr = @tagName(address_mode_u).ptr,
        .address_mode_u_len = @tagName(address_mode_u).len,
        .address_mode_v_ptr = @tagName(address_mode_v).ptr,
        .address_mode_v_len = @tagName(address_mode_v).len,
        .address_mode_w_ptr = @tagName(address_mode_w).ptr,
        .address_mode_w_len = @tagName(address_mode_w).len,
        .mag_filter_ptr = @tagName(mag_filter).ptr,
        .mag_filter_len = @tagName(mag_filter).len,
        .min_filter_ptr = @tagName(min_filter).ptr,
        .min_filter_len = @tagName(min_filter).len,
        .mipmap_filter_ptr = @tagName(mipmap_filter).ptr,
        .mipmap_filter_len = @tagName(mipmap_filter).len,
        .max_anisotropy = c_descriptor.maxAnisotropy,
    };
}

fn jsTextureDimensionFromC(c_texture_dimension: c.WGPUTextureDimension) js.gpu.TextureDimension {
    return @fromBackingInt(c_texture_dimension);
}

fn jsTextureDescriptorFromC(c_descriptor: *const c.WGPUTextureDescriptor) js.gpu.TextureDescriptor {
    return .init(
        jsTextureFormatFromC(c_descriptor.format),
        jsTextureDimensionFromC(c_descriptor.dimension),
        c_descriptor.size.width,
        c_descriptor.size.height,
        c_descriptor.size.depthOrArrayLayers,
        c_descriptor.sampleCount,
        c_descriptor.mipLevelCount,
        c_descriptor.usage,
    );
}

fn jsTextureViewDimensionFromC(c_texture_view_dimension: c.WGPUTextureViewDimension) js.gpu.TextureViewDimension {
    return @fromBackingInt(c_texture_view_dimension);
}

fn jsTextureAspectFromC(c_texture_aspect: c.WGPUTextureAspect) js.gpu.TextureAspect {
    return @fromBackingInt(c_texture_aspect);
}

fn jsTextureViewDescriptorFromC(c_descriptor: *const c.WGPUTextureViewDescriptor) js.gpu.TextureViewDescriptor {
    return .init(
        jsTextureFormatFromC(c_descriptor.format),
        jsTextureViewDimensionFromC(c_descriptor.dimension),
        jsTextureAspectFromC(c_descriptor.aspect),
        c_descriptor.baseMipLevel,
        c_descriptor.mipLevelCount,
        c_descriptor.baseArrayLayer,
        c_descriptor.arrayLayerCount,
    );
}

fn jsTexelCopyTextureInfoFromC(c_info: *const c.WGPUTexelCopyTextureInfo) js.gpu.TexelCopyTextureInfo {
    return .init(@as(*js.gpu.Texture, @ptrCast(@alignCast(c_info.texture))).*, c_info.mipLevel, c_info.origin.x, c_info.origin.y, c_info.origin.z, jsTextureAspectFromC(c_info.aspect));
}

fn jsTexelCopyBufferLayoutFromC(c_texel_copy_buffer_layout: *const c.WGPUTexelCopyBufferLayout) js.gpu.TexelCopyBufferLayout {
    return .{
        .offset = c_texel_copy_buffer_layout.offset,
        .bytes_per_row = c_texel_copy_buffer_layout.bytesPerRow,
        .rows_per_image = c_texel_copy_buffer_layout.rowsPerImage,
    };
}

fn jsExtent3DFromC(c_extent_3d: *const c.WGPUExtent3D) js.gpu.Extent3D {
    return .{
        .width = c_extent_3d.width,
        .height = c_extent_3d.height,
        .depth_or_array_layers = c_extent_3d.depthOrArrayLayers,
    };
}

fn jsColorFromC(c_color: *const c.WGPUColor) js.gpu.Color {
    return .{
        .r = c_color.r,
        .g = c_color.g,
        .b = c_color.b,
        .a = c_color.a,
    };
}

fn jsStringViewFromStr(str: []const u8) c.WGPUStringView {
    return .{
        .data = str.ptr,
        .length = str.len,
    };
}

pub fn adapterGetInfo(c_adapter: c.WGPUAdapter, info: *c.WGPUAdapterInfo) callconv(.c) c.WGPUStatus {
    const adapter: *js.gpu.Adapter = @ptrCast(@alignCast(c_adapter));
    info.* = .{
        .description = jsStringViewFromStr(adapter.info.description),
        .vendor = jsStringViewFromStr(adapter.info.vendor),
        .vendorID = adapter.info.vendor_id,
        .architecture = jsStringViewFromStr(adapter.info.architecture),
        .device = jsStringViewFromStr(adapter.info.device),
        .deviceID = adapter.info.device_id,
        .adapterType = @backingInt(adapter.info.adapter_type),
        .backendType = @backingInt(adapter.info.backend_type),
    };
    return c.WGPUStatus_Success;
}

pub fn adapterInfoFreeMembers(adapter_info: c.WGPUAdapterInfo) callconv(.c) void {
    _ = adapter_info;
}

pub fn bindGroupLayoutRelease(c_bind_group_layout: c.WGPUBindGroupLayout) callconv(.c) void {
    var bind_group_layout: *js.gpu.BindGroupLayout = @ptrCast(@alignCast(c_bind_group_layout));
    bind_group_layout.deinit();
    allocator.destroy(bind_group_layout);
}

pub fn bindGroupRelease(c_bind_group: c.WGPUBindGroup) callconv(.c) void {
    var bind_group: *js.gpu.BindGroup = @ptrCast(@alignCast(c_bind_group));
    bind_group.deinit();
    allocator.destroy(bind_group);
}

pub fn bufferDestroy(c_buffer: c.WGPUBuffer) callconv(.c) void {
    var buffer: *js.gpu.Buffer = @ptrCast(@alignCast(c_buffer));
    buffer.destroy();
}

pub fn bufferRelease(c_buffer: c.WGPUBuffer) callconv(.c) void {
    var buffer: *js.gpu.Buffer = @ptrCast(@alignCast(c_buffer));
    buffer.deinit();
    allocator.destroy(buffer);
}

pub fn deviceCreateBindGroup(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUBindGroupDescriptor) callconv(.c) c.WGPUBindGroup {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        var bind_group_entries = allocator.alloc(js.gpu.BindGroupEntry, c_descriptor.entryCount) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        defer allocator.free(bind_group_entries);
        for (0..c_descriptor.entryCount) |i| bind_group_entries[i] = jsBindGroupEntryFromC(&c_descriptor.entries[i]);
        const bind_group = allocator.create(js.gpu.BindGroup) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        bind_group.* = js.gpu.Device.createBindGroup(@as(*js.gpu.BindGroupLayout, @ptrCast(@alignCast(c_descriptor.layout))).*, bind_group_entries);
        return @ptrCast(@alignCast(bind_group));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceCreateBindGroupLayout(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUBindGroupLayoutDescriptor) callconv(.c) c.WGPUBindGroupLayout {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        var bind_group_layout_entries = allocator.alloc(js.gpu.BindGroupLayoutEntry, c_descriptor.entryCount) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        defer allocator.free(bind_group_layout_entries);
        for (0..c_descriptor.entryCount) |i| bind_group_layout_entries[i] = jsBindGroupLayoutEntryFromC(&c_descriptor.entries[i]);
        const bind_group_layout = allocator.create(js.gpu.BindGroupLayout) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        bind_group_layout.* = js.gpu.Device.createBindGroupLayout(bind_group_layout_entries);
        return @ptrCast(@alignCast(bind_group_layout));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceCreateBuffer(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUBufferDescriptor) callconv(.c) c.WGPUBuffer {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        const buffer = allocator.create(js.gpu.Buffer) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        buffer.* = js.gpu.Device.createBuffer(c_descriptor.size, c_descriptor.usage);
        return @ptrCast(@alignCast(buffer));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceCreatePipelineLayout(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUPipelineLayoutDescriptor) callconv(.c) c.WGPUPipelineLayout {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        const pipeline_layout = allocator.create(js.gpu.PipelineLayout) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        var bind_group_layouts = allocator.alloc(js.gpu.BindGroupLayout, c_descriptor.bindGroupLayoutCount) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        defer allocator.free(bind_group_layouts);
        for (0..c_descriptor.bindGroupLayoutCount) |i| {
            bind_group_layouts[i] = @as(*js.gpu.BindGroupLayout, @ptrCast(@alignCast(c_descriptor.bindGroupLayouts[i]))).*;
        }
        pipeline_layout.* = js.gpu.Device.createPipelineLayout(bind_group_layouts);
        return @ptrCast(@alignCast(pipeline_layout));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

// WGPUMultisampleState and WGPUDepthStencilState are ignored because:
// 1) we don't use it,
// 2) ImGui WGPU backend doesn't use it if we don't use it
pub fn deviceCreateRenderPipeline(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPURenderPipelineDescriptor) callconv(.c) c.WGPURenderPipeline {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        const vertex_state = jsVertexStateFromC(allocator, &c_descriptor.vertex);
        defer {
            const vertex_buffer_layouts_ptr: [*]js.gpu.VertexBufferLayout = @ptrFromInt(vertex_state.buffers_ptr);
            var vertex_attributes_ptr: [*]js.gpu.VertexAttribute = undefined;
            for (0..vertex_state.buffers_len) |i| {
                vertex_attributes_ptr = @ptrFromInt(vertex_buffer_layouts_ptr[i].vertex_attributes_ptr);
                allocator.free(vertex_attributes_ptr[0..vertex_buffer_layouts_ptr[i].vertex_attributes_len]);
            }
            allocator.free(vertex_buffer_layouts_ptr[0..vertex_state.buffers_len]);
        }

        const fragment_state = jsFragmentStateFromC(allocator, c_descriptor.fragment);
        defer {
            const color_target_states_ptr: [*]js.gpu.ColorTargetState = @ptrFromInt(fragment_state.targets_ptr);
            allocator.free(color_target_states_ptr[0..fragment_state.targets_len]);
        }
        const primitive_state = jsPrimitiveStateFromC(&c_descriptor.primitive);
        const render_pipeline = allocator.create(js.gpu.RenderPipeline) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        render_pipeline.* = js.gpu.Device.createRenderPipeline(@as(*js.gpu.PipelineLayout, @ptrCast(@alignCast(c_descriptor.layout))).*, vertex_state, fragment_state, primitive_state);
        return @ptrCast(@alignCast(render_pipeline));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceCreateSampler(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUSamplerDescriptor) callconv(.c) c.WGPUSampler {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        const descriptor = jsSamplerDescriptorFromC(c_descriptor);
        const sampler = allocator.create(js.gpu.Sampler) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        sampler.* = js.gpu.Device.createSampler(descriptor);
        return @ptrCast(@alignCast(sampler));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceCreateShaderModule(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUShaderModuleDescriptor) callconv(.c) c.WGPUShaderModule {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        var code: []const u8 = "";
        switch (c_descriptor.nextInChain.*.sType) {
            c.WGPUSType_ShaderSourceWGSL => {
                const source: *c.WGPUShaderSourceWGSL = @ptrCast(@alignCast(c_descriptor.nextInChain));
                code = if (source.code.length == c.WGPU_STRLEN) std.mem.span(source.code.data) else source.code.data[0..source.code.length];
            },
            c.WGPUSType_ShaderSourceSPIRV => {},
            else => std.debug.panic("{s}: Unknown WGPUSType value", .{@src().fn_name}),
        }
        const shader_module = allocator.create(js.gpu.ShaderModule) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        shader_module.* = js.gpu.Device.createShaderModule(code);
        return @ptrCast(@alignCast(shader_module));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceCreateTexture(c_device: c.WGPUDevice, c_descriptor_opt: ?*const c.WGPUTextureDescriptor) callconv(.c) c.WGPUTexture {
    _ = c_device;
    if (c_descriptor_opt) |c_descriptor| {
        const descriptor = jsTextureDescriptorFromC(c_descriptor);
        const texture = allocator.create(js.gpu.Texture) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        texture.* = js.gpu.Device.createTexture(descriptor);
        return @ptrCast(@alignCast(texture));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn deviceGetQueue(c_device: c.WGPUDevice) callconv(.c) c.WGPUQueue {
    _ = c_device;
    return null;
}

// Not implemented: because this isn't a mandatory feature for the WebGPU imgui backend and I didn't find a satisfying way to implement C Future and Javascript Async/Promise scheduling
pub fn devicePopErrorScope(c_device: c.WGPUQueue, callback_info: c.WGPUPopErrorScopeCallbackInfo) callconv(.c) c.WGPUFuture {
    _ = .{ c_device, callback_info };
    return .{ .id = 0 };
}

// Not implemented: because this isn't a mandatory feature for the WebGPU imgui backend and I didn't find a satisfying way to implement C Future and Javascript Async/Promise scheduling
pub fn devicePushErrorScope(c_device: c.WGPUQueue, filter: c.WGPUErrorFilter) callconv(.c) void {
    _ = .{ c_device, filter };
}

pub fn pipelineLayoutRelease(c_pipeline_layout: c.WGPUPipelineLayout) callconv(.c) void {
    var pipeline_layout: *js.gpu.PipelineLayout = @ptrCast(@alignCast(c_pipeline_layout));
    pipeline_layout.deinit();
    allocator.destroy(pipeline_layout);
}

// Not implemented: we don't need to release the queue here
pub fn queueRelease(c_queue: c.WGPUQueue) callconv(.c) void {
    _ = c_queue;
}

pub fn queueWriteBuffer(c_queue: c.WGPUQueue, c_buffer: c.WGPUBuffer, buffer_offset: u64, c_data: ?*const anyopaque, size: usize) callconv(.c) void {
    _ = c_queue;
    js.gpu.Queue.writeBuffer(u8, @as(*js.gpu.Buffer, @ptrCast(@alignCast(c_buffer))).*, buffer_offset, @as([*]const u8, @ptrCast(c_data))[0..size], 0, size);
}

pub fn queueWriteTexture(c_queue: c.WGPUQueue, destination_opt: ?*const c.WGPUTexelCopyTextureInfo, c_data: ?*const anyopaque, data_size: usize, c_data_layout_opt: ?*const c.WGPUTexelCopyBufferLayout, write_size_opt: ?*const c.WGPUExtent3D) callconv(.c) void {
    _ = c_queue;
    if (destination_opt) |destination| {
        if (c_data_layout_opt) |c_data_layout| {
            if (write_size_opt) |write_size| {
                const info = jsTexelCopyTextureInfoFromC(destination);
                const data_layout = jsTexelCopyBufferLayoutFromC(c_data_layout);
                const size = jsExtent3DFromC(write_size);
                js.gpu.Queue.writeTexture(info, @as([*]const u8, @ptrCast(c_data))[0..data_size], data_layout, size);
            } else std.debug.panic("{s}: write_size is null", .{@src().fn_name});
        } else std.debug.panic("{s}: c_data_layout is null", .{@src().fn_name});
    } else std.debug.panic("{s}: destination is null", .{@src().fn_name});
}

pub fn renderPassEncoderDrawIndexed(c_render_pass_encoder: c.WGPURenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    render_pass_encoder.drawIndexed(index_count, instance_count, first_index, base_vertex, first_instance);
}

pub fn renderPassEncoderSetBindGroup(c_render_pass_encoder: c.WGPURenderPassEncoder, group_index: u32, c_group: c.WGPUBindGroup, dynamic_offset_count: usize, c_dynamic_offsets_opt: ?[*]const u32) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    render_pass_encoder.setBindGroup(group_index, @as(*js.gpu.BindGroup, @ptrCast(@alignCast(c_group))).*, if (c_dynamic_offsets_opt) |c_dynamic_offsets| c_dynamic_offsets[0..dynamic_offset_count] else &.{});
}

pub fn renderPassEncoderSetBlendConstant(c_render_pass_encoder: c.WGPURenderPassEncoder, c_color_opt: ?*const c.WGPUColor) callconv(.c) void {
    if (c_color_opt) |c_color| {
        const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
        const color = jsColorFromC(c_color);
        render_pass_encoder.setBlendConstant(color);
    } else std.debug.panic("{s}: c_color is null", .{@src().fn_name});
}

pub fn renderPassEncoderSetIndexBuffer(c_render_pass_encoder: c.WGPURenderPassEncoder, c_buffer: c.WGPUBuffer, c_index_format: c.WGPUIndexFormat, offset: u64, size: u64) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    const index_format = jsIndexFormatFromC(c_index_format);
    render_pass_encoder.setIndexBuffer(@as(*js.gpu.Buffer, @ptrCast(@alignCast(c_buffer))).*, index_format, offset, size);
}

pub fn renderPassEncoderSetPipeline(c_render_pass_encoder: c.WGPURenderPassEncoder, c_render_pipeline: c.WGPURenderPipeline) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    render_pass_encoder.setPipeline(@as(*js.gpu.RenderPipeline, @ptrCast(@alignCast(c_render_pipeline))).*);
}

pub fn renderPassEncoderSetScissorRect(c_render_pass_encoder: c.WGPURenderPassEncoder, x: u32, y: u32, width: u32, height: u32) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    render_pass_encoder.setScissorRect(x, y, width, height);
}

pub fn renderPassEncoderSetVertexBuffer(c_render_pass_encoder: c.WGPURenderPassEncoder, slot: u32, c_buffer: c.WGPUBuffer, offset: u64, size: u64) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    render_pass_encoder.setVertexBuffer(slot, @as(*js.gpu.Buffer, @ptrCast(@alignCast(c_buffer))).*, offset, size);
}

pub fn renderPassEncoderSetViewport(c_render_pass_encoder: c.WGPURenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) callconv(.c) void {
    const render_pass_encoder: *js.gpu.RenderPassEncoder = @ptrCast(@alignCast(c_render_pass_encoder));
    render_pass_encoder.setViewport(x, y, width, height, min_depth, max_depth);
}

pub fn renderPipelineRelease(c_render_pipeline: c.WGPURenderPipeline) callconv(.c) void {
    var render_pipeline: *js.gpu.RenderPipeline = @ptrCast(@alignCast(c_render_pipeline));
    render_pipeline.deinit();
    allocator.destroy(render_pipeline);
}

pub fn samplerRelease(c_sampler: c.WGPUSampler) callconv(.c) void {
    var sampler: *js.gpu.Sampler = @ptrCast(@alignCast(c_sampler));
    sampler.deinit();
    allocator.destroy(sampler);
}

pub fn shaderModuleRelease(c_shader_module: c.WGPUShaderModule) callconv(.c) void {
    var shader_module: *js.gpu.ShaderModule = @ptrCast(@alignCast(c_shader_module));
    shader_module.deinit();
    allocator.destroy(shader_module);
}

pub fn textureCreateView(c_texture: c.WGPUTexture, c_descriptor_opt: ?*const c.WGPUTextureViewDescriptor) callconv(.c) c.WGPUTextureView {
    if (c_descriptor_opt) |c_descriptor| {
        const texture: *js.gpu.Texture = @ptrCast(@alignCast(c_texture));
        const descriptor = jsTextureViewDescriptorFromC(c_descriptor);
        const texture_view = allocator.create(js.gpu.TextureView) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
        texture_view.* = texture.createView(descriptor, .{
            .mip_level_count = false,
            .array_layer_count = false,
        });
        return @ptrCast(@alignCast(texture_view));
    } else std.debug.panic("{s}: descriptor is null", .{@src().fn_name});
}

pub fn textureRelease(c_texture: c.WGPUTexture) callconv(.c) void {
    var texture: *js.gpu.Texture = @ptrCast(@alignCast(c_texture));
    texture.deinit();
    allocator.destroy(texture);
}

pub fn textureViewRelease(c_texture_view: c.WGPUTextureView) callconv(.c) void {
    var texture_view: *js.gpu.TextureView = @ptrCast(@alignCast(c_texture_view));
    texture_view.deinit();
    allocator.destroy(texture_view);
}
