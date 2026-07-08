const std = @import("std");
const c = @import("c");
const build = @import("build");
const prototypes = @import("prototypes");
const shader = @import("shaders/types.zig");
const log = @import("log");

extern "c" fn glfwCreateWindow(width: u32, height: u32, title: [*c]const u8, monitor: ?*c.GLFWmonitor, share: ?*c.GLFWwindow) ?*c.GLFWwindow;
extern "c" fn glfwGetFramebufferSize(window: ?*c.GLFWwindow, width: [*c]u32, height: [*c]u32) void;
extern "c" fn glfwSetWindowMaximizeCallback(window: ?*c.GLFWwindow, callback: ?*const fn (?*c.GLFWwindow, u32) callconv(.c) void) c.GLFWwindowmaximizefun;
extern "c" fn glfwSetFramebufferSizeCallback(window: ?*c.GLFWwindow, callback: ?*const fn (?*c.GLFWwindow, u32, u32) callconv(.c) void) c.GLFWframebuffersizefun;
extern "c" fn glfwSetWindowSizeLimits(window: ?*c.GLFWwindow, u32, u32, u32, u32) void;

const MAX_FRAMES_IN_FLIGHT: u32 = 2;
const TIMEOUT = std.math.maxInt(u64);
const VULKAN_API_VERSION = c.VK_API_VERSION_1_2;

const PIXELLIZATION_MAX = 600;

const vertices = [_]shader.Vec2{
    .{ -1.0, -1.0 }, .{ 3.0, -1.0 }, .{ -1.0, 3.0 },
};
const indices = [_]u32{ 0, 1, 2 };

const required_device_extensions_z = [_][*:0]const u8{
    c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
};

const required_device_extensions: [required_device_extensions_z.len][]const u8 = blk: {
    var exts: [required_device_extensions_z.len][]const u8 = undefined;
    for (0..exts.len) |i| exts[i] = std.mem.span(required_device_extensions_z[i]);
    break :blk exts;
};

fn alignUp(n: c.VkDeviceSize, m: c.VkDeviceSize) c.VkDeviceSize {
    return (n + m - 1) & ~(m - 1);
}

const PhysicalDevice = struct {
    const Queue = struct {
        handle: c.VkQueue = undefined,
        family: u32 = undefined,
    };

    const Queues = struct {
        graphics: Queue = .{},
        present: Queue = .{},
    };

    const Features = struct {
        const RequiredFeatures = blk: {
            var field_names = [_][]const u8{
                "has_sampler_anisotropy",
                "has_shader_int_16",
                "has_shader_int_64",
                "has_surface_format",
                "has_present_mode",
                "is_lt_max_sampler_anisotropy",
                "is_lt_max_image_dimension_2d_width",
                "is_lt_max_image_dimension_2d_height",
                "is_lt_max_image_array_layers",
                "is_lt_max_onscreen_uniform_buffer_range",
                "is_lt_max_offscreen_uniform_buffer_range",
                "is_lt_max_memory_allocation_count",
                "is_lt_max_sampler_allocation_count",
                "is_lt_max_bound_descriptor_sets",
                "is_lt_max_per_stage_descriptor_samplers",
                "is_lt_max_per_stage_descriptor_uniform_buffers",
                "is_lt_max_per_stage_descriptor_sampled_images",
                "is_lt_max_per_stage_resources",
                "is_lt_max_descriptor_set_uniform_buffers",
                "is_lt_max_descriptor_set_uniform_buffers_dynamic",
                "is_lt_max_descriptor_set_samplers",
                "is_lt_max_descriptor_set_sampled_images",
                "is_lt_max_fragment_input_components",
                "is_lt_max_viewports",
                "is_lt_max_viewport_dimension_width",
                "is_lt_max_viewport_dimension_height",
                "is_lt_max_framebuffer_width",
                "is_lt_max_framebuffer_height",
                "is_lt_max_color_attachments",
            } ++ required_device_extensions;
            var field_types: [field_names.len]type = @splat(bool);
            const default_value = false;
            const default_ptr: ?*const anyopaque = @ptrCast(&default_value);
            var field_attrs: [field_names.len]std.lang.Type.Struct.FieldAttributes = @splat(.{
                .default_value_ptr = default_ptr,
            });
            break :blk @Struct(.auto, null, &field_names, &field_types, &field_attrs);
        };

        required: RequiredFeatures = .{},
        discrete: bool = false,
    };

    handle: c.VkPhysicalDevice = undefined,
    buffer_image_granularity: c.VkDeviceSize = undefined,
    min_uniform_buffer_offset_alignment: c.VkDeviceSize = undefined,
    non_coherent_atom_size: c.VkDeviceSize = undefined,
    capabilities: c.VkSurfaceCapabilitiesKHR = undefined,
    extensions: std.ArrayList([*:0]const u8) = .empty,
    surface_formats: []c.VkSurfaceFormatKHR = undefined,
    present_modes: []c.VkPresentModeKHR = undefined,
    queues: Queues = .{},
    features: Features = .{},

    fn init(root: *Root, physical_device: c.VkPhysicalDevice) (std.mem.Allocator.Error || error{ Vulkan, QueueFamilies })!@This() {
        var physical_device_properties: c.VkPhysicalDeviceProperties = undefined;
        prototypes.vkGetPhysicalDeviceProperties(physical_device, &physical_device_properties);

        if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) log.debug("Physical device name: {s}", .{physical_device_properties.deviceName});

        var physical_device_features: c.VkPhysicalDeviceFeatures = undefined;
        prototypes.vkGetPhysicalDeviceFeatures(physical_device, &physical_device_features);

        var self: @This() = .{
            .handle = physical_device,
            .buffer_image_granularity = physical_device_properties.limits.bufferImageGranularity,
            .min_uniform_buffer_offset_alignment = physical_device_properties.limits.minUniformBufferOffsetAlignment,
            .non_coherent_atom_size = physical_device_properties.limits.nonCoherentAtomSize,
            .extensions = try std.ArrayList([*:0]const u8).initCapacity(root.arena_allocator, required_device_extensions_z.len),
            .features = .{
                .discrete = (physical_device_properties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU),
                .required = .{
                    .has_sampler_anisotropy = (physical_device_features.samplerAnisotropy == c.VK_TRUE),
                    .has_shader_int_16 = (physical_device_features.shaderInt16 == c.VK_TRUE),
                    .has_shader_int_64 = (physical_device_features.shaderInt64 == c.VK_TRUE),
                    .is_lt_max_sampler_anisotropy = (physical_device_properties.limits.maxSamplerAnisotropy > 0),
                    .is_lt_max_image_dimension_2d_width = (physical_device_properties.limits.maxImageDimension2D >= root.offscreen.extent.width),
                    .is_lt_max_image_dimension_2d_height = (physical_device_properties.limits.maxImageDimension2D >= root.offscreen.extent.height),
                    .is_lt_max_image_array_layers = (physical_device_properties.limits.maxImageArrayLayers >= root.offscreen.layers),
                    .is_lt_max_onscreen_uniform_buffer_range = (physical_device_properties.limits.maxUniformBufferRange >= @sizeOf(shader.OnscreenUBO)),
                    .is_lt_max_offscreen_uniform_buffer_range = (physical_device_properties.limits.maxUniformBufferRange >= @sizeOf(shader.OffscreenUBO)),
                    .is_lt_max_memory_allocation_count = (physical_device_properties.limits.maxMemoryAllocationCount > 1),
                    .is_lt_max_sampler_allocation_count = (physical_device_properties.limits.maxSamplerAllocationCount > 0),
                    .is_lt_max_bound_descriptor_sets = (physical_device_properties.limits.maxBoundDescriptorSets > 1),
                    .is_lt_max_per_stage_descriptor_samplers = (physical_device_properties.limits.maxPerStageDescriptorSamplers > 0),
                    .is_lt_max_per_stage_descriptor_uniform_buffers = (physical_device_properties.limits.maxPerStageDescriptorUniformBuffers > 0),
                    .is_lt_max_per_stage_descriptor_sampled_images = (physical_device_properties.limits.maxPerStageDescriptorSampledImages > 0),
                    .is_lt_max_per_stage_resources = (physical_device_properties.limits.maxPerStageResources > 1),
                    .is_lt_max_descriptor_set_uniform_buffers = (physical_device_properties.limits.maxDescriptorSetUniformBuffers > 1),
                    .is_lt_max_descriptor_set_uniform_buffers_dynamic = (physical_device_properties.limits.maxDescriptorSetUniformBuffersDynamic > 0),
                    .is_lt_max_descriptor_set_samplers = (physical_device_properties.limits.maxDescriptorSetSamplers > 0),
                    .is_lt_max_descriptor_set_sampled_images = (physical_device_properties.limits.maxDescriptorSetSampledImages > 0),
                    .is_lt_max_fragment_input_components = (physical_device_properties.limits.maxFragmentInputComponents > 1),
                    .is_lt_max_viewports = (physical_device_properties.limits.maxViewports > 0),
                    .is_lt_max_viewport_dimension_width = (physical_device_properties.limits.maxViewportDimensions[0] >= root.max_extent.width),
                    .is_lt_max_viewport_dimension_height = (physical_device_properties.limits.maxViewportDimensions[1] >= root.max_extent.height),
                    .is_lt_max_framebuffer_width = (physical_device_properties.limits.maxFramebufferWidth >= @max(root.offscreen.extent.width, root.max_extent.width)),
                    .is_lt_max_framebuffer_height = (physical_device_properties.limits.maxFramebufferHeight >= @max(root.offscreen.extent.height, root.max_extent.height)),
                    .is_lt_max_color_attachments = (physical_device_properties.limits.maxColorAttachments > 0),
                },
            },
        };

        var supported_device_extension_count: u32 = undefined;

        try errify(prototypes.vkEnumerateDeviceExtensionProperties(physical_device, null, &supported_device_extension_count, null));

        const supported_device_extensions = try root.init.gpa.alloc(c.VkExtensionProperties, supported_device_extension_count);
        defer root.init.gpa.free(supported_device_extensions);

        try errify(prototypes.vkEnumerateDeviceExtensionProperties(physical_device, null, &supported_device_extension_count, supported_device_extensions.ptr));

        if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) log.debug("  - supported extensions:", .{});

        for (supported_device_extensions) |supported_ext| {
            if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) log.debug("    - {s}", .{supported_ext.extensionName});
            inline for (required_device_extensions) |required_ext| {
                if (std.mem.eql(u8, required_ext, supported_ext.extensionName[0..std.mem.indexOfScalar(u8, &(supported_ext.extensionName), 0).?])) {
                    @field(self.features.required, required_ext) = true;
                    break;
                }
            }
        }

        self.extensions.appendSliceAssumeCapacity(required_device_extensions_z[0..]);

        try self.querySwapchainSupport(root);

        if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) {
            log.debug("  - features:", .{});
            inline for (@typeInfo(@TypeOf(physical_device_features)).@"struct".field_names) |field_name| {
                log.debug("    - {s}: {any}", .{ field_name, @field(physical_device_features, field_name) });
            }
            log.debug("  - limits:", .{});
            inline for (@typeInfo(@TypeOf(physical_device_properties.limits)).@"struct".field_names) |field_name| {
                log.debug("    - {s}: {any}", .{ field_name, @field(physical_device_properties.limits, field_name) });
            }
        }

        var physical_device_queue_family_property_count: u32 = undefined;
        prototypes.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &physical_device_queue_family_property_count, null);

        const physical_device_queue_family_properties = try root.init.gpa.alloc(c.VkQueueFamilyProperties, physical_device_queue_family_property_count);
        defer root.init.gpa.free(physical_device_queue_family_properties);

        prototypes.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &physical_device_queue_family_property_count, physical_device_queue_family_properties.ptr);

        var supported = c.VK_FALSE;
        var graphics: ?u32 = null;
        var present: ?u32 = null;
        for (0..physical_device_queue_family_property_count) |family| {
            try errify(prototypes.vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, @intCast(family), root.surface, &supported));

            if ((physical_device_queue_family_properties[family].queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) and (supported == c.VK_TRUE)) {
                graphics = @intCast(family);
                present = @intCast(family);
                break;
            }

            if (graphics == null and (physical_device_queue_family_properties[family].queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0)) graphics = @intCast(family);
            if (present == null and (supported == c.VK_TRUE)) present = @intCast(family);
        }

        if (graphics == null or present == null) return error.QueueFamilies;

        self.queues.graphics.family = graphics.?;
        self.queues.present.family = present.?;

        if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) {
            log.debug("  - score:", .{});
            log.debug("    - required features: ({})", .{self.supportsRequiredFeatures()});
            log.debug("    - same queue: {} ({d})", .{ self.queues.graphics.family == self.queues.present.family, 2 * @as(u32, @intFromBool(self.queues.graphics.family == self.queues.present.family)) });
            log.debug("    - discrete: {} ({d})", .{ self.features.discrete, 4 * @as(u32, @intFromBool(self.features.discrete)) });
            log.debug("    - total: {d}", .{self.score()});
        }

        return self;
    }

    fn querySwapchainSupport(self: *@This(), root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
        try errify(prototypes.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(self.handle, root.surface, &self.capabilities));

        var surface_format_count: u32 = undefined;

        try errify(prototypes.vkGetPhysicalDeviceSurfaceFormatsKHR(self.handle, root.surface, &surface_format_count, null));

        if (surface_format_count > 0) {
            self.features.required.has_surface_format = true;
            self.surface_formats = try root.arena_allocator.alloc(c.VkSurfaceFormatKHR, surface_format_count);
            try errify(prototypes.vkGetPhysicalDeviceSurfaceFormatsKHR(self.handle, root.surface, &surface_format_count, self.surface_formats.ptr));
        }

        var present_mode_count: u32 = undefined;

        try errify(prototypes.vkGetPhysicalDeviceSurfacePresentModesKHR(self.handle, root.surface, &present_mode_count, null));

        if (present_mode_count > 0) {
            self.features.required.has_present_mode = true;
            self.present_modes = try root.arena_allocator.alloc(c.VkPresentModeKHR, present_mode_count);
            try errify(prototypes.vkGetPhysicalDeviceSurfacePresentModesKHR(self.handle, root.surface, &present_mode_count, self.present_modes.ptr));
        }
    }

    fn supportsRequiredFeatures(self: @This()) bool {
        var supported = true;
        inline for (@typeInfo(@TypeOf(self.features.required)).@"struct".field_names) |field_name| {
            supported = supported and @field(self.features.required, field_name);
        }
        return supported;
    }

    fn score(self: @This()) u32 {
        return @as(u32, @intFromBool(self.supportsRequiredFeatures())) * (1 +
            2 * @as(u32, @intFromBool(self.queues.graphics.family == self.queues.present.family)) +
            4 * @as(u32, @intFromBool(self.features.discrete)));
    }
};

