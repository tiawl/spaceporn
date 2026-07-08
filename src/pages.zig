const std = @import("std");
const c = @import("c");
const js = @import("js");
const shader = @import("shader");

pub const std_options_debug_io: std.Io = std.Io.failing;
pub const panic = std.debug.FullPanic(js.console.panic);
pub const std_options: std.Options = .{
    .allow_stack_tracing = true, // currently useless for wasm target
};
var gpa = std.heap.wasm_allocator;

export fn sizeOfBindGroupEntry() js.BigUint64 {
    return @sizeOf(js.gpu.BindGroupEntry);
}

export fn sizeOfBindGroupLayoutEntry() js.BigUint64 {
    return @sizeOf(js.gpu.BindGroupLayoutEntry);
}

export fn sizeOfColor() js.BigUint64 {
    return @sizeOf(js.gpu.Color);
}

export fn sizeOfColorTargetState() js.BigUint64 {
    return @sizeOf(js.gpu.ColorTargetState);
}

export fn sizeOfExtent3D() js.BigUint64 {
    return @sizeOf(js.gpu.Extent3D);
}

export fn sizeOfFragmentState() js.BigUint64 {
    return @sizeOf(js.gpu.FragmentState);
}

export fn sizeOfPrimitiveState() js.BigUint64 {
    return @sizeOf(js.gpu.PrimitiveState);
}

export fn sizeOfRenderPassDescriptor() js.BigUint64 {
    return @sizeOf(js.gpu.RenderPassDescriptor);
}

export fn sizeOfSamplerDescriptor() js.BigUint64 {
    return @sizeOf(js.gpu.SamplerDescriptor);
}

export fn sizeOfTexelCopyBufferLayout() js.BigUint64 {
    return @sizeOf(js.gpu.TexelCopyBufferLayout);
}

export fn sizeOfTexelCopyTextureInfo() js.BigUint64 {
    return @sizeOf(js.gpu.TexelCopyTextureInfo);
}

export fn sizeOfTextureDescriptor() js.BigUint64 {
    return @sizeOf(js.gpu.TextureDescriptor);
}

export fn sizeOfTextureViewDescriptor() js.BigUint64 {
    return @sizeOf(js.gpu.TextureViewDescriptor);
}

export fn sizeOfVertexAttribute() js.BigUint64 {
    return @sizeOf(js.gpu.VertexAttribute);
}

export fn sizeOfVertexBufferLayout() js.BigUint64 {
    return @sizeOf(js.gpu.VertexBufferLayout);
}

export fn sizeOfVertexState() js.BigUint64 {
    return @sizeOf(js.gpu.VertexState);
}

fn exportFunctions(comptime Lib: type) void {
    const libname = @typeName(Lib)[(if (std.mem.lastIndexOfScalar(u8, @typeName(Lib), '.')) |i| i + 1 else 0)..];
    var buf: [libname.len]u8 = undefined;
    _ = std.ascii.lowerString(&buf, libname);
    for (@typeInfo(Lib).@"struct".decl_names) |decl_name| {
        switch (@typeInfo(@TypeOf(@field(Lib, decl_name)))) {
            .@"fn" => |func| {
                if (std.meta.activeTag(func.attrs.@"callconv") == std.lang.CallingConvention.c) {
                    @export(&@field(Lib, decl_name), .{
                        .name = buf[0..] ++ "Impl_" ++ decl_name,
                        .linkage = .strong,
                    });
                }
            },
            else => {},
        }
    }
}

const libc = @import("libc.zig");
const webgpu = @import("webgpu.zig");
const glfw3 = @import("glfw3.zig");

comptime {
    for (&.{ libc, webgpu, glfw3 }) |impl| exportFunctions(impl);
    @export(&libc.errno, .{
        .name = "errno",
        .linkage = .strong,
    });
}

// TODO: refactor this with native
const LAYER_COUNT = 2;

// TODO: refactor this with native
const PIXELLIZATION_MAX = 200;