const Pipelines = struct {
    handles: []c.VkPipeline = undefined,
    layout: c.VkPipelineLayout = undefined,
};

const Offscreen = struct {
    const Views = struct {
        array: c.VkImageView = undefined,
        layers: []c.VkImageView = undefined,
    };

    extent: c.VkExtent2D,
    layers: u32,
    image: c.VkImage = undefined,
    views: Views = .{},
    sampler: c.VkSampler = undefined,
    render_pass: c.VkRenderPass = undefined,
    framebuffers: []c.VkFramebuffer = undefined,
    descriptor_set_layouts: []c.VkDescriptorSetLayout = undefined,
    pipelines: Pipelines = undefined,
    descriptor_sets: []c.VkDescriptorSet = undefined,
    render: bool = true,
};

const Memory = struct {
    const DeviceLocal = struct {
        const Offsets = struct {
            geometry_buffer: c.VkDeviceSize = 0,
            vertex_buffer: c.VkDeviceSize = 0,
            index_buffer: c.VkDeviceSize = 0,
            offscreen_image: c.VkDeviceSize = 0,
        };

        handle: c.VkDeviceMemory = undefined,
        offset: Offsets = .{},
    };

    const HostVisible = struct {
        const Offsets = struct {
            staging_buffer: c.VkDeviceSize = 0,
            staging_vertex_buffer: c.VkDeviceSize = 0,
            staging_index_buffer: c.VkDeviceSize = 0,
            uniform_buffer: c.VkDeviceSize = 0,
            onscreen_uniform_buffer: [2]c.VkDeviceSize = .{ 0, 0 },
            offscreen_uniform_buffer: c.VkDeviceSize = 0,
        };

        handle: c.VkDeviceMemory = undefined,
        offset: Offsets = .{},
    };

    device_local: DeviceLocal = .{},
    host_visible: HostVisible = .{},
};

const Root = struct {
    init: *const std.process.Init,
    arena_allocator: std.mem.Allocator,
    window: *c.GLFWwindow = undefined,
    required_platform_extensions: [][*:0]const u8 = undefined,
    instance: c.VkInstance = undefined,
    surface: c.VkSurfaceKHR = undefined,
    surface_format: c.VkSurfaceFormatKHR = undefined,
    extent: c.VkExtent2D = .{
        .width = 0,
        .height = 0,
    },
    max_extent: c.VkExtent2D = .{
        .width = 0,
        .height = 0,
    },
    physical_device: PhysicalDevice = .{},
    device: c.VkDevice = undefined,
    swapchain: c.VkSwapchainKHR = undefined,
    images: []c.VkImage = undefined,
    views: []c.VkImageView = undefined,
    render_pass: c.VkRenderPass = undefined,
    offscreen: Offscreen,
    descriptor_set_layouts: []c.VkDescriptorSetLayout = undefined,
    viewports: [1]c.VkViewport = undefined,
    scissors: [1]c.VkRect2D = undefined,
    pipelines: Pipelines = undefined,
    framebuffers: []c.VkFramebuffer = undefined,
    command_pool: c.VkCommandPool = undefined,
    buffers_command_pool: c.VkCommandPool = undefined,
    memory: Memory = .{},
    geometry_buffer: c.VkBuffer = undefined,
    staging_buffer: c.VkBuffer = undefined,
    uniform_buffer: c.VkBuffer = undefined,
    descriptor_pool: c.VkDescriptorPool = undefined,
    descriptor_sets: []c.VkDescriptorSet = undefined,
    command_buffers: []c.VkCommandBuffer = undefined,
    image_available_semaphores: []c.VkSemaphore = undefined,
    render_finished_semaphores: []c.VkSemaphore = undefined,
    in_flight_fences: []c.VkFence = undefined,
    current_frame: u32 = 0,
    framebuffer_resized: bool = false,
    start_time: std.Io.Timestamp = undefined,
    imgui_window_created: bool = false,
    imgui_window_hidden: bool = false,
    prng: std.Random.DefaultPrng,
    random: std.Random,
    seed: u32 = 0,
};

fn errify(result: c.VkResult) error{Vulkan}!void {
    if (result == c.VK_SUCCESS) return;
    std.debug.print("[vulkan] Error: VkResult = {d}\n", .{result});
    return error.Vulkan;
}

fn panic(result: c.VkResult) callconv(.c) void {
    if (result == c.VK_SUCCESS) return;
    std.debug.panic("[vulkan] Error: VkResult = {d}\n", .{result});
}

fn imguiLoader(name: [*c]const u8, instance: ?*anyopaque) callconv(.c) ?*const fn () callconv(.c) void {
    return c.glfwGetInstanceProcAddress(@ptrCast(@alignCast(instance)), name);
}

fn GLFWErrorCallback(err: c_int, description: [*c]const u8) callconv(.c) void {
    std.debug.print("GLFW Error {d}: {s}\n", .{ err, description });
}

fn GLFWFramebuferResized(window: ?*c.GLFWwindow) void {
    if (c.glfwGetWindowUserPointer(window)) |user_pointer| {
        const root = @as(?*Root, @ptrCast(@alignCast(user_pointer)));
        root.?.framebuffer_resized = true;
    } else unreachable;
}

fn GLFWWindowMaximizeCallback(window: ?*c.GLFWwindow, maximized: u32) callconv(.c) void {
    _ = maximized;
    GLFWFramebuferResized(window);
}

fn GLFWFramebufferSizeCallback(window: ?*c.GLFWwindow, width: u32, height: u32) callconv(.c) void {
    _ = .{ width, height };
    GLFWFramebuferResized(window);
}

fn GLFWKeyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = .{ scancode, mods };
    var root: ?*Root = undefined;
    if (action == c.GLFW_PRESS) {
        if (c.glfwGetWindowUserPointer(window)) |user_pointer| {
            root = @ptrCast(@alignCast(user_pointer));
        } else unreachable;
        // WARNING: US keyboard layout used here
        switch (key) {
            c.GLFW_KEY_SPACE => root.?.imgui_window_hidden = !root.?.imgui_window_hidden,
            c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(root.?.window, c.GLFW_TRUE),
            else => {},
        }
    }
}

fn initImguiStyle() void {
    var style: *c.ImGuiStyle = c.ImGui_GetStyle();

    // --- 1. Sizing and Spacing (Sharp & Aggressive) ---
    style.WindowPadding = c.ImVec2{ .x = 10.0, .y = 10.0 };
    style.FramePadding = c.ImVec2{ .x = 6.0, .y = 4.0 };
    style.ItemSpacing = c.ImVec2{ .x = 8.0, .y = 4.0 };
    style.ScrollbarSize = 13.0;
    style.GrabMinSize = 10.0;

    // --- 2. Borders & Rounding (Cyberpunk = Hard Edges) ---
    style.WindowRounding = 0.0;
    style.FrameRounding = 0.0;
    style.PopupRounding = 0.0;
    style.ScrollbarRounding = 0.0;
    style.GrabRounding = 0.0;
    style.TabRounding = 0.0;

    style.WindowBorderSize = 1.0;
    style.FrameBorderSize = 1.0;
    style.PopupBorderSize = 1.0;

    // --- 3. The Neon Palette ---
    // Background: Pitch Black / Deep Navy
    // Neon Cyan: #00f9 | Neon Pink: #ff003 | Neon Yellow: #fcee0a

    // Text
    style.Colors[c.ImGuiCol_Text] = c.ImVec4{ .x = 0.00, .y = 1.00, .z = 0.62, .w = 1.00 }; // Neon Green/Cyan
    style.Colors[c.ImGuiCol_TextDisabled] = c.ImVec4{ .x = 0.20, .y = 0.40, .z = 0.35, .w = 1.00 };

    // Backgrounds
    style.Colors[c.ImGuiCol_WindowBg] = c.ImVec4{ .x = 0.02, .y = 0.02, .z = 0.04, .w = 0.95 }; // Near black
    style.Colors[c.ImGuiCol_ChildBg] = c.ImVec4{ .x = 0.02, .y = 0.02, .z = 0.04, .w = 0.00 };
    style.Colors[c.ImGuiCol_PopupBg] = c.ImVec4{ .x = 0.02, .y = 0.02, .z = 0.04, .w = 0.98 };

    // Borders (The "Glow" look)
    style.Colors[c.ImGuiCol_Border] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.60 }; // Neon Pink Border
    style.Colors[c.ImGuiCol_BorderShadow] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.20 };

    // Frames
    style.Colors[c.ImGuiCol_FrameBg] = c.ImVec4{ .x = 0.05, .y = 0.05, .z = 0.10, .w = 1.00 };
    style.Colors[c.ImGuiCol_FrameBgHovered] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.20 };
    style.Colors[c.ImGuiCol_FrameBgActive] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.40 };

    // Title Barsc.
    style.Colors[c.ImGuiCol_TitleBg] = c.ImVec4{ .x = 0.02, .y = 0.02, .z = 0.04, .w = 1.00 };
    style.Colors[c.ImGuiCol_TitleBgActive] = c.ImVec4{ .x = 0.05, .y = 0.05, .z = 0.10, .w = 1.00 };
    style.Colors[c.ImGuiCol_TitleBgCollapsed] = c.ImVec4{ .x = 0.02, .y = 0.02, .z = 0.04, .w = 1.00 };

    // Menus
    style.Colors[c.ImGuiCol_MenuBarBg] = c.ImVec4{ .x = 0.05, .y = 0.05, .z = 0.10, .w = 1.00 };

    // Scrollbars
    style.Colors[c.ImGuiCol_ScrollbarBg] = c.ImVec4{ .x = 0.02, .y = 0.02, .z = 0.04, .w = 1.00 };
    style.Colors[c.ImGuiCol_ScrollbarGrab] = c.ImVec4{ .x = 1.00, .y = 0.93, .z = 0.04, .w = 0.60 }; // Neon Yellow
    style.Colors[c.ImGuiCol_ScrollbarGrabHovered] = c.ImVec4{ .x = 1.00, .y = 0.93, .z = 0.04, .w = 0.80 };
    style.Colors[c.ImGuiCol_ScrollbarGrabActive] = c.ImVec4{ .x = 1.00, .y = 0.93, .z = 0.04, .w = 1.00 };

    // Interactables
    style.Colors[c.ImGuiCol_CheckMark] = c.ImVec4{ .x = 1.00, .y = 0.93, .z = 0.04, .w = 1.00 }; // Yellow
    style.Colors[c.ImGuiCol_SliderGrab] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.80 }; // Pink
    style.Colors[c.ImGuiCol_SliderGrabActive] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 1.00 };
    style.Colors[c.ImGuiCol_Button] = c.ImVec4{ .x = 0.00, .y = 1.00, .z = 0.62, .w = 0.20 }; // Cyan Ghost
    style.Colors[c.ImGuiCol_ButtonHovered] = c.ImVec4{ .x = 0.00, .y = 1.00, .z = 0.62, .w = 0.50 };
    style.Colors[c.ImGuiCol_ButtonActive] = c.ImVec4{ .x = 0.00, .y = 1.00, .z = 0.62, .w = 1.00 };
    style.Colors[c.ImGuiCol_Header] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.30 };
    style.Colors[c.ImGuiCol_HeaderHovered] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.50 };
    style.Colors[c.ImGuiCol_HeaderActive] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 1.00 };

    // Tabs
    style.Colors[c.ImGuiCol_Tab] = c.ImVec4{ .x = 0.05, .y = 0.05, .z = 0.10, .w = 1.00 };
    style.Colors[c.ImGuiCol_TabHovered] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 0.80 };
    style.Colors[c.ImGuiCol_TabActive] = c.ImVec4{ .x = 0.80, .y = 0.00, .z = 0.20, .w = 1.00 };

    // Misc
    style.Colors[c.ImGuiCol_TextSelectedBg] = c.ImVec4{ .x = 1.00, .y = 0.93, .z = 0.04, .w = 0.30 };
    style.Colors[c.ImGuiCol_NavHighlight] = c.ImVec4{ .x = 1.00, .y = 0.00, .z = 0.25, .w = 1.00 };
}

fn initImgui(root: *Root) error{ ImGuiCreateContext, ImGuiGlfwInit, ImGuiVulkanInit, ImGuiVulkanLoad }!void {
    _ = c.CIMGUI_CHECKVERSION();
    if (c.ImGui_CreateContext(null) == null) return error.ImGuiCreateContext;
    errdefer c.ImGui_DestroyContext(null);

    var io: *c.ImGuiIO = c.ImGui_GetIO();
    io.IniFilename = null;
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard | c.ImGuiConfigFlags_NavEnableGamepad;

    initImguiStyle();

    if (!c.cImGui_ImplGlfw_InitForVulkan(root.window, true)) return error.ImGuiGlfwInit;
    errdefer c.cImGui_ImplGlfw_Shutdown();

    var init_info: c.ImGui_ImplVulkan_InitInfo = .{
        .ApiVersion = VULKAN_API_VERSION,
        .Instance = root.instance,
        .PhysicalDevice = root.physical_device.handle,
        .Device = root.device,
        .QueueFamily = root.physical_device.queues.graphics.family,
        .Queue = root.physical_device.queues.graphics.handle,
        .PipelineCache = @ptrCast(c.VK_NULL_HANDLE),
        .DescriptorPool = root.descriptor_pool,
        .DescriptorPoolSize = 0,
        .UseDynamicRendering = false,
        .MinAllocationSize = 0,
        .MinImageCount = 2,
        .ImageCount = 2,
        .Allocator = null,
        .PipelineInfoMain = .{
            .RenderPass = root.render_pass,
            .Subpass = 0,
            .MSAASamples = c.VK_SAMPLE_COUNT_1_BIT,
            .ExtraDynamicStates = std.mem.zeroes(c.ImVector_VkDynamicState),
            .PipelineRenderingCreateInfo = std.mem.zeroes(c.VkPipelineRenderingCreateInfo),
        },
        .CheckVkResultFn = panic,
        .CustomShaderVertCreateInfo = std.mem.zeroes(c.VkShaderModuleCreateInfo),
        .CustomShaderFragCreateInfo = std.mem.zeroes(c.VkShaderModuleCreateInfo),
    };
    if (!c.cImGui_ImplVulkan_LoadFunctions(VULKAN_API_VERSION, imguiLoader)) return error.ImGuiVulkanLoad;

    if (!c.cImGui_ImplVulkan_Init(&init_info)) return error.ImGuiVulkanInit;
    errdefer c.cImGui_ImplVulkan_Shutdown();
}

fn deinitImgui() void {
    c.cImGui_ImplVulkan_Shutdown();
    c.cImGui_ImplGlfw_Shutdown();
    c.ImGui_DestroyContext(null);
}

fn drawImgui(root: *Root) (std.mem.Allocator.Error || error{ImGuiBegin})!void {
    c.cImGui_ImplVulkan_NewFrame();
    c.cImGui_ImplGlfw_NewFrame();
    c.ImGui_NewFrame();

    if (!root.imgui_window_created) {
        const window_pos: c.ImVec2 = .{ .x = 0.0, .y = 0.0 };
        const window_pivot: c.ImVec2 = .{ .x = 0.0, .y = 0.0 };

        c.ImGui_SetNextWindowPosEx(window_pos, 0, window_pivot);

        root.imgui_window_created = true;
    }

    var extent: c.VkExtent2D = undefined;
    glfwGetFramebufferSize(root.window, &extent.width, &extent.height);
    extent = .{
        .width = std.math.clamp(extent.width, root.physical_device.capabilities.minImageExtent.width, root.physical_device.capabilities.maxImageExtent.width),
        .height = std.math.clamp(extent.height, root.physical_device.capabilities.minImageExtent.height, root.physical_device.capabilities.maxImageExtent.height),
    };
    const window_size = c.ImVec2{ .x = 300.0, .y = @floatFromInt(extent.height) };
    c.ImGui_SetNextWindowSize(window_size, 0);

    const flags = c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoMove | c.ImGuiWindowFlags_NoResize | c.ImGuiWindowFlags_NoTitleBar;

    if (!root.imgui_window_hidden) {
        if (!c.ImGui_Begin("tweaker", null, flags)) return error.ImGuiBegin;
        defer c.ImGui_End();
        const io: *c.ImGuiIO = c.ImGui_GetIO();

        if (c.ImGui_CollapsingHeader("Help", 0)) {
            c.ImGui_BulletText("Press SPACE to hide/show this panel");
            c.ImGui_BulletText("Press ESPACE to close " ++ build.name);
        }

        if (c.ImGui_CollapsingHeader("Stats", 0)) {
            const fps_text = try std.fmt.allocPrintSentinel(root.init.gpa, "Average {d:.1} ms/frame ({d:.0} FPS)", .{ std.time.ms_per_s / io.Framerate, io.Framerate }, 0);
            defer root.init.gpa.free(fps_text);
            c.ImGui_Text(fps_text.ptr);
        }

        if (c.ImGui_CollapsingHeader("Settings", 0)) {
            const seed_text = try std.fmt.allocPrintSentinel(root.init.gpa, "Seed: {d}", .{root.seed}, 0);
            defer root.init.gpa.free(seed_text);
            if (c.ImGui_Button("New Seed")) {
                root.seed = root.random.int(u32);
                root.offscreen.render = true;
            }
            c.ImGui_SameLine();
            c.ImGui_Text(seed_text.ptr);
        }

        //if (c.ImGui_CollapsingHeader("Stars", 0)) {
    }

    c.ImGui_Render();
}

fn renderImGui(root: *Root) void {
    c.cImGui_ImplVulkan_RenderDrawDataEx(c.ImGui_GetDrawData(), root.command_buffers[root.current_frame], @ptrCast(c.VK_NULL_HANDLE));
}

fn initGLFW(root: *Root) error{ GLFWInit, GLFWCreateWindow, VulkanNotSupported }!void {
    if (c.glfwInit() != c.GLFW_TRUE) return error.GLFWInit;
    errdefer c.glfwTerminate();

    if (c.glfwVulkanSupported() == 0) return error.VulkanNotSupported;
    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);

    // This is the only disgusting way I found to get maximized size of a window in pixels with GLFW
    {
        c.glfwWindowHint(c.GLFW_MAXIMIZED, c.GLFW_TRUE);

        var hidden_window: *c.GLFWwindow = undefined;
        if (glfwCreateWindow(1, 1, "hidden", null, null)) |*win| {
            hidden_window = win.*;
        } else return error.GLFWCreateWindow;
        defer c.glfwDestroyWindow(hidden_window);

        glfwGetFramebufferSize(hidden_window, &root.max_extent.width, &root.max_extent.height);
    }

    if (root.init.environ_map.contains(build.upname ++ "_DEBUG") or std.mem.indexOf(u8, root.init.environ_map.get("VK_INSTANCE_LAYERS") orelse "", "VK_LAYER_KHRONOS_validation") != null) c.glfwWindowHint(c.GLFW_MAXIMIZED, c.GLFW_FALSE);
    const main_scale = c.cImGui_ImplGlfw_GetContentScaleForMonitor(c.glfwGetPrimaryMonitor());

    if (glfwCreateWindow(std.math.lossyCast(u32, main_scale * 1280.0), std.math.lossyCast(u32, main_scale * 800.0), build.name ++ " " ++ build.version, null, null)) |*win| {
        root.window = win.*;
    } else return error.GLFWCreateWindow;
    errdefer c.glfwDestroyWindow(root.window);

    c.glfwSetWindowUserPointer(root.window, root);
    _ = c.glfwSetErrorCallback(GLFWErrorCallback);
    _ = glfwSetFramebufferSizeCallback(root.window, GLFWFramebufferSizeCallback);
    _ = glfwSetWindowMaximizeCallback(root.window, GLFWWindowMaximizeCallback);
    _ = c.glfwSetKeyCallback(root.window, GLFWKeyCallback);

    var count: u32 = 0;
    if (c.glfwGetRequiredInstanceExtensions(&count)) |extensions|
        root.required_platform_extensions = @as([*][*:0]const u8, @ptrCast(extensions))[0..count];

    glfwGetFramebufferSize(root.window, &root.extent.width, &root.extent.height);
}

fn deinitGLFW(root: *Root) void {
    c.glfwDestroyWindow(root.window);
    c.glfwTerminate();
}

fn initInstance(root: *Root) error{ Vulkan, UnknownFunction }!void {
    if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) prototypes.debugLoadStructless() else prototypes.loadStructless();

    const app_info: c.VkApplicationInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pNext = null,
        .pApplicationName = build.name ++ " " ++ build.version,
        .applicationVersion = c.VK_MAKE_API_VERSION(0, 0, 0, 0),
        .pEngineName = "No Engine",
        .engineVersion = c.VK_MAKE_API_VERSION(0, 0, 0, 0),
        .apiVersion = VULKAN_API_VERSION,
    };

    const create_info: c.VkInstanceCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .pApplicationInfo = &app_info,
        .enabledExtensionCount = @intCast(root.required_platform_extensions.len),
        .ppEnabledExtensionNames = root.required_platform_extensions[0..].ptr,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = &[_][*:0]const u8{},
    };

    try errify(prototypes.vkCreateInstance(&create_info, null, &root.instance));
    errdefer prototypes.vkDestroyInstance(root.instance, null);

    if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) prototypes.debugLoadInstance(&root.instance) else prototypes.loadInstance(&root.instance);
}

fn deinitInstance(root: *Root) void {
    prototypes.vkDestroyInstance(root.instance, null);
}

fn initSurface(root: *Root) error{Vulkan}!void {
    try errify(c.glfwCreateWindowSurface(root.instance, root.window, null, &root.surface));
    errdefer prototypes.vkDestroySurfaceKHR(root.instance, root.surface, null);
}

fn deinitSurface(root: *Root) void {
    prototypes.vkDestroySurfaceKHR(root.instance, root.surface, null);
}

fn pickPhysicalDevice(root: *Root) (std.mem.Allocator.Error || error{ Vulkan, QueueFamilies, NoAvailablePhysicalDevice, NoSuitablePhysicalDevice })!void {
    var physical_device_count: u32 = undefined;

    try errify(prototypes.vkEnumeratePhysicalDevices(root.instance, &physical_device_count, null));

    if (physical_device_count == 0) return error.NoAvailablePhysicalDevice;

    const physical_devices = try root.init.gpa.alloc(c.VkPhysicalDevice, physical_device_count);
    defer root.init.gpa.free(physical_devices);

    try errify(prototypes.vkEnumeratePhysicalDevices(root.instance, &physical_device_count, physical_devices.ptr));

    for (physical_devices) |handle| {
        const physical_device = try PhysicalDevice.init(root, handle);
        if (physical_device.score() > root.physical_device.score()) root.physical_device = physical_device;
    }

    if (root.physical_device.score() == 0) return error.NoSuitablePhysicalDevice;
}

fn initLogicalDevice(root: *Root) (std.mem.Allocator.Error || error{ Vulkan, UnknownFunction })!void {
    var device_extensions: std.ArrayList([*:0]const u8) = .empty;
    try device_extensions.append(root.arena_allocator, "VK_KHR_swapchain");

    const queue_priorities = [_]f32{1.0};
    const device_queue_create_info = [_]c.VkDeviceQueueCreateInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = root.physical_device.queues.graphics.family,
            .queueCount = queue_priorities.len,
            .pQueuePriorities = &queue_priorities,
        },
        .{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = root.physical_device.queues.present.family,
            .queueCount = queue_priorities.len,
            .pQueuePriorities = &queue_priorities,
        },
    };

    const queue_count: u32 = if (root.physical_device.queues.graphics.family == root.physical_device.queues.present.family) 1 else 2;

    var physical_device_vk12_features: c.VkPhysicalDeviceVulkan12Features = .{
        .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
        .pNext = null,
        .shaderInt8 = c.VK_TRUE,
        .bufferDeviceAddress = c.VK_TRUE,
        .samplerMirrorClampToEdge = c.VK_FALSE,
        .drawIndirectCount = c.VK_FALSE,
        .storageBuffer8BitAccess = c.VK_FALSE,
        .uniformAndStorageBuffer8BitAccess = c.VK_FALSE,
        .storagePushConstant8 = c.VK_FALSE,
        .shaderBufferInt64Atomics = c.VK_FALSE,
        .shaderSharedInt64Atomics = c.VK_FALSE,
        .shaderFloat16 = c.VK_FALSE,
        .descriptorIndexing = c.VK_FALSE,
        .shaderInputAttachmentArrayDynamicIndexing = c.VK_FALSE,
        .shaderUniformTexelBufferArrayDynamicIndexing = c.VK_FALSE,
        .shaderStorageTexelBufferArrayDynamicIndexing = c.VK_FALSE,
        .shaderUniformBufferArrayNonUniformIndexing = c.VK_FALSE,
        .shaderSampledImageArrayNonUniformIndexing = c.VK_FALSE,
        .shaderStorageBufferArrayNonUniformIndexing = c.VK_FALSE,
        .shaderStorageImageArrayNonUniformIndexing = c.VK_FALSE,
        .shaderInputAttachmentArrayNonUniformIndexing = c.VK_FALSE,
        .shaderUniformTexelBufferArrayNonUniformIndexing = c.VK_FALSE,
        .shaderStorageTexelBufferArrayNonUniformIndexing = c.VK_FALSE,
        .descriptorBindingUniformBufferUpdateAfterBind = c.VK_FALSE,
        .descriptorBindingSampledImageUpdateAfterBind = c.VK_FALSE,
        .descriptorBindingStorageImageUpdateAfterBind = c.VK_FALSE,
        .descriptorBindingStorageBufferUpdateAfterBind = c.VK_FALSE,
        .descriptorBindingUniformTexelBufferUpdateAfterBind = c.VK_FALSE,
        .descriptorBindingStorageTexelBufferUpdateAfterBind = c.VK_FALSE,
        .descriptorBindingUpdateUnusedWhilePending = c.VK_FALSE,
        .descriptorBindingPartiallyBound = c.VK_FALSE,
        .descriptorBindingVariableDescriptorCount = c.VK_FALSE,
        .runtimeDescriptorArray = c.VK_FALSE,
        .samplerFilterMinmax = c.VK_FALSE,
        .scalarBlockLayout = c.VK_FALSE,
        .imagelessFramebuffer = c.VK_FALSE,
        .uniformBufferStandardLayout = c.VK_FALSE,
        .shaderSubgroupExtendedTypes = c.VK_FALSE,
        .separateDepthStencilLayouts = c.VK_FALSE,
        .hostQueryReset = c.VK_FALSE,
        .timelineSemaphore = c.VK_FALSE,
        .bufferDeviceAddressCaptureReplay = c.VK_FALSE,
        .bufferDeviceAddressMultiDevice = c.VK_FALSE,
        .vulkanMemoryModel = c.VK_FALSE,
        .vulkanMemoryModelDeviceScope = c.VK_FALSE,
        .vulkanMemoryModelAvailabilityVisibilityChains = c.VK_FALSE,
        .shaderOutputViewportIndex = c.VK_FALSE,
        .shaderOutputLayer = c.VK_FALSE,
        .subgroupBroadcastDynamicId = c.VK_FALSE,
    };

    const physical_device_features: c.VkPhysicalDeviceFeatures = .{
        .samplerAnisotropy = c.VK_TRUE,
        .shaderInt16 = c.VK_TRUE,
        .shaderInt64 = c.VK_TRUE,
        .robustBufferAccess = c.VK_FALSE,
        .fullDrawIndexUint32 = c.VK_FALSE,
        .imageCubeArray = c.VK_FALSE,
        .independentBlend = c.VK_FALSE,
        .geometryShader = c.VK_FALSE,
        .tessellationShader = c.VK_FALSE,
        .sampleRateShading = c.VK_FALSE,
        .dualSrcBlend = c.VK_FALSE,
        .logicOp = c.VK_FALSE,
        .multiDrawIndirect = c.VK_FALSE,
        .drawIndirectFirstInstance = c.VK_FALSE,
        .depthClamp = c.VK_FALSE,
        .depthBiasClamp = c.VK_FALSE,
        .fillModeNonSolid = c.VK_FALSE,
        .depthBounds = c.VK_FALSE,
        .wideLines = c.VK_FALSE,
        .largePoints = c.VK_FALSE,
        .alphaToOne = c.VK_FALSE,
        .multiViewport = c.VK_FALSE,
        .textureCompressionETC2 = c.VK_FALSE,
        .textureCompressionASTC_LDR = c.VK_FALSE,
        .textureCompressionBC = c.VK_FALSE,
        .occlusionQueryPrecise = c.VK_FALSE,
        .pipelineStatisticsQuery = c.VK_FALSE,
        .vertexPipelineStoresAndAtomics = c.VK_FALSE,
        .fragmentStoresAndAtomics = c.VK_FALSE,
        .shaderTessellationAndGeometryPointSize = c.VK_FALSE,
        .shaderImageGatherExtended = c.VK_FALSE,
        .shaderStorageImageExtendedFormats = c.VK_FALSE,
        .shaderStorageImageMultisample = c.VK_FALSE,
        .shaderStorageImageReadWithoutFormat = c.VK_FALSE,
        .shaderStorageImageWriteWithoutFormat = c.VK_FALSE,
        .shaderUniformBufferArrayDynamicIndexing = c.VK_FALSE,
        .shaderSampledImageArrayDynamicIndexing = c.VK_FALSE,
        .shaderStorageBufferArrayDynamicIndexing = c.VK_FALSE,
        .shaderStorageImageArrayDynamicIndexing = c.VK_FALSE,
        .shaderClipDistance = c.VK_FALSE,
        .shaderCullDistance = c.VK_FALSE,
        .shaderFloat64 = c.VK_FALSE,
        .shaderResourceResidency = c.VK_FALSE,
        .shaderResourceMinLod = c.VK_FALSE,
        .sparseBinding = c.VK_FALSE,
        .sparseResidencyBuffer = c.VK_FALSE,
        .sparseResidencyImage2D = c.VK_FALSE,
        .sparseResidencyImage3D = c.VK_FALSE,
        .sparseResidency2Samples = c.VK_FALSE,
        .sparseResidency4Samples = c.VK_FALSE,
        .sparseResidency8Samples = c.VK_FALSE,
        .sparseResidency16Samples = c.VK_FALSE,
        .sparseResidencyAliased = c.VK_FALSE,
        .variableMultisampleRate = c.VK_FALSE,
        .inheritedQueries = c.VK_FALSE,
    };

    var device_create_info: c.VkDeviceCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .flags = 0,
        .pNext = &physical_device_vk12_features,
        .queueCreateInfoCount = queue_count,
        .pQueueCreateInfos = &device_queue_create_info,
        .enabledExtensionCount = @intCast(root.physical_device.extensions.items.len),
        .ppEnabledExtensionNames = root.physical_device.extensions.items.ptr,
        .pEnabledFeatures = &physical_device_features,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = &[_][*:0]const u8{},
    };
    try errify(prototypes.vkCreateDevice(root.physical_device.handle, &device_create_info, null, &root.device));
    errdefer prototypes.vkDestroyDevice(root.device, null);

    if (root.init.environ_map.contains(build.upname ++ "_DEBUG")) prototypes.debugLoadDevice(&root.device) else prototypes.loadDevice(&root.device);

    prototypes.vkGetDeviceQueue(root.device, root.physical_device.queues.graphics.family, 0, &root.physical_device.queues.graphics.handle);
    prototypes.vkGetDeviceQueue(root.device, root.physical_device.queues.present.family, 0, &root.physical_device.queues.present.handle);
}