const Root = struct {
    surface_texture_format: js.gpu.TextureFormat = undefined,
    sampler: js.gpu.Sampler = .{},
    vertex_buffer: js.gpu.Buffer = .{},
    index_buffer: js.gpu.Buffer = .{},
    fullscreen_shader_module: js.gpu.ShaderModule = .{},
    offscreen_shader_module: js.gpu.ShaderModule = .{},
    offscreen_texture_format: js.gpu.TextureFormat = undefined,
    offscreen_texture: js.gpu.Texture = undefined,
    offscreen_texture_view: js.gpu.TextureView = .{},
    offscreen_layer_texture_views: [LAYER_COUNT]js.gpu.TextureView = undefined,
    offscreen_uniform_buffer: js.gpu.Buffer = .{},
    offscreen_ubo: shader.OffscreenUBO = undefined,
    offscreen_bind_group: js.gpu.BindGroup = .{},
    offscreen_render_pipeline: js.gpu.RenderPipeline = .{},
    onscreen_shader_module: js.gpu.ShaderModule = .{},
    onscreen_uniform_buffer: js.gpu.Buffer = .{},
    onscreen_ubo: shader.OnscreenUBO = undefined,
    onscreen_bind_group: js.gpu.BindGroup = .{},
    onscreen_render_pipeline: js.gpu.RenderPipeline = .{},
    start_time: ?js.Float64 = null,
    failed: bool = false,
};
var root: Root = .{};

// TODO: refactor this with native
const vertices = [_]@Vector(2, f32){
    .{ -1.0, -1.0 }, .{ 3.0, -1.0 }, .{ -1.0, 3.0 },
};

// TODO: refactor this with native
const indices = [_]u32{ 0, 1, 2 };

const vertex_buffer_size = js.wgsl.sizeOf(@TypeOf(vertices));
const index_buffer_size = js.wgsl.sizeOf(@TypeOf(indices));
const offscreen_ubo_size = js.wgsl.sizeOf(@TypeOf(root.offscreen_ubo));
const onscreen_ubo_size = js.wgsl.sizeOf(@TypeOf(root.onscreen_ubo));

export fn allocUint8(len: u32) [*]const u8 {
    const slice = gpa.alloc(u8, len) catch std.debug.panic("{s}: failed to allocate memory", .{@src().fn_name});
    return slice.ptr;
}

fn onWindowResize(width: f32, height: f32) void {
    root.onscreen_ubo.resolution_x = width;
    root.onscreen_ubo.resolution_y = height;
}

fn onWindowFocus(focused: bool) void {
    c.cImGui_ImplGlfw_WindowFocusCallback(@ptrFromInt(1), if (focused) 1 else 0);
}

fn onCursorEnter(entered: bool) void {
    c.cImGui_ImplGlfw_CursorEnterCallback(@ptrFromInt(1), if (entered) 1 else 0);
}

fn onCursorPos(x: f32, y: f32) void {
    c.cImGui_ImplGlfw_CursorPosCallback(@ptrFromInt(1), x, y);
}

fn onMouseButton(button: js.platform.MouseButton, pressed: bool) void {
    c.cImGui_ImplGlfw_MouseButtonCallback(
        @ptrFromInt(1),
        @backingInt(button),
        @backingInt(if (pressed) js.platform.Action.press else js.platform.Action.release),
        js.platform.Keyboard.computeModifierBits(),
    );
}

fn onScroll(xoffset: f32, yoffset: f32) void {
    c.cImGui_ImplGlfw_ScrollCallback(@ptrFromInt(1), xoffset, yoffset);
}

fn onChar(codepoint: js.Uint32) void {
    c.cImGui_ImplGlfw_CharCallback(@ptrFromInt(1), codepoint);
}

fn onKey(key: js.platform.Key, scancode: js.platform.Scancode, action: js.platform.Action, mods: js.Uint32) void {
    c.cImGui_ImplGlfw_KeyCallback(@ptrFromInt(1), @backingInt(key), @backingInt(scancode), @backingInt(action), std.math.cast(c_int, mods) orelse 0);
}