fn deinitLogicalDevice(root: *Root) void {
    prototypes.vkDestroyDevice(root.device, null);
}

fn initOffscreenImage(root: *Root) error{Vulkan}!void {
    const offscreen_image_create_info: c.VkImageCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .imageType = c.VK_IMAGE_TYPE_2D,
        .format = c.VK_FORMAT_R8G8B8A8_UNORM,
        .extent = .{
            .width = root.offscreen.extent.width,
            .height = root.offscreen.extent.height,
            .depth = 1,
        },
        .mipLevels = 1,
        .arrayLayers = root.offscreen.layers,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .tiling = c.VK_IMAGE_TILING_OPTIMAL,
        .usage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };

    try errify(prototypes.vkCreateImage(root.device, &offscreen_image_create_info, null, &root.offscreen.image));
    errdefer prototypes.vkDestroyImage(root.device, root.offscreen.image, null);
}

fn deinitOffscreenImage(root: *Root) void {
    prototypes.vkDestroyImage(root.device, root.offscreen.image, null);
}

fn initSwapchain(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    for (root.physical_device.surface_formats) |surface_format| {
        if (surface_format.format == c.VK_FORMAT_B8G8R8A8_SRGB and surface_format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
            root.surface_format = surface_format;
    } else root.surface_format = root.physical_device.surface_formats[0];

    const present_mode = blk: {
        for (root.physical_device.present_modes) |present_mode| {
            if (present_mode == c.VK_PRESENT_MODE_MAILBOX_KHR) break :blk present_mode;
        }

        break :blk c.VK_PRESENT_MODE_FIFO_KHR;
    };

    if (root.physical_device.capabilities.currentExtent.width != std.math.maxInt(u32)) {
        root.extent = root.physical_device.capabilities.currentExtent;
    } else {
        var extent: c.VkExtent2D = undefined;
        glfwGetFramebufferSize(root.window, &extent.width, &extent.height);
        root.extent = .{
            .width = std.math.clamp(extent.width, root.physical_device.capabilities.minImageExtent.width, root.physical_device.capabilities.maxImageExtent.width),
            .height = std.math.clamp(extent.height, root.physical_device.capabilities.minImageExtent.height, root.physical_device.capabilities.maxImageExtent.height),
        };
    }

    glfwSetWindowSizeLimits(root.window, 300, 300, root.physical_device.capabilities.maxImageExtent.width, root.physical_device.capabilities.maxImageExtent.height);

    var image_count = root.physical_device.capabilities.minImageCount + 1;

    if (root.physical_device.capabilities.maxImageCount > 0 and image_count > root.physical_device.capabilities.maxImageCount) {
        image_count = root.physical_device.capabilities.maxImageCount;
    }

    const queue_family_indices = [_]u32{
        root.physical_device.queues.graphics.family, root.physical_device.queues.present.family,
    };

    const swapchain_create_info: c.VkSwapchainCreateInfoKHR = .{
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .pNext = null,
        .flags = 0,
        .surface = root.surface,
        .minImageCount = image_count,
        .imageFormat = root.surface_format.format,
        .imageColorSpace = root.surface_format.colorSpace,
        .imageExtent = root.extent,
        .imageArrayLayers = 1,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
        .imageSharingMode = if (root.physical_device.queues.graphics.family != root.physical_device.queues.present.family) c.VK_SHARING_MODE_CONCURRENT else c.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = if (root.physical_device.queues.graphics.family != root.physical_device.queues.present.family) queue_family_indices.len else 0,
        .pQueueFamilyIndices = if (root.physical_device.queues.graphics.family != root.physical_device.queues.present.family) &queue_family_indices else null,
        .preTransform = root.physical_device.capabilities.currentTransform,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = present_mode,
        .clipped = c.VK_TRUE,
        .oldSwapchain = @ptrCast(c.VK_NULL_HANDLE),
    };

    try errify(prototypes.vkCreateSwapchainKHR(root.device, &swapchain_create_info, null, &root.swapchain));
    errdefer prototypes.vkDestroySwapchainKHR(root.device, root.swapchain, null);

    var swapchain_image_count: u32 = undefined;

    try errify(prototypes.vkGetSwapchainImagesKHR(root.device, root.swapchain, &swapchain_image_count, null));

    root.images = try root.init.gpa.alloc(c.VkImage, swapchain_image_count);
    errdefer root.init.gpa.free(root.images);

    try errify(prototypes.vkGetSwapchainImagesKHR(root.device, root.swapchain, &swapchain_image_count, root.images.ptr));
}

fn deinitOnscreenImage(root: *Root) void {
    root.init.gpa.free(root.images);
}

fn deinitSwapchain(root: *Root) void {
    prototypes.vkDestroySwapchainKHR(root.device, root.swapchain, null);
}

fn initGeometryBuffer(root: *Root) error{Vulkan}!void {
    const alignment = @max(root.physical_device.min_uniform_buffer_offset_alignment, root.physical_device.non_coherent_atom_size);
    const staging_buffer_create_info: c.VkBufferCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .size = alignUp(@sizeOf(@TypeOf(vertices)) + @sizeOf(@TypeOf(indices)), alignment),
        .usage = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };

    try errify(prototypes.vkCreateBuffer(root.device, &staging_buffer_create_info, null, &root.staging_buffer));
    errdefer prototypes.vkDestroyBuffer(root.device, root.staging_buffer, null);

    const buffer_create_info: c.VkBufferCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .size = @sizeOf(@TypeOf(vertices)) + @sizeOf(@TypeOf(indices)),
        .usage = c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };

    try errify(prototypes.vkCreateBuffer(root.device, &buffer_create_info, null, &root.geometry_buffer));
    errdefer prototypes.vkDestroyBuffer(root.device, root.geometry_buffer, null);
}

fn deinitGeometryBuffer(root: *Root) void {
    prototypes.vkDestroyBuffer(root.device, root.geometry_buffer, null);
    prototypes.vkDestroyBuffer(root.device, root.staging_buffer, null);
}

fn initUniformBuffers(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    const alignment = @max(root.physical_device.min_uniform_buffer_offset_alignment, root.physical_device.non_coherent_atom_size);
    const uniform_buffer_create_info: c.VkBufferCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .size = alignUp(@sizeOf(shader.OffscreenUBO), alignment) * root.offscreen.layers + alignUp(@sizeOf(shader.OnscreenUBO), alignment) * MAX_FRAMES_IN_FLIGHT,
        .usage = c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };

    try errify(prototypes.vkCreateBuffer(root.device, &uniform_buffer_create_info, null, &root.uniform_buffer));
    errdefer prototypes.vkDestroyBuffer(root.device, root.uniform_buffer, null);
}

fn deinitUniformBuffers(root: *Root) void {
    prototypes.vkDestroyBuffer(root.device, root.uniform_buffer, null);
}

fn findMemoryType(root: *Root, type_filter: u32, memory_properties: c.VkMemoryPropertyFlags) error{NoSuitableMemoryType}!u32 {
    var physical_device_memory_properties: c.VkPhysicalDeviceMemoryProperties = undefined;
    prototypes.vkGetPhysicalDeviceMemoryProperties(root.physical_device.handle, &physical_device_memory_properties);

    for (physical_device_memory_properties.memoryTypes[0..physical_device_memory_properties.memoryTypeCount], 0..) |memory_type, index| {
        if (type_filter & (@as(u32, 1) << @truncate(index)) != 0 and memory_type.propertyFlags & memory_properties == memory_properties) {
            return @truncate(index);
        }
    }

    return error.NoSuitableMemoryType;
}

fn computeMemoryOffset(memory_requirements: c.VkMemoryRequirements, memory_offset: *c.VkDeviceSize) void {
    memory_offset.* = alignUp(memory_offset.* + memory_requirements.size, memory_requirements.alignment);
}

fn allocMemory(root: *Root) error{ Vulkan, NoSuitableMemoryType }!void {
    var alignment: c.VkDeviceSize = 0;
    var allocation_size: c.VkDeviceSize = 0;
    var memory_type_bits: u32 = 0;
    var memory_offset: c.VkDeviceSize = 0;

    var geometry_buffer_memory_requirements: c.VkMemoryRequirements = undefined;
    prototypes.vkGetBufferMemoryRequirements(root.device, root.geometry_buffer, &geometry_buffer_memory_requirements);

    var offscreen_image_memory_requirements: c.VkMemoryRequirements = undefined;
    prototypes.vkGetImageMemoryRequirements(root.device, root.offscreen.image, &offscreen_image_memory_requirements);

    const device_local_memory_requirements = [_]c.VkMemoryRequirements{
        geometry_buffer_memory_requirements, offscreen_image_memory_requirements,
    };

    for (device_local_memory_requirements) |memory_requirements| {
        alignment = @max(memory_requirements.alignment, root.physical_device.buffer_image_granularity);
        allocation_size = alignUp(allocation_size, alignment);
        allocation_size += memory_requirements.size;
        memory_type_bits |= memory_requirements.memoryTypeBits;
    }

    const device_local_memory_alloc_info: c.VkMemoryAllocateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = null,
        .allocationSize = allocation_size,
        .memoryTypeIndex = try findMemoryType(root, memory_type_bits, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
    };

    try errify(prototypes.vkAllocateMemory(root.device, &device_local_memory_alloc_info, null, &root.memory.device_local.handle));
    errdefer prototypes.vkFreeMemory(root.device, root.memory.device_local.handle, null);

    root.memory.device_local.offset.geometry_buffer = memory_offset;
    root.memory.device_local.offset.vertex_buffer = root.memory.device_local.offset.geometry_buffer;
    root.memory.device_local.offset.index_buffer = root.memory.device_local.offset.vertex_buffer + @sizeOf(@TypeOf(vertices));
    try errify(prototypes.vkBindBufferMemory(root.device, root.geometry_buffer, root.memory.device_local.handle, memory_offset));

    computeMemoryOffset(geometry_buffer_memory_requirements, &memory_offset);
    root.memory.device_local.offset.offscreen_image = memory_offset;
    try errify(prototypes.vkBindImageMemory(root.device, root.offscreen.image, root.memory.device_local.handle, memory_offset));

    allocation_size = 0;
    memory_type_bits = 0;
    memory_offset = 0;

    var staging_buffer_memory_requirements: c.VkMemoryRequirements = undefined;
    prototypes.vkGetBufferMemoryRequirements(root.device, root.staging_buffer, &staging_buffer_memory_requirements);

    var uniform_buffer_memory_requirements: c.VkMemoryRequirements = undefined;
    prototypes.vkGetBufferMemoryRequirements(root.device, root.uniform_buffer, &uniform_buffer_memory_requirements);

    const host_visible_memory_requirements = [_]c.VkMemoryRequirements{
        staging_buffer_memory_requirements, uniform_buffer_memory_requirements,
    };

    for (host_visible_memory_requirements) |memory_requirements| {
        alignment = @max(memory_requirements.alignment, root.physical_device.min_uniform_buffer_offset_alignment, root.physical_device.non_coherent_atom_size);
        allocation_size = alignUp(allocation_size, alignment);
        allocation_size += memory_requirements.size;
        memory_type_bits |= memory_requirements.memoryTypeBits;
    }

    const host_visible_memory_alloc_info: c.VkMemoryAllocateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = null,
        .allocationSize = allocation_size,
        .memoryTypeIndex = try findMemoryType(root, memory_type_bits, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT),
    };

    try errify(prototypes.vkAllocateMemory(root.device, &host_visible_memory_alloc_info, null, &root.memory.host_visible.handle));
    errdefer prototypes.vkFreeMemory(root.device, root.memory.host_visible.handle, null);

    root.memory.host_visible.offset.staging_buffer = memory_offset;
    root.memory.host_visible.offset.staging_vertex_buffer = root.memory.host_visible.offset.staging_buffer;
    root.memory.host_visible.offset.staging_index_buffer = root.memory.host_visible.offset.staging_vertex_buffer + @sizeOf(@TypeOf(vertices));
    try errify(prototypes.vkBindBufferMemory(root.device, root.staging_buffer, root.memory.host_visible.handle, memory_offset));

    computeMemoryOffset(staging_buffer_memory_requirements, &memory_offset);
    root.memory.host_visible.offset.uniform_buffer = memory_offset;
    root.memory.host_visible.offset.onscreen_uniform_buffer[0] = root.memory.host_visible.offset.uniform_buffer;
    alignment = @max(root.physical_device.min_uniform_buffer_offset_alignment, root.physical_device.non_coherent_atom_size);
    root.memory.host_visible.offset.onscreen_uniform_buffer[1] = root.memory.host_visible.offset.onscreen_uniform_buffer[0] + alignUp(@sizeOf(shader.OnscreenUBO), alignment);
    root.memory.host_visible.offset.offscreen_uniform_buffer = root.memory.host_visible.offset.onscreen_uniform_buffer[1] + alignUp(@sizeOf(shader.OnscreenUBO), alignment);
    try errify(prototypes.vkBindBufferMemory(root.device, root.uniform_buffer, root.memory.host_visible.handle, memory_offset));
}

fn freeMemory(root: *Root) void {
    prototypes.vkFreeMemory(root.device, root.memory.device_local.handle, null);
    prototypes.vkFreeMemory(root.device, root.memory.host_visible.handle, null);
}

fn initOffscreenImageViews(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    const offscreen_array_image_view_create_info: c.VkImageViewCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .viewType = c.VK_IMAGE_VIEW_TYPE_2D_ARRAY,
        .format = c.VK_FORMAT_R8G8B8A8_UNORM,
        .subresourceRange = .{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = root.offscreen.layers,
        },
        .image = root.offscreen.image,
        .components = .{
            .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
    };

    try errify(prototypes.vkCreateImageView(root.device, &offscreen_array_image_view_create_info, null, &root.offscreen.views.array));
    errdefer prototypes.vkDestroyImageView(root.device, root.offscreen.views.array, null);

    root.offscreen.views.layers = try root.init.gpa.alloc(c.VkImageView, root.offscreen.layers);
    errdefer root.init.gpa.free(root.offscreen.views.layers);

    var offscreen_layer_image_view_create_info: c.VkImageViewCreateInfo = undefined;
    for (0..root.offscreen.layers) |index| {
        offscreen_layer_image_view_create_info = .{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .image = root.offscreen.image,
            .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
            .format = c.VK_FORMAT_R8G8B8A8_UNORM,
            .components = .{
                .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            },
            .subresourceRange = .{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = @intCast(index),
                .layerCount = 1,
            },
        };

        try errify(prototypes.vkCreateImageView(root.device, &offscreen_layer_image_view_create_info, null, &root.offscreen.views.layers[index]));
        errdefer prototypes.vkDestroyImageView(root.device, root.offscreen.views.layers[index], null);
    }
}

fn deinitOffscreenImageViews(root: *Root) void {
    for (0..root.offscreen.layers) |index| prototypes.vkDestroyImageView(root.device, root.offscreen.views.layers[index], null);
    root.init.gpa.free(root.offscreen.views.layers);
    prototypes.vkDestroyImageView(root.device, root.offscreen.views.array, null);
}

fn initOnscreenImageViews(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    var image_view_create_info: c.VkImageViewCreateInfo = undefined;

    root.views = try root.init.gpa.alloc(c.VkImageView, root.images.len);
    errdefer root.init.gpa.free(root.views);

    for (0..root.images.len) |index| {
        image_view_create_info = .{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .image = root.images[index],
            .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
            .format = root.surface_format.format,
            .components = .{
                .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            },
            .subresourceRange = .{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        };

        try errify(prototypes.vkCreateImageView(root.device, &image_view_create_info, null, &root.views[index]));
        errdefer prototypes.vkDestroyImageView(root.device, root.views[index], null);
    }
}

fn deinitOnscreenImageViews(root: *Root) void {
    for (0..root.views.len) |index| prototypes.vkDestroyImageView(root.device, root.views[index], null);
    root.init.gpa.free(root.views);
}

fn initOffscreenSampler(root: *Root) error{Vulkan}!void {
    const offscreen_sampler_create_info: c.VkSamplerCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .magFilter = c.VK_FILTER_NEAREST,
        .minFilter = c.VK_FILTER_NEAREST,
        .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_NEAREST,
        .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
        .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
        .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
        .mipLodBias = 0.0,
        .anisotropyEnable = c.VK_TRUE,
        .maxAnisotropy = 1.0,
        .minLod = 0.0,
        .maxLod = 1.0,
        .borderColor = c.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
        .compareEnable = c.VK_FALSE,
        .compareOp = c.VK_COMPARE_OP_ALWAYS,
        .unnormalizedCoordinates = c.VK_FALSE,
    };

    try errify(prototypes.vkCreateSampler(root.device, &offscreen_sampler_create_info, null, &root.offscreen.sampler));
    errdefer prototypes.vkDestroySampler(root.device, root.offscreen.sampler, null);
}

fn deinitOffscreenSampler(root: *Root) void {
    prototypes.vkDestroySampler(root.device, root.offscreen.sampler, null);
}

fn initRenderPasses(root: *Root) error{Vulkan}!void {
    const offscreen_attachment_descriptions = [_]c.VkAttachmentDescription{
        .{
            .flags = 0,
            .format = c.VK_FORMAT_R8G8B8A8_UNORM,
            .samples = c.VK_SAMPLE_COUNT_1_BIT,
            .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
            .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
            .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
            .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .finalLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        },
    };

    const offscreen_attachment_references = [_]c.VkAttachmentReference{
        .{
            .attachment = 0,
            .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        },
    };

    const offscreen_subpass_descriptions = [_]c.VkSubpassDescription{
        .{
            .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            .flags = 0,
            .colorAttachmentCount = offscreen_attachment_references.len,
            .pColorAttachments = &offscreen_attachment_references,
            .inputAttachmentCount = 0,
            .pInputAttachments = null,
            .pResolveAttachments = null,
            .pDepthStencilAttachment = null,
            .preserveAttachmentCount = 0,
            .pPreserveAttachments = null,
        },
    };

    const offscreen_subpass_dependencies = [_]c.VkSubpassDependency{
        .{
            .srcSubpass = c.VK_SUBPASS_EXTERNAL,
            .dstSubpass = 0,
            .srcStageMask = c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
            .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            .srcAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
            .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            .dependencyFlags = c.VK_DEPENDENCY_BY_REGION_BIT,
        },
        .{
            .srcSubpass = 0,
            .dstSubpass = c.VK_SUBPASS_EXTERNAL,
            .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            .dstStageMask = c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
            .srcAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
            .dependencyFlags = c.VK_DEPENDENCY_BY_REGION_BIT,
        },
    };

    const offscreen_render_pass_create_info: c.VkRenderPassCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .attachmentCount = offscreen_attachment_descriptions.len,
        .pAttachments = &offscreen_attachment_descriptions,
        .subpassCount = offscreen_subpass_descriptions.len,
        .pSubpasses = &offscreen_subpass_descriptions,
        .dependencyCount = offscreen_subpass_dependencies.len,
        .pDependencies = &offscreen_subpass_dependencies,
    };

    try errify(prototypes.vkCreateRenderPass(root.device, &offscreen_render_pass_create_info, null, &root.offscreen.render_pass));
    errdefer prototypes.vkDestroyRenderPass(root.device, root.offscreen.render_pass, null);

    const onscreen_attachment_descriptions = [_]c.VkAttachmentDescription{
        .{
            .flags = 0,
            .format = root.surface_format.format,
            .samples = c.VK_SAMPLE_COUNT_1_BIT,
            .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
            .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
            .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
            .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        },
    };

    const onscreen_attachment_references = [_]c.VkAttachmentReference{
        .{
            .attachment = 0,
            .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        },
    };

    const onscreen_subpass_descriptions = [_]c.VkSubpassDescription{
        .{
            .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            .colorAttachmentCount = onscreen_attachment_references.len,
            .pColorAttachments = &onscreen_attachment_references,
            .flags = 0,
            .inputAttachmentCount = 0,
            .pInputAttachments = null,
            .pResolveAttachments = null,
            .pDepthStencilAttachment = null,
            .preserveAttachmentCount = 0,
            .pPreserveAttachments = null,
        },
    };

    const onscreen_subpass_dependencies = [_]c.VkSubpassDependency{
        .{
            .srcSubpass = c.VK_SUBPASS_EXTERNAL,
            .dstSubpass = 0,
            .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            .srcAccessMask = 0,
            .dstAccessMask = 0,
            .dependencyFlags = 0,
        },
    };

    const onscreen_render_pass_create_info: c.VkRenderPassCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .attachmentCount = onscreen_attachment_descriptions.len,
        .pAttachments = &onscreen_attachment_descriptions,
        .subpassCount = onscreen_subpass_descriptions.len,
        .pSubpasses = &onscreen_subpass_descriptions,
        .dependencyCount = onscreen_subpass_dependencies.len,
        .pDependencies = &onscreen_subpass_dependencies,
    };

    try errify(prototypes.vkCreateRenderPass(root.device, &onscreen_render_pass_create_info, null, &root.render_pass));
    errdefer prototypes.vkDestroyRenderPass(root.device, root.render_pass, null);
}

fn deinitRenderPasses(root: *Root) void {
    prototypes.vkDestroyRenderPass(root.device, root.render_pass, null);
    prototypes.vkDestroyRenderPass(root.device, root.offscreen.render_pass, null);
}

fn initDescriptorSetLayouts(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    const offscreen_ubo_layout_bindings = [_]c.VkDescriptorSetLayoutBinding{
        .{
            .binding = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
            .descriptorCount = 1,
            .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .pImmutableSamplers = null,
        },
    };

    const onscreen_ubo_layout_bindings = [_]c.VkDescriptorSetLayoutBinding{
        .{
            .binding = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
            .descriptorCount = 1,
            .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .pImmutableSamplers = null,
        },
        .{
            .binding = 1,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1,
            .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .pImmutableSamplers = null,
        },
    };

    const offscreen_descriptor_set_layout_create_info: c.VkDescriptorSetLayoutCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .bindingCount = offscreen_ubo_layout_bindings.len,
        .pBindings = &offscreen_ubo_layout_bindings,
    };

    const onscreen_descriptor_set_layout_create_info: c.VkDescriptorSetLayoutCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .bindingCount = onscreen_ubo_layout_bindings.len,
        .pBindings = &onscreen_ubo_layout_bindings,
    };

    root.offscreen.descriptor_set_layouts = try root.init.gpa.alloc(c.VkDescriptorSetLayout, 1);
    errdefer root.init.gpa.free(root.offscreen.descriptor_set_layouts);

    try errify(prototypes.vkCreateDescriptorSetLayout(root.device, &offscreen_descriptor_set_layout_create_info, null, &root.offscreen.descriptor_set_layouts[0]));
    errdefer prototypes.vkDestroyDescriptorSetLayout(root.device, root.offscreen.descriptor_set_layouts[0], null);

    root.descriptor_set_layouts = try root.init.gpa.alloc(c.VkDescriptorSetLayout, 1);
    errdefer root.init.gpa.free(root.descriptor_set_layouts);

    try errify(prototypes.vkCreateDescriptorSetLayout(root.device, &onscreen_descriptor_set_layout_create_info, null, &root.descriptor_set_layouts[0]));
    errdefer prototypes.vkDestroyDescriptorSetLayout(root.device, root.descriptor_set_layouts[0], null);
}

fn deinitDescriptorSetLayouts(root: *Root) void {
    prototypes.vkDestroyDescriptorSetLayout(root.device, root.descriptor_set_layouts[0], null);
    root.init.gpa.free(root.descriptor_set_layouts);
    prototypes.vkDestroyDescriptorSetLayout(root.device, root.offscreen.descriptor_set_layouts[0], null);
    root.init.gpa.free(root.offscreen.descriptor_set_layouts);
}