fn requestAdapterCallback() void {
    js.gpu.Adapter.requestDevice(requestDeviceCallback);
}

fn requestDeviceCallback() void {
    js.gpu.Context.configure(root.surface_texture_format);
    const vertex_attributes = [_]js.gpu.VertexAttribute{
        .init(0, .float32x2, 0),
    };
    const vertex_buffer_layouts = [_]js.gpu.VertexBufferLayout{
        js.gpu.VertexBufferLayout.init(2 * 4, &vertex_attributes), // 2 floats, 4 bytes each
    };
    root.fullscreen_shader_module = js.gpu.Device.createShaderModule(@embedFile("fullscreen.vert.wgsl"));
    root.onscreen_shader_module = js.gpu.Device.createShaderModule(@embedFile("onscreen.frag.wgsl"));
    root.offscreen_shader_module = js.gpu.Device.createShaderModule(@embedFile("offscreen.frag.wgsl"));
    const fullscreen_vertex_state: js.gpu.VertexState = .init(root.fullscreen_shader_module, &vertex_buffer_layouts);
    root.sampler = js.gpu.Device.createSampler(.{});
    root.vertex_buffer = js.gpu.Device.createBuffer(vertex_buffer_size, js.gpu.BufferUsage.vertex | js.gpu.BufferUsage.copy_dst);
    js.gpu.Queue.writeBuffer(@TypeOf(vertices), root.vertex_buffer, 0, &[_]@TypeOf(vertices){vertices}, 0, @sizeOf(@TypeOf(vertices)));
    root.index_buffer = js.gpu.Device.createBuffer(index_buffer_size, js.gpu.BufferUsage.index | js.gpu.BufferUsage.copy_dst);
    js.gpu.Queue.writeBuffer(@TypeOf(indices), root.index_buffer, 0, &[_]@TypeOf(indices){indices}, 0, @sizeOf(@TypeOf(indices)));
    root.offscreen_ubo.resolution_x = PIXELLIZATION_MAX;
    root.offscreen_ubo.resolution_y = PIXELLIZATION_MAX;
    root.offscreen_ubo.seed = 0;
    root.offscreen_texture_format = .rgba8unorm;
    const offscreen_texture_descriptor = js.gpu.TextureDescriptor.init(
        root.offscreen_texture_format,
        .@"2d",
        @round(root.offscreen_ubo.resolution_x),
        @round(root.offscreen_ubo.resolution_y),
        LAYER_COUNT,
        1,
        1,
        js.gpu.TextureUsage.texture_binding | js.gpu.TextureUsage.render_attachment | js.gpu.TextureUsage.copy_dst,
    );
    root.offscreen_texture = js.gpu.Device.createTexture(offscreen_texture_descriptor);
    root.offscreen_texture_view = root.offscreen_texture.createView(.fromDimension(.@"2d-array"), .{});
    root.offscreen_uniform_buffer = js.gpu.Device.createBuffer(offscreen_ubo_size, js.gpu.BufferUsage.uniform | js.gpu.BufferUsage.copy_dst);

    const offscreen_bind_group_layout_entries = [_]js.gpu.BindGroupLayoutEntry{
        js.gpu.BindGroupLayoutEntry.initUniformBuffer(0, js.gpu.ShaderStage.fragment),
    };
    var offscreen_bind_group_layout = js.gpu.Device.createBindGroupLayout(&offscreen_bind_group_layout_entries);
    defer offscreen_bind_group_layout.deinit();
    const offscreen_bind_group_entries = [_]js.gpu.BindGroupEntry{
        js.gpu.BindGroupEntry.initBuffer(0, root.offscreen_uniform_buffer, 0, offscreen_ubo_size),
    };
    root.offscreen_bind_group = js.gpu.Device.createBindGroup(offscreen_bind_group_layout, &offscreen_bind_group_entries);
    var offscreen_pipeline_layout = js.gpu.Device.createPipelineLayout(&[_]js.gpu.BindGroupLayout{offscreen_bind_group_layout});
    defer offscreen_pipeline_layout.deinit();

    const offscreen_color_target_states = [_]js.gpu.ColorTargetState{
        js.gpu.ColorTargetState.init(
            root.offscreen_texture_format,
            .{ .operation = .add, .src_factor = .one, .dst_factor = .zero },
            .{ .operation = .add, .src_factor = .one, .dst_factor = .zero },
            js.gpu.ColorWriteMask.all,
        ),
    };

    const offscreen_fragment_state: js.gpu.FragmentState = .init(root.offscreen_shader_module, &offscreen_color_target_states);

    root.offscreen_render_pipeline = js.gpu.Device.createRenderPipeline(offscreen_pipeline_layout, fullscreen_vertex_state, offscreen_fragment_state, .{});

    updateOffscreen();

    root.onscreen_uniform_buffer = js.gpu.Device.createBuffer(onscreen_ubo_size, js.gpu.BufferUsage.uniform | js.gpu.BufferUsage.copy_dst);
    const onscreen_bind_group_layout_entries = [_]js.gpu.BindGroupLayoutEntry{
        js.gpu.BindGroupLayoutEntry.initUniformBuffer(0, js.gpu.ShaderStage.fragment),
        js.gpu.BindGroupLayoutEntry.init2DArrayTexture(1, js.gpu.ShaderStage.fragment),
        js.gpu.BindGroupLayoutEntry.initSampler(2, js.gpu.ShaderStage.fragment),
    };
    var onscreen_bind_group_layout = js.gpu.Device.createBindGroupLayout(&onscreen_bind_group_layout_entries);
    defer onscreen_bind_group_layout.deinit();
    const onscreen_bind_group_entries = [_]js.gpu.BindGroupEntry{
        js.gpu.BindGroupEntry.initBuffer(0, root.onscreen_uniform_buffer, 0, onscreen_ubo_size),
        js.gpu.BindGroupEntry.initTextureView(1, root.offscreen_texture_view),
        js.gpu.BindGroupEntry.initSampler(2, root.sampler),
    };
    root.onscreen_bind_group = js.gpu.Device.createBindGroup(onscreen_bind_group_layout, &onscreen_bind_group_entries);
    var onscreen_pipeline_layout = js.gpu.Device.createPipelineLayout(&[_]js.gpu.BindGroupLayout{onscreen_bind_group_layout});
    defer onscreen_pipeline_layout.deinit();

    const onscreen_color_target_states = [_]js.gpu.ColorTargetState{
        js.gpu.ColorTargetState.init(
            root.surface_texture_format,
            .{ .operation = .add, .src_factor = .one, .dst_factor = .zero },
            .{ .operation = .add, .src_factor = .one, .dst_factor = .zero },
            js.gpu.ColorWriteMask.all,
        ),
    };

    const onscreen_fragment_state: js.gpu.FragmentState = .init(root.onscreen_shader_module, &onscreen_color_target_states);

    root.onscreen_render_pipeline = js.gpu.Device.createRenderPipeline(onscreen_pipeline_layout, fullscreen_vertex_state, onscreen_fragment_state, .{});
    root.onscreen_ubo.resolution_x = std.math.lossyCast(f32, js.platform.Canvas.getWidth());
    root.onscreen_ubo.resolution_y = std.math.lossyCast(f32, js.platform.Canvas.getHeight());

    js.requestAnimationFrame();
}