fn initGraphicsPipelines(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    const fullscreen_vertex_shader_module_code = @embedFile("fullscreen.vert.spv");
    var fullscreen_vertex_shader_module: c.VkShaderModule = undefined;
    const fullscreen_vertex_shader_module_create_info: c.VkShaderModuleCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .codeSize = fullscreen_vertex_shader_module_code.len,
        .pCode = @ptrCast(@alignCast(fullscreen_vertex_shader_module_code.ptr)),
    };
    try errify(prototypes.vkCreateShaderModule(root.device, &fullscreen_vertex_shader_module_create_info, null, &fullscreen_vertex_shader_module));
    defer prototypes.vkDestroyShaderModule(root.device, fullscreen_vertex_shader_module, null);

    const onscreen_fragment_shader_module_code = @embedFile("onscreen.frag.spv");
    var onscreen_fragment_shader_module: c.VkShaderModule = undefined;
    const onscreen_fragment_shader_module_create_info: c.VkShaderModuleCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .codeSize = onscreen_fragment_shader_module_code.len,
        .pCode = @ptrCast(@alignCast(onscreen_fragment_shader_module_code.ptr)),
    };
    try errify(prototypes.vkCreateShaderModule(root.device, &onscreen_fragment_shader_module_create_info, null, &onscreen_fragment_shader_module));
    defer prototypes.vkDestroyShaderModule(root.device, onscreen_fragment_shader_module, null);

    const offscreen_fragment_shader_module_code = @embedFile("offscreen.frag.spv");
    var offscreen_fragment_shader_module: c.VkShaderModule = undefined;
    const offscreen_fragment_shader_module_create_info: c.VkShaderModuleCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .codeSize = offscreen_fragment_shader_module_code.len,
        .pCode = @ptrCast(@alignCast(offscreen_fragment_shader_module_code.ptr)),
    };
    try errify(prototypes.vkCreateShaderModule(root.device, &offscreen_fragment_shader_module_create_info, null, &offscreen_fragment_shader_module));
    defer prototypes.vkDestroyShaderModule(root.device, offscreen_fragment_shader_module, null);

    const offscreen_pipeline_shader_stage_create_infos = [_]c.VkPipelineShaderStageCreateInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
            .module = fullscreen_vertex_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
        },
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .module = offscreen_fragment_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
        },
    };

    const onscreen_pipeline_shader_stage_create_infos = [_]c.VkPipelineShaderStageCreateInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
            .module = fullscreen_vertex_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
        },
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .module = onscreen_fragment_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
        },
    };

    const dynamic_states = [_]c.VkDynamicState{
        c.VK_DYNAMIC_STATE_VIEWPORT, c.VK_DYNAMIC_STATE_SCISSOR,
    };

    const pipeline_dynamic_state_create_info: c.VkPipelineDynamicStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .dynamicStateCount = dynamic_states.len,
        .pDynamicStates = &dynamic_states,
    };

    const vertex_input_binding_descriptions = [_]c.VkVertexInputBindingDescription{
        .{
            .binding = 0,
            .stride = @sizeOf(shader.Vec2),
            .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
        },
    };

    const vertex_input_attribute_descriptions = [_]c.VkVertexInputAttributeDescription{
        .{
            .binding = 0,
            .location = 0,
            .format = c.VK_FORMAT_R32G32_SFLOAT,
            .offset = 0,
        },
    };

    const pipeline_vertex_input_state_create_info: c.VkPipelineVertexInputStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .vertexBindingDescriptionCount = vertex_input_binding_descriptions.len,
        .pVertexBindingDescriptions = &vertex_input_binding_descriptions,
        .vertexAttributeDescriptionCount = vertex_input_attribute_descriptions.len,
        .pVertexAttributeDescriptions = &vertex_input_attribute_descriptions,
    };

    const pipeline_input_assembly_state_create_info: c.VkPipelineInputAssemblyStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = c.VK_FALSE,
    };

    root.viewports = [_]c.VkViewport{
        .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(root.max_extent.width),
            .height = @floatFromInt(root.max_extent.height),
            .minDepth = 0,
            .maxDepth = 1,
        },
    };

    root.scissors = [_]c.VkRect2D{
        .{
            .offset = .{
                .x = 0,
                .y = 0,
            },
            .extent = root.max_extent,
        },
    };

    const pipeline_viewport_state_create_info: c.VkPipelineViewportStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .viewportCount = root.viewports.len,
        .pViewports = &root.viewports,
        .scissorCount = root.scissors.len,
        .pScissors = &root.scissors,
    };

    const pipeline_rasterization_state_create_info: c.VkPipelineRasterizationStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .depthClampEnable = c.VK_FALSE,
        .rasterizerDiscardEnable = c.VK_FALSE,
        .polygonMode = c.VK_POLYGON_MODE_FILL,
        .lineWidth = 1,
        .cullMode = c.VK_CULL_MODE_BACK_BIT,
        .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
        .depthBiasEnable = c.VK_FALSE,
        .depthBiasConstantFactor = 0,
        .depthBiasClamp = 0,
        .depthBiasSlopeFactor = 0,
    };

    const pipeline_multisample_state_create_info: c.VkPipelineMultisampleStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .sampleShadingEnable = c.VK_FALSE,
        .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
        .minSampleShading = 1,
        .pSampleMask = null,
        .alphaToCoverageEnable = c.VK_FALSE,
        .alphaToOneEnable = c.VK_FALSE,
    };

    const pipeline_depth_stencil_state_create_info = c.VkPipelineDepthStencilStateCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .depthTestEnable = c.VK_TRUE,
        .depthWriteEnable = c.VK_TRUE,
        .depthCompareOp = c.VK_COMPARE_OP_LESS,
        .depthBoundsTestEnable = c.VK_FALSE,
        .stencilTestEnable = c.VK_FALSE,
        .front = std.mem.zeroes(c.VkStencilOpState),
        .back = std.mem.zeroes(c.VkStencilOpState),
        .minDepthBounds = 0.0,
        .maxDepthBounds = 0.0,
    };

    const pipeline_color_blend_attachment_states = [_]c.VkPipelineColorBlendAttachmentState{
        .{
            .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
            .blendEnable = c.VK_FALSE,
            .srcColorBlendFactor = c.VK_BLEND_FACTOR_ONE,
            .dstColorBlendFactor = c.VK_BLEND_FACTOR_ZERO,
            .colorBlendOp = c.VK_BLEND_OP_ADD,
            .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
            .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
            .alphaBlendOp = c.VK_BLEND_OP_ADD,
        },
    };

    const pipeline_color_blend_state_create_info: c.VkPipelineColorBlendStateCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .logicOpEnable = c.VK_FALSE,
        .logicOp = c.VK_LOGIC_OP_COPY,
        .attachmentCount = pipeline_color_blend_attachment_states.len,
        .pAttachments = &pipeline_color_blend_attachment_states,
        .blendConstants = @splat(0.0),
    };

    const offscreen_pipeline_layout_create_info: c.VkPipelineLayoutCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .setLayoutCount = @intCast(root.offscreen.descriptor_set_layouts.len),
        .pSetLayouts = root.offscreen.descriptor_set_layouts.ptr,
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = undefined,
    };

    const onscreen_pipeline_layout_create_info: c.VkPipelineLayoutCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .setLayoutCount = @intCast(root.descriptor_set_layouts.len),
        .pSetLayouts = root.descriptor_set_layouts.ptr,
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = undefined,
    };

    try errify(prototypes.vkCreatePipelineLayout(root.device, &offscreen_pipeline_layout_create_info, null, &root.offscreen.pipelines.layout));
    errdefer prototypes.vkDestroyPipelineLayout(root.device, root.offscreen.pipelines.layout, null);

    try errify(prototypes.vkCreatePipelineLayout(root.device, &onscreen_pipeline_layout_create_info, null, &root.pipelines.layout));
    errdefer prototypes.vkDestroyPipelineLayout(root.device, root.pipelines.layout, null);

    const offscreen_graphics_pipeline_create_infos = [_]c.VkGraphicsPipelineCreateInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .stageCount = offscreen_pipeline_shader_stage_create_infos.len,
            .pStages = &offscreen_pipeline_shader_stage_create_infos,
            .pVertexInputState = &pipeline_vertex_input_state_create_info,
            .pInputAssemblyState = &pipeline_input_assembly_state_create_info,
            .pViewportState = &pipeline_viewport_state_create_info,
            .pRasterizationState = &pipeline_rasterization_state_create_info,
            .pMultisampleState = &pipeline_multisample_state_create_info,
            .pDepthStencilState = &pipeline_depth_stencil_state_create_info,
            .pColorBlendState = &pipeline_color_blend_state_create_info,
            .pDynamicState = &pipeline_dynamic_state_create_info,
            .pTessellationState = null,
            .layout = root.offscreen.pipelines.layout,
            .renderPass = root.offscreen.render_pass,
            .subpass = 0,
            .basePipelineHandle = @ptrCast(c.VK_NULL_HANDLE),
            .basePipelineIndex = 0,
        },
    };

    const onscreen_graphics_pipeline_create_infos = [_]c.VkGraphicsPipelineCreateInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .stageCount = onscreen_pipeline_shader_stage_create_infos.len,
            .pStages = &onscreen_pipeline_shader_stage_create_infos,
            .pVertexInputState = &pipeline_vertex_input_state_create_info,
            .pInputAssemblyState = &pipeline_input_assembly_state_create_info,
            .pViewportState = &pipeline_viewport_state_create_info,
            .pRasterizationState = &pipeline_rasterization_state_create_info,
            .pMultisampleState = &pipeline_multisample_state_create_info,
            .pDepthStencilState = &pipeline_depth_stencil_state_create_info,
            .pColorBlendState = &pipeline_color_blend_state_create_info,
            .pDynamicState = &pipeline_dynamic_state_create_info,
            .pTessellationState = null,
            .layout = root.pipelines.layout,
            .renderPass = root.render_pass,
            .subpass = 0,
            .basePipelineHandle = @ptrCast(c.VK_NULL_HANDLE),
            .basePipelineIndex = 0,
        },
    };

    root.offscreen.pipelines.handles = try root.init.gpa.alloc(c.VkPipeline, 1);
    errdefer root.init.gpa.free(root.offscreen.pipelines.handles);

    try errify(prototypes.vkCreateGraphicsPipelines(root.device, @ptrCast(c.VK_NULL_HANDLE), offscreen_graphics_pipeline_create_infos.len, &offscreen_graphics_pipeline_create_infos, null, root.offscreen.pipelines.handles.ptr));
    errdefer prototypes.vkDestroyPipeline(root.device, root.offscreen.pipelines.handles[0], null);

    root.pipelines.handles = try root.init.gpa.alloc(c.VkPipeline, 1);
    errdefer root.init.gpa.free(root.pipelines.handles);

    try errify(prototypes.vkCreateGraphicsPipelines(root.device, @ptrCast(c.VK_NULL_HANDLE), onscreen_graphics_pipeline_create_infos.len, &onscreen_graphics_pipeline_create_infos, null, root.pipelines.handles.ptr));
    errdefer prototypes.vkDestroyPipeline(root.device, root.pipelines.handles[0], null);
}

fn deinitGraphicsPipelines(root: *Root) void {
    prototypes.vkDestroyPipeline(root.device, root.pipelines.handles[0], null);
    root.init.gpa.free(root.pipelines.handles);
    prototypes.vkDestroyPipeline(root.device, root.offscreen.pipelines.handles[0], null);
    root.init.gpa.free(root.offscreen.pipelines.handles);
}

fn deinitPipelineLayouts(root: *Root) void {
    prototypes.vkDestroyPipelineLayout(root.device, root.pipelines.layout, null);
    prototypes.vkDestroyPipelineLayout(root.device, root.offscreen.pipelines.layout, null);
}

fn initOffscreenFramebuffers(root: *Root) error{ OutOfMemory, Vulkan }!void {
    root.offscreen.framebuffers = try root.init.gpa.alloc(c.VkFramebuffer, root.offscreen.layers);
    errdefer root.init.gpa.free(root.offscreen.framebuffers);

    var offscreen_framebuffer_create_info: c.VkFramebufferCreateInfo = undefined;

    for (0..root.offscreen.layers) |index| {
        const offscreen_framebuffer_attachments = [_]c.VkImageView{root.offscreen.views.layers[index]};

        offscreen_framebuffer_create_info = .{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .renderPass = root.offscreen.render_pass,
            .attachmentCount = offscreen_framebuffer_attachments.len,
            .pAttachments = &offscreen_framebuffer_attachments,
            .width = root.offscreen.extent.width,
            .height = root.offscreen.extent.height,
            .layers = 1,
        };

        try errify(prototypes.vkCreateFramebuffer(root.device, &offscreen_framebuffer_create_info, null, &root.offscreen.framebuffers[index]));
        errdefer prototypes.vkDestroyFramebuffer(root.device, root.offscreen.framebuffers[index], null);
    }
}

fn deinitOffscreenFramebuffers(root: *Root) void {
    for (0..root.offscreen.layers) |index| prototypes.vkDestroyFramebuffer(root.device, root.offscreen.framebuffers[index], null);
    root.init.gpa.free(root.offscreen.framebuffers);
}

fn initOnscreenFramebuffers(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    root.framebuffers = try root.init.gpa.alloc(c.VkFramebuffer, root.views.len);
    errdefer root.init.gpa.free(root.framebuffers);

    var framebuffer_create_info: c.VkFramebufferCreateInfo = undefined;
    var attachments: [1]c.VkImageView = undefined;

    for (0..root.views.len) |index| {
        attachments = .{root.views[index]};
        framebuffer_create_info = .{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .renderPass = root.render_pass,
            .attachmentCount = attachments.len,
            .pAttachments = &attachments,
            .width = root.extent.width,
            .height = root.extent.height,
            .layers = 1,
        };

        try errify(prototypes.vkCreateFramebuffer(root.device, &framebuffer_create_info, null, &root.framebuffers[index]));
        errdefer prototypes.vkDestroyFramebuffer(root.device, root.framebuffers[index], null);
    }
}

fn deinitOnscreenFramebuffers(root: *Root) void {
    for (0..root.framebuffers.len) |index| prototypes.vkDestroyFramebuffer(root.device, root.framebuffers[index], null);
    root.init.gpa.free(root.framebuffers);
}

fn initCommandPools(root: *Root) error{Vulkan}!void {
    const command_pool_create_info: c.VkCommandPoolCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .pNext = null,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = root.physical_device.queues.graphics.family,
    };

    try errify(prototypes.vkCreateCommandPool(root.device, &command_pool_create_info, null, &root.command_pool));
    errdefer prototypes.vkDestroyCommandPool(root.device, root.command_pool, null);

    const buffers_command_pool_create_info: c.VkCommandPoolCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .pNext = null,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT | c.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT,
        .queueFamilyIndex = root.physical_device.queues.graphics.family,
    };

    try errify(prototypes.vkCreateCommandPool(root.device, &buffers_command_pool_create_info, null, &root.buffers_command_pool));
    errdefer prototypes.vkDestroyCommandPool(root.device, root.buffers_command_pool, null);
}

fn deinitCommandPools(root: *Root) void {
    prototypes.vkDestroyCommandPool(root.device, root.command_pool, null);
    prototypes.vkDestroyCommandPool(root.device, root.buffers_command_pool, null);
}