export fn onFailure() void {
    root.failed = true;
}

export fn triggerCallback(cb_handle: js.Handle) void {
    const callback: js.gpu.Callback = @fromBackingInt(cb_handle);
    js.gpu.triggerCallback(callback);
}

fn initImgui() void {
    _ = c.CIMGUI_CHECKVERSION();
    if (c.ImGui_CreateContext(null) == null) {
        js.console.err("ImGui_CreateContext() failed", .{});
    }

    var io: *c.ImGuiIO = c.ImGui_GetIO();
    io.IniFilename = null;
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard | c.ImGuiConfigFlags_NavEnableGamepad;
    io.BackendFlags |= c.ImGuiBackendFlags_RendererHasTextures;

    // TODO: replace this line with initImguiStyle();
    c.ImGui_StyleColorsDark(null);

    if (!c.cImGui_ImplGlfw_InitForOther(@ptrFromInt(1), false)) {
        js.console.err("cImGui_ImplGlfw_InitForOther() failed", .{});
    }

    var init_info: c.ImGui_ImplWGPU_InitInfo = .{
        .Device = @ptrFromInt(1),
        .NumFramesInFlight = 3,
        .RenderTargetFormat = @backingInt(root.surface_texture_format),
        .DepthStencilFormat = c.WGPUTextureFormat_Undefined,
        .PipelineMultisampleState = .{
            .count = 1,
            .mask = std.math.maxInt(u32),
            .alphaToCoverageEnabled = c.WGPU_FALSE,
        },
    };

    if (!c.cImGui_ImplWGPU_Init(&init_info)) {
        js.console.err("cImGui_ImplWGPU_Init() failed", .{});
    }
}

export fn init() void {
    js.platform.init();
    js.platform.listenEvent(.windowresize, onWindowResize);
    js.platform.listenEvent(.windowfocus, onWindowFocus);
    js.platform.listenEvent(.cursorpos, onCursorPos);
    js.platform.listenEvent(.cursorenter, onCursorEnter);
    js.platform.listenEvent(.mousebutton, onMouseButton);
    js.platform.listenEvent(.scroll, onScroll);
    js.platform.listenEvent(.char, onChar);
    js.platform.listenEvent(.key, onKey);
    js.platform.Canvas.getGpuContext();
    js.platform.Window.getGpuInstance();
    root.surface_texture_format = js.gpu.Instance.getPreferredSurfaceFormat();
    initImgui();
    js.gpu.Instance.requestAdapter(requestAdapterCallback);
}

export fn onWindowEvent(event_type: js.String) void {
    js.platform.Window.onEvent(event_type);
}

export fn onCanvasEvent(event_type: js.String) void {
    js.platform.Canvas.onEvent(event_type);
}

fn updateOffscreen() void {
    var offscreen_render_pass_encoder: js.gpu.RenderPassEncoder = .{};
    var offscreen_command_encoder: js.gpu.CommandEncoder = .{};
    var offscreen_command_buffer: js.gpu.CommandBuffer = .{};
    var offscreen_layer_texture_view_desc: js.gpu.TextureViewDescriptor = .fromDimension(.@"2d");
    for (0..LAYER_COUNT) |layer| {
        offscreen_command_encoder = js.gpu.Device.createCommandEncoder();
        defer offscreen_command_encoder.deinit();
        offscreen_layer_texture_view_desc.base_array_layer = layer;
        if (root.offscreen_layer_texture_views[layer].isInit()) root.offscreen_layer_texture_views[layer].deinit();
        root.offscreen_layer_texture_views[layer] = root.offscreen_texture.createView(offscreen_layer_texture_view_desc, .{});
        {
            offscreen_render_pass_encoder = offscreen_command_encoder.beginRenderPass(root.offscreen_layer_texture_views[layer], .{});
            defer offscreen_render_pass_encoder.end();
            offscreen_render_pass_encoder.setPipeline(root.offscreen_render_pipeline);
            offscreen_render_pass_encoder.setVertexBuffer(0, root.vertex_buffer, 0, @sizeOf(@TypeOf(vertices)));
            offscreen_render_pass_encoder.setIndexBuffer(root.index_buffer, .uint32, 0, @sizeOf(@TypeOf(indices)));
            root.offscreen_ubo.layer = layer;
            js.gpu.Queue.writeBuffer(@TypeOf(root.offscreen_ubo), root.offscreen_uniform_buffer, 0, &[_]@TypeOf(root.offscreen_ubo){root.offscreen_ubo}, 0, @sizeOf(@TypeOf(root.offscreen_ubo)));
            offscreen_render_pass_encoder.setBindGroup(0, root.offscreen_bind_group, &.{});
            offscreen_render_pass_encoder.drawIndexed(indices.len, 1, 0, 0, 0);
        }
        offscreen_command_buffer = offscreen_command_encoder.finish();
        defer offscreen_command_buffer.deinit();
        js.gpu.Queue.submit(&[_]js.gpu.CommandBuffer{offscreen_command_buffer});
    }
}