fn copyBuffer(root: *Root, src_buffer: c.VkBuffer, dst_buffer: c.VkBuffer, size: c.VkDeviceSize) !void {
    var command_buffers = [_]c.VkCommandBuffer{undefined};

    const command_buffer_alloc_info: c.VkCommandBufferAllocateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .pNext = null,
        .commandPool = root.buffers_command_pool,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = command_buffers.len,
    };

    try errify(prototypes.vkAllocateCommandBuffers(root.device, &command_buffer_alloc_info, &command_buffers));
    defer prototypes.vkFreeCommandBuffers(root.device, root.buffers_command_pool, command_buffers.len, &command_buffers);

    const command_buffer_begin_info: c.VkCommandBufferBeginInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .pNext = null,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
        .pInheritanceInfo = null,
    };

    try errify(prototypes.vkBeginCommandBuffer(command_buffers[0], &command_buffer_begin_info));

    const buffer_copy_regions = [_]c.VkBufferCopy{
        .{
            .srcOffset = 0,
            .dstOffset = 0,
            .size = size,
        },
    };

    prototypes.vkCmdCopyBuffer(command_buffers[0], src_buffer, dst_buffer, buffer_copy_regions.len, &buffer_copy_regions);
    try errify(prototypes.vkEndCommandBuffer(command_buffers[0]));

    const submit_infos = [_]c.VkSubmitInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .pNext = null,
            .commandBufferCount = command_buffers.len,
            .pCommandBuffers = &command_buffers,
            .waitSemaphoreCount = 0,
            .pWaitSemaphores = null,
            .signalSemaphoreCount = 0,
            .pSignalSemaphores = null,
            .pWaitDstStageMask = null,
        },
    };

    try errify(prototypes.vkQueueSubmit(root.physical_device.queues.graphics.handle, submit_infos.len, &submit_infos, @ptrCast(c.VK_NULL_HANDLE)));
    try errify(prototypes.vkQueueWaitIdle(root.physical_device.queues.graphics.handle));
}

fn updateGeometryBuffer(root: *Root) error{Vulkan}!void {
    var staging_memory_mapped: ?*anyopaque = undefined;

    const alignment = @max(root.physical_device.min_uniform_buffer_offset_alignment, root.physical_device.non_coherent_atom_size);
    const mapped_memory_ranges = [_]c.VkMappedMemoryRange{
        .{
            .sType = c.VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE,
            .pNext = null,
            .memory = root.memory.host_visible.handle,
            .offset = root.memory.host_visible.offset.staging_buffer,
            .size = alignUp(@sizeOf(@TypeOf(vertices)) + @sizeOf(@TypeOf(indices)), alignment),
        },
    };

    try errify(prototypes.vkMapMemory(root.device, root.memory.host_visible.handle, root.memory.host_visible.offset.staging_buffer, alignUp(@sizeOf(@TypeOf(vertices)) + @sizeOf(@TypeOf(indices)), alignment), 0, &staging_memory_mapped));
    defer prototypes.vkUnmapMemory(root.device, root.memory.host_visible.handle);

    try errify(prototypes.vkInvalidateMappedMemoryRanges(root.device, mapped_memory_ranges.len, &mapped_memory_ranges));

    @memcpy(@as([*]u8, @ptrCast(staging_memory_mapped.?))[0..@sizeOf(@TypeOf(vertices))], std.mem.sliceAsBytes(&vertices));
    @memcpy(@as([*]u8, @ptrCast(staging_memory_mapped.?))[@sizeOf(@TypeOf(vertices)) .. @sizeOf(@TypeOf(vertices)) + @sizeOf(@TypeOf(indices))], std.mem.sliceAsBytes(&indices));

    try errify(prototypes.vkFlushMappedMemoryRanges(root.device, mapped_memory_ranges.len, &mapped_memory_ranges));

    try copyBuffer(root, root.staging_buffer, root.geometry_buffer, @sizeOf(@TypeOf(vertices)) + @sizeOf(@TypeOf(indices)));
}

fn initDescriptorPool(root: *Root) error{Vulkan}!void {
    const descriptor_pool_sizes = [_]c.VkDescriptorPoolSize{
        .{
            .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
            .descriptorCount = MAX_FRAMES_IN_FLIGHT * 2,
        },
        .{
            .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = MAX_FRAMES_IN_FLIGHT + 1,
        },
    };

    const descriptor_pool_create_info: c.VkDescriptorPoolCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .pNext = null,
        .flags = c.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
        .poolSizeCount = descriptor_pool_sizes.len,
        .pPoolSizes = &descriptor_pool_sizes,
        .maxSets = @min(descriptor_pool_sizes[0].descriptorCount, descriptor_pool_sizes[1].descriptorCount),
    };

    try errify(prototypes.vkCreateDescriptorPool(root.device, &descriptor_pool_create_info, null, &root.descriptor_pool));
    errdefer prototypes.vkDestroyDescriptorPool(root.device, root.descriptor_pool, null);
}

fn deinitDescriptorPool(root: *Root) void {
    prototypes.vkDestroyDescriptorPool(root.device, root.descriptor_pool, null);
}

fn initDescriptorSets(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    const offscreen_descriptor_set_alloc_info: c.VkDescriptorSetAllocateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .pNext = null,
        .descriptorPool = root.descriptor_pool,
        .descriptorSetCount = @intCast(root.offscreen.descriptor_set_layouts.len),
        .pSetLayouts = root.offscreen.descriptor_set_layouts.ptr,
    };

    root.offscreen.descriptor_sets = try root.init.gpa.alloc(c.VkDescriptorSet, 1);
    errdefer root.init.gpa.free(root.offscreen.descriptor_sets);

    // We don't need to explicitly clean up descriptor sets, because they will be automatically freed when the descriptor pool is destroyed
    try errify(prototypes.vkAllocateDescriptorSets(root.device, &offscreen_descriptor_set_alloc_info, root.offscreen.descriptor_sets.ptr));

    const offscreen_descriptor_buffer_infos = [_]c.VkDescriptorBufferInfo{
        .{
            .buffer = root.uniform_buffer,
            .offset = 0,
            .range = @sizeOf(shader.OffscreenUBO),
        },
    };

    const offscreen_write_descriptor_sets = [_]c.VkWriteDescriptorSet{
        .{
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .pNext = null,
            .dstSet = root.offscreen.descriptor_sets[0],
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
            .descriptorCount = 1,
            .pBufferInfo = &offscreen_descriptor_buffer_infos,
            .pImageInfo = undefined,
            .pTexelBufferView = undefined,
        },
    };

    prototypes.vkUpdateDescriptorSets(root.device, offscreen_write_descriptor_sets.len, &offscreen_write_descriptor_sets, 0, undefined);

    const onscreen_descriptor_set_alloc_info: c.VkDescriptorSetAllocateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .pNext = null,
        .descriptorPool = root.descriptor_pool,
        .descriptorSetCount = MAX_FRAMES_IN_FLIGHT,
        .pSetLayouts = &[_]c.VkDescriptorSetLayout{
            root.descriptor_set_layouts[0], root.descriptor_set_layouts[0],
        },
    };

    root.descriptor_sets = try root.init.gpa.alloc(c.VkDescriptorSet, MAX_FRAMES_IN_FLIGHT);
    errdefer root.init.gpa.free(root.descriptor_sets);

    // We don't need to explicitly clean up descriptor sets, because they will be automatically freed when the descriptor pool is destroyed
    try errify(prototypes.vkAllocateDescriptorSets(root.device, &onscreen_descriptor_set_alloc_info, root.descriptor_sets.ptr));

    var onscreen_descriptor_buffer_infos: [1]c.VkDescriptorBufferInfo = undefined;
    var onscreen_descriptor_image_infos: [1]c.VkDescriptorImageInfo = undefined;
    var onscreen_write_descriptor_sets: [2]c.VkWriteDescriptorSet = undefined;

    for (0..MAX_FRAMES_IN_FLIGHT) |index| {
        onscreen_descriptor_buffer_infos = [_]c.VkDescriptorBufferInfo{
            .{
                .buffer = root.uniform_buffer,
                .offset = 0,
                .range = @sizeOf(shader.OnscreenUBO),
            },
        };

        onscreen_descriptor_image_infos = [_]c.VkDescriptorImageInfo{
            .{
                .sampler = root.offscreen.sampler,
                .imageView = root.offscreen.views.array,
                .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            },
        };

        onscreen_write_descriptor_sets = [_]c.VkWriteDescriptorSet{
            .{
                .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .pNext = null,
                .dstSet = root.descriptor_sets[index],
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
                .descriptorCount = 1,
                .pBufferInfo = &onscreen_descriptor_buffer_infos,
                .pImageInfo = undefined,
                .pTexelBufferView = undefined,
            },
            .{
                .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .pNext = null,
                .dstSet = root.descriptor_sets[index],
                .dstBinding = 1,
                .dstArrayElement = 0,
                .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = 1,
                .pBufferInfo = undefined,
                .pImageInfo = &onscreen_descriptor_image_infos,
                .pTexelBufferView = undefined,
            },
        };

        prototypes.vkUpdateDescriptorSets(root.device, onscreen_write_descriptor_sets.len, &onscreen_write_descriptor_sets, 0, undefined);
    }
}

fn deinitDescriptorSets(root: *Root) void {
    root.init.gpa.free(root.descriptor_sets);
    root.init.gpa.free(root.offscreen.descriptor_sets);
}

fn initCommandBuffers(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    root.command_buffers = try root.init.gpa.alloc(c.VkCommandBuffer, MAX_FRAMES_IN_FLIGHT);
    errdefer root.init.gpa.free(root.command_buffers);

    const command_buffer_alloc_info: c.VkCommandBufferAllocateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .pNext = null,
        .commandPool = root.command_pool,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = MAX_FRAMES_IN_FLIGHT,
    };

    try errify(prototypes.vkAllocateCommandBuffers(root.device, &command_buffer_alloc_info, root.command_buffers.ptr));
    errdefer prototypes.vkFreeCommandBuffers(root.device, root.command_pool, @intCast(root.command_buffers.len), root.command_buffers.ptr);
}

fn deinitCommandBuffers(root: *Root) void {
    prototypes.vkFreeCommandBuffers(root.device, root.command_pool, @intCast(root.command_buffers.len), root.command_buffers.ptr);
    root.init.gpa.free(root.command_buffers);
}

fn initSyncObjects(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    root.image_available_semaphores = try root.init.gpa.alloc(c.VkSemaphore, MAX_FRAMES_IN_FLIGHT);
    errdefer root.init.gpa.free(root.image_available_semaphores);
    root.render_finished_semaphores = try root.init.gpa.alloc(c.VkSemaphore, MAX_FRAMES_IN_FLIGHT);
    errdefer root.init.gpa.free(root.render_finished_semaphores);
    root.in_flight_fences = try root.init.gpa.alloc(c.VkFence, MAX_FRAMES_IN_FLIGHT);
    errdefer root.init.gpa.free(root.in_flight_fences);

    const semaphore_create_info: c.VkSemaphoreCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
    };

    const fence_create_info: c.VkFenceCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .pNext = null,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    for (0..MAX_FRAMES_IN_FLIGHT) |index| {
        try errify(prototypes.vkCreateSemaphore(root.device, &semaphore_create_info, null, &root.image_available_semaphores[index]));
        errdefer prototypes.vkDestroySemaphore(root.device, root.image_available_semaphores[index], null);
        try errify(prototypes.vkCreateSemaphore(root.device, &semaphore_create_info, null, &root.render_finished_semaphores[index]));
        errdefer prototypes.vkDestroySemaphore(root.device, root.render_finished_semaphores[index], null);
        try errify(prototypes.vkCreateFence(root.device, &fence_create_info, null, &root.in_flight_fences[index]));
        errdefer prototypes.vkDestroyFence(root.device, root.in_flight_fences[index], null);
    }
}

fn deinitSemaphores(root: *Root) void {
    for (0..MAX_FRAMES_IN_FLIGHT) |index| {
        prototypes.vkDestroySemaphore(root.device, root.image_available_semaphores[index], null);
        prototypes.vkDestroySemaphore(root.device, root.render_finished_semaphores[index], null);
    }
    root.init.gpa.free(root.image_available_semaphores);
    root.init.gpa.free(root.render_finished_semaphores);
}

fn deinitFences(root: *Root) void {
    for (0..MAX_FRAMES_IN_FLIGHT) |index| {
        prototypes.vkDestroyFence(root.device, root.in_flight_fences[index], null);
    }
    root.init.gpa.free(root.in_flight_fences);
}

fn isLooping(root: *Root) bool {
    return c.glfwWindowShouldClose(root.window) != c.GLFW_TRUE;
}

fn rebuildSwapchain(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    try errify(prototypes.vkDeviceWaitIdle(root.device));

    deinitOnscreenFramebuffers(root);
    deinitOnscreenImageViews(root);
    deinitSwapchain(root);
    deinitOnscreenImage(root);

    try root.physical_device.querySwapchainSupport(root);
    try initSwapchain(root);
    try initOnscreenImageViews(root);
    try initOnscreenFramebuffers(root);
}

fn updateUniformBuffers(root: *Root) (std.mem.Allocator.Error || error{Vulkan})!void {
    const onscreen_ubo: shader.OnscreenUBO = .{
        .time = std.math.lossyCast(f32, root.start_time.untilNow(root.init.io, .real).toNanoseconds()) / std.time.ns_per_s,
        .resolution_x = std.math.lossyCast(f32, root.extent.width),
        .resolution_y = std.math.lossyCast(f32, root.extent.height),
        .max_resolution_x = std.math.lossyCast(f32, root.max_extent.width),
        .max_resolution_y = std.math.lossyCast(f32, root.max_extent.height),
    };

    var ubo_memory_mapped: ?*anyopaque = undefined;

    var mapped_memory_ranges = try std.ArrayList(c.VkMappedMemoryRange).initCapacity(root.init.gpa, 2);
    defer mapped_memory_ranges.deinit(root.init.gpa);

    const alignment = @max(root.physical_device.non_coherent_atom_size, root.physical_device.min_uniform_buffer_offset_alignment);
    mapped_memory_ranges.appendAssumeCapacity(.{
        .sType = c.VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE,
        .pNext = null,
        .memory = root.memory.host_visible.handle,
        .offset = root.memory.host_visible.offset.onscreen_uniform_buffer[root.current_frame],
        .size = alignUp(@sizeOf(shader.OnscreenUBO), alignment),
    });

    if (root.offscreen.render) {
        mapped_memory_ranges.appendAssumeCapacity(.{
            .sType = c.VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE,
            .pNext = null,
            .memory = root.memory.host_visible.handle,
            .offset = root.memory.host_visible.offset.offscreen_uniform_buffer,
            .size = alignUp(@sizeOf(shader.OffscreenUBO), alignment) * root.offscreen.layers,
        });
    }

    try errify(prototypes.vkMapMemory(root.device, root.memory.host_visible.handle, root.memory.host_visible.offset.uniform_buffer, alignUp(@sizeOf(shader.OnscreenUBO), alignment) * MAX_FRAMES_IN_FLIGHT + alignUp(@sizeOf(shader.OffscreenUBO), alignment) * root.offscreen.layers, 0, &ubo_memory_mapped));
    defer prototypes.vkUnmapMemory(root.device, root.memory.host_visible.handle);

    try errify(prototypes.vkInvalidateMappedMemoryRanges(root.device, @intCast(mapped_memory_ranges.items.len), mapped_memory_ranges.items.ptr));

    const onscreen_start = root.memory.host_visible.offset.onscreen_uniform_buffer[root.current_frame] - root.memory.host_visible.offset.uniform_buffer;
    @memcpy(@as([*]u8, @ptrCast(ubo_memory_mapped.?))[onscreen_start .. onscreen_start + @sizeOf(shader.OnscreenUBO)], std.mem.asBytes(&onscreen_ubo));

    if (root.offscreen.render) {
        for (0..root.offscreen.layers) |index| {
            const offscreen_ubo: shader.OffscreenUBO = .{
                .seed = root.seed,
                .resolution_x = std.math.lossyCast(f32, root.offscreen.extent.width),
                .resolution_y = std.math.lossyCast(f32, root.offscreen.extent.height),
                .layer = @intCast(index),
            };
            const offscreen_start = root.memory.host_visible.offset.offscreen_uniform_buffer - root.memory.host_visible.offset.uniform_buffer + alignUp(@sizeOf(shader.OffscreenUBO), alignment) * index;
            @memcpy(@as([*]u8, @ptrCast(ubo_memory_mapped.?))[offscreen_start .. offscreen_start + @sizeOf(shader.OffscreenUBO)], std.mem.asBytes(&offscreen_ubo));
        }
    }

    try errify(prototypes.vkFlushMappedMemoryRanges(root.device, @intCast(mapped_memory_ranges.items.len), mapped_memory_ranges.items.ptr));
}