export fn update() void {
    if (root.failed) js.console.throwErr(.js_err);

    c.cImGui_ImplGlfw_NewFrame();
    c.cImGui_ImplWGPU_NewFrame();
    c.ImGui_NewFrame();
    c.ImGui_GetStyle().*.Colors[c.ImGuiCol_WindowBg] = .{ .x = 1, .y = 0, .z = 0, .w = 1 }; // opaque red
    c.ImGui_GetStyle().*.Colors[c.ImGuiCol_Text] = .{ .x = 1, .y = 1, .z = 1, .w = 1 };
    c.ImGui_SetNextWindowPos(.{ .x = 50, .y = 30 }, c.ImGuiCond_FirstUseEver);
    c.ImGui_SetNextWindowSize(.{ .x = 100, .y = 90 }, c.ImGuiCond_FirstUseEver);
    if (c.ImGui_Begin("Test", null, 0)) c.ImGui_Text("Hello world");
    c.ImGui_End();
    c.ImGui_Render();

    var surface_texture = js.gpu.Context.getCurrentTexture();
    defer surface_texture.deinit();
    var surface_texture_view = surface_texture.createView(.fromDimension(.@"2d"), .{});
    defer surface_texture_view.deinit();

    const now: js.Float64 = js.time.now();
    if (root.start_time == null) root.start_time = now;
    var onscreen_command_encoder = js.gpu.Device.createCommandEncoder();
    defer onscreen_command_encoder.deinit();
    var onscreen_render_pass_encoder: js.gpu.RenderPassEncoder = .{};
    {
        onscreen_render_pass_encoder = onscreen_command_encoder.beginRenderPass(surface_texture_view, .{});
        defer onscreen_render_pass_encoder.end();
        onscreen_render_pass_encoder.setPipeline(root.onscreen_render_pipeline);
        onscreen_render_pass_encoder.setVertexBuffer(0, root.vertex_buffer, 0, @sizeOf(@TypeOf(vertices)));
        onscreen_render_pass_encoder.setIndexBuffer(root.index_buffer, .uint32, 0, @sizeOf(@TypeOf(indices)));
        root.onscreen_ubo.time = std.math.lossyCast(f32, (now - root.start_time.?) / 1000.0);
        js.gpu.Queue.writeBuffer(@TypeOf(root.onscreen_ubo), root.onscreen_uniform_buffer, 0, &[_]@TypeOf(root.onscreen_ubo){root.onscreen_ubo}, 0, @sizeOf(@TypeOf(root.onscreen_ubo)));
        onscreen_render_pass_encoder.setBindGroup(0, root.onscreen_bind_group, &.{});
        onscreen_render_pass_encoder.drawIndexed(indices.len, 1, 0, 0, 0);
        // Imgui must be drawn after the onscreen render pass:
        c.cImGui_ImplWGPU_RenderDrawData(c.ImGui_GetDrawData(), @ptrCast(@alignCast(&onscreen_render_pass_encoder)));
    }
    var onscreen_command_buffer = onscreen_command_encoder.finish();
    defer onscreen_command_buffer.deinit();
    js.gpu.Queue.submit(&[_]js.gpu.CommandBuffer{onscreen_command_buffer});
}