fn recordCommandBuffer(root: *Root, image_index: u32) !void {
    try errify(prototypes.vkResetCommandBuffer(root.command_buffers[root.current_frame], 0));

    const command_buffer_begin_info: c.VkCommandBufferBeginInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .pNext = null,
        .flags = 0,
        .pInheritanceInfo = null,
    };

    try errify(prototypes.vkBeginCommandBuffer(root.command_buffers[root.current_frame], &command_buffer_begin_info));

    const offscreen_clear_values = [_]c.VkClearValue{
        .{
            .color = .{
                .float32 = @splat(0.0),
            },
        },
    };

    const vertex_buffers_offsets = [_]c.VkDeviceSize{root.memory.device_local.offset.vertex_buffer};
    const vertex_buffers = [_]c.VkBuffer{root.geometry_buffer};
    prototypes.vkCmdBindVertexBuffers(root.command_buffers[root.current_frame], 0, vertex_buffers.len, &vertex_buffers, &vertex_buffers_offsets);
    prototypes.vkCmdBindIndexBuffer(root.command_buffers[root.current_frame], root.geometry_buffer, root.memory.device_local.offset.index_buffer, c.VK_INDEX_TYPE_UINT32);

    if (root.offscreen.render) {
        const alignment = @max(root.physical_device.min_uniform_buffer_offset_alignment, root.physical_device.non_coherent_atom_size);
        for (0..root.offscreen.layers) |index| {
            const offscreen_dynamic_offsets = [_]u32{std.math.lossyCast(u32, root.memory.host_visible.offset.offscreen_uniform_buffer - root.memory.host_visible.offset.uniform_buffer + alignUp(@sizeOf(shader.OffscreenUBO), alignment) * index)};

            const offscreen_render_pass_begin_info: c.VkRenderPassBeginInfo = .{
                .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
                .pNext = null,
                .renderPass = root.offscreen.render_pass,
                .framebuffer = root.offscreen.framebuffers[index],
                .renderArea = .{
                    .offset = .{
                        .x = 0,
                        .y = 0,
                    },
                    .extent = root.offscreen.extent,
                },
                .clearValueCount = offscreen_clear_values.len,
                .pClearValues = &offscreen_clear_values,
            };

            prototypes.vkCmdBeginRenderPass(root.command_buffers[root.current_frame], &offscreen_render_pass_begin_info, c.VK_SUBPASS_CONTENTS_INLINE);
            defer prototypes.vkCmdEndRenderPass(root.command_buffers[root.current_frame]);
            prototypes.vkCmdSetViewport(root.command_buffers[root.current_frame], 0, root.viewports.len, &root.viewports);
            prototypes.vkCmdSetScissor(root.command_buffers[root.current_frame], 0, root.scissors.len, &root.scissors);
            prototypes.vkCmdBindDescriptorSets(root.command_buffers[root.current_frame], c.VK_PIPELINE_BIND_POINT_GRAPHICS, root.offscreen.pipelines.layout, 0, @intCast(root.offscreen.descriptor_sets.len), root.offscreen.descriptor_sets.ptr, offscreen_dynamic_offsets.len, &offscreen_dynamic_offsets);
            prototypes.vkCmdBindPipeline(root.command_buffers[root.current_frame], c.VK_PIPELINE_BIND_POINT_GRAPHICS, root.offscreen.pipelines.handles[0]);
            prototypes.vkCmdDrawIndexed(root.command_buffers[root.current_frame], indices.len, 1, 0, 0, 0);
        }
    }

    const onscreen_clear_values = [_]c.VkClearValue{
        .{
            .color = .{
                .float32 = @as([3]f32, @splat(0.0)) ++ [_]f32{1.0},
            },
        },
    };

    const onscreen_render_pass_begin_info: c.VkRenderPassBeginInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .pNext = null,
        .renderPass = root.render_pass,
        .framebuffer = root.framebuffers[image_index],
        .renderArea = .{
            .offset = .{
                .x = 0,
                .y = 0,
            },
            .extent = root.extent,
        },
        .clearValueCount = onscreen_clear_values.len,
        .pClearValues = &onscreen_clear_values,
    };

    const onscreen_dynamic_offsets = [_]u32{std.math.lossyCast(u32, root.memory.host_visible.offset.onscreen_uniform_buffer[root.current_frame] - root.memory.host_visible.offset.uniform_buffer)};

    {
        prototypes.vkCmdBeginRenderPass(root.command_buffers[root.current_frame], &onscreen_render_pass_begin_info, c.VK_SUBPASS_CONTENTS_INLINE);
        defer prototypes.vkCmdEndRenderPass(root.command_buffers[root.current_frame]);
        prototypes.vkCmdBindPipeline(root.command_buffers[root.current_frame], c.VK_PIPELINE_BIND_POINT_GRAPHICS, root.pipelines.handles[0]);

        prototypes.vkCmdSetViewport(root.command_buffers[root.current_frame], 0, root.viewports.len, &root.viewports);
        prototypes.vkCmdSetScissor(root.command_buffers[root.current_frame], 0, root.scissors.len, &root.scissors);

        const onscreen_descriptor_sets = [_]c.VkDescriptorSet{root.descriptor_sets[root.current_frame]};
        prototypes.vkCmdBindDescriptorSets(root.command_buffers[root.current_frame], c.VK_PIPELINE_BIND_POINT_GRAPHICS, root.pipelines.layout, 0, onscreen_descriptor_sets.len, &onscreen_descriptor_sets, onscreen_dynamic_offsets.len, &onscreen_dynamic_offsets);
        prototypes.vkCmdDrawIndexed(root.command_buffers[root.current_frame], indices.len, 1, 0, 0, 0);
        renderImGui(root);
    }

    try errify(prototypes.vkEndCommandBuffer(root.command_buffers[root.current_frame]));

    root.offscreen.render = false;
}

fn draw(root: *Root) (std.mem.Allocator.Error || error{ Vulkan, ImGuiBegin })!void {
    c.glfwPollEvents();

    const fences = [_]c.VkFence{root.in_flight_fences[root.current_frame]};
    try errify(prototypes.vkWaitForFences(root.device, fences.len, &fences, c.VK_TRUE, TIMEOUT));

    try drawImgui(root);

    var image_index: u32 = undefined;
    switch (prototypes.vkAcquireNextImageKHR(root.device, root.swapchain, TIMEOUT, root.image_available_semaphores[root.current_frame], @ptrCast(c.VK_NULL_HANDLE), &image_index)) {
        c.VK_SUCCESS => {},
        c.VK_ERROR_OUT_OF_DATE_KHR => try rebuildSwapchain(root),
        else => |result| try errify(result),
    }

    try updateUniformBuffers(root);
    try errify(prototypes.vkResetFences(root.device, fences.len, &fences));
    try recordCommandBuffer(root, image_index);

    const pipeline_stages = [_]c.VkPipelineStageFlags{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
    const image_available_semaphores = [_]c.VkSemaphore{root.image_available_semaphores[root.current_frame]};
    const command_buffers = [_]c.VkCommandBuffer{root.command_buffers[root.current_frame]};
    const render_finished_semaphores = [_]c.VkSemaphore{root.render_finished_semaphores[root.current_frame]};

    const submit_infos = [_]c.VkSubmitInfo{
        .{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .pNext = null,
            .waitSemaphoreCount = image_available_semaphores.len,
            .pWaitSemaphores = &image_available_semaphores,
            .pWaitDstStageMask = &pipeline_stages,
            .commandBufferCount = command_buffers.len,
            .pCommandBuffers = &command_buffers,
            .signalSemaphoreCount = render_finished_semaphores.len,
            .pSignalSemaphores = &render_finished_semaphores,
        },
    };

    try errify(prototypes.vkQueueSubmit(root.physical_device.queues.graphics.handle, submit_infos.len, &submit_infos, root.in_flight_fences[root.current_frame]));

    const swapchains = [_]c.VkSwapchainKHR{root.swapchain};

    const present_info: c.VkPresentInfoKHR = .{
        .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .pNext = null,
        .waitSemaphoreCount = render_finished_semaphores.len,
        .pWaitSemaphores = &render_finished_semaphores,
        .swapchainCount = swapchains.len,
        .pSwapchains = &swapchains,
        .pImageIndices = &[_]u32{image_index},
        .pResults = null,
    };

    var present_result_suboptimal_khr = false;
    switch (prototypes.vkQueuePresentKHR(root.physical_device.queues.present.handle, &present_info)) {
        c.VK_SUCCESS => {},
        c.VK_ERROR_OUT_OF_DATE_KHR => present_result_suboptimal_khr = true,
        else => |result| try errify(result),
    }

    if (present_result_suboptimal_khr or root.framebuffer_resized) {
        root.framebuffer_resized = false;
        try rebuildSwapchain(root);
    }

    root.current_frame = @intFromBool(root.current_frame == 0);
}

fn loop(root: *Root) (std.mem.Allocator.Error || std.Io.Cancelable || error{ Vulkan, ImGuiBegin })!void {
    var frame: u32 = 0;
    const frames_per_s = 60;
    const ns_per_frame = std.time.ns_per_s / frames_per_s;
    root.start_time = std.Io.Timestamp.now(root.init.io, .real);
    var start_time = root.start_time;
    while (isLooping(root)) {
        try draw(root);
        frame += 1;
        const until_now = start_time.untilNow(root.init.io, .real).toNanoseconds();
        try root.init.io.sleep(.{ .nanoseconds = @max(0, ns_per_frame * frame - until_now) }, .real);
        if (until_now > std.time.ns_per_s) {
            frame = 0;
            start_time = std.Io.Timestamp.now(root.init.io, .real);
        }
    }

    try errify(prototypes.vkDeviceWaitIdle(root.device));
}

pub fn main(init: std.process.Init) (std.mem.Allocator.Error || std.Io.Cancelable || error{ Vulkan, GLFWCreateWindow, GLFWInit, VulkanNotSupported, QueueFamilies, UnknownFunction, NoSuitableMemoryType, NoAvailablePhysicalDevice, NoSuitablePhysicalDevice, ImGuiCreateContext, ImGuiGlfwInit, ImGuiVulkanInit, ImGuiVulkanLoad, ImGuiBegin })!void {
    var root: Root = .{
        .init = &init,
        .arena_allocator = init.arena.allocator(),
        .offscreen = .{
            .extent = .{
                .width = PIXELLIZATION_MAX,
                .height = PIXELLIZATION_MAX,
            },
            .layers = 2,
        },
        .prng = .init(blk: {
            var seed: u64 = undefined;
            init.io.random(std.mem.asBytes(&seed));
            break :blk seed;
        }),
        .random = undefined,
    };
    root.random = root.prng.random();
    root.seed = root.random.int(u32);

    try initGLFW(&root);
    defer deinitGLFW(&root);
    try initInstance(&root);
    defer deinitInstance(&root);
    try initSurface(&root);
    defer deinitSurface(&root);

    try pickPhysicalDevice(&root);
    try initLogicalDevice(&root);
    defer deinitLogicalDevice(&root);

    try initOffscreenImage(&root);
    defer deinitOffscreenImage(&root);

    try initSwapchain(&root);
    defer deinitOnscreenImage(&root);
    defer deinitSwapchain(&root);

    try initGeometryBuffer(&root);
    defer deinitGeometryBuffer(&root);
    try initUniformBuffers(&root);
    defer deinitUniformBuffers(&root);
    try allocMemory(&root);
    defer freeMemory(&root);

    try initOffscreenImageViews(&root);
    defer deinitOffscreenImageViews(&root);
    try initOnscreenImageViews(&root);
    defer deinitOnscreenImageViews(&root);
    try initOffscreenSampler(&root);
    defer deinitOffscreenSampler(&root);
    try initRenderPasses(&root);
    defer deinitRenderPasses(&root);
    try initDescriptorSetLayouts(&root);
    defer deinitDescriptorSetLayouts(&root);
    try initGraphicsPipelines(&root);
    defer deinitGraphicsPipelines(&root);
    defer deinitPipelineLayouts(&root);
    try initOffscreenFramebuffers(&root);
    defer deinitOffscreenFramebuffers(&root);
    try initOnscreenFramebuffers(&root);
    defer deinitOnscreenFramebuffers(&root);

    try initCommandPools(&root);
    defer deinitCommandPools(&root);
    try updateGeometryBuffer(&root);

    try initDescriptorPool(&root);
    defer deinitDescriptorPool(&root);
    try initDescriptorSets(&root);
    defer deinitDescriptorSets(&root);
    try initCommandBuffers(&root);
    defer deinitCommandBuffers(&root);
    try initSyncObjects(&root);
    defer deinitSemaphores(&root);
    defer deinitFences(&root);

    try initImgui(&root);
    defer deinitImgui();

    try loop(&root);
}
