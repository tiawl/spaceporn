const std = @import("std");
const c = @import("c");
const build = @import("build");

const Button = enum(u32) {
    pressed,
    released,

    pub fn isPressed(self: @This()) bool {
        return self == .pressed;
    }

    pub fn press(self: *@This()) void {
        self.* = .pressed;
    }

    pub fn release(self: *@This()) void {
        self.* = .released;
    }
};

const Buttons = struct {
    new_seed: Button,
};

fn pow2_2(comptime erase_gamma: bool, comptime n: f32) f32 {
    return comptime if (erase_gamma) std.math.pow(f32, n, 2.2) else n;
}

pub const UI = struct {
    pub const VTable = struct {
        init_fn: *const fn(*anyopaque) anyerror!void,
        deinit_fn: *const fn(*anyopaque) void,
        new_frame_fn: *const fn(*anyopaque) void,
        render_fn: *const fn(*anyopaque) void,
        get_scale_fn: *const fn(*anyopaque) f32,
    };

    ptr: *anyopaque,
    vtable: *const VTable,
    gpa: std.mem.Allocator,
    is_hidden: bool,
    buttons: Buttons,
    style: *c.ImGuiStyle,

    pub fn implement(ptr: *anyopaque, vtable: *const VTable, gpa: std.mem.Allocator, comptime erase_gamma: bool) !@This() {
        _ = c.CIMGUI_CHECKVERSION();
        if (c.ImGui_CreateContext(null) == null) return error.ImGuiCreateContext;
        errdefer c.ImGui_DestroyContext(null);

        var io: *c.ImGuiIO = c.ImGui_GetIO();
        io.IniFilename = null;
        io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard | c.ImGuiConfigFlags_NavEnableGamepad;

        const self: @This() = .{
            .ptr = ptr,
            .vtable = vtable,
            .gpa = gpa,
            .is_hidden = false,
            .buttons = .{
                .new_seed = .pressed,
            },
            .style = c.ImGui_GetStyle(),
        };
        self.initStyle(erase_gamma);
        return self;
    }

    pub fn init(self: *@This()) !void {
        try self.vtable.init_fn(self.ptr);
    }

    pub fn deinit(self: *@This()) void {
        self.vtable.deinit_fn(self.ptr);
        c.ImGui_DestroyContext(null);
    }

    fn initPaddingStyle(self: @This()) void {
        self.style.WindowPadding = .{ .x = 10.0, .y = 10.0 };
        self.style.FramePadding = .{ .x = 6.0, .y = 4.0 };
        self.style.ItemSpacing = .{ .x = 8.0, .y = 4.0 };
    }

    fn initSizingStyle(self: @This()) void {
        self.style.ScrollbarSize = 13.0;
        self.style.GrabMinSize = 10.0;
    }

    fn initRoundingStyle(self: @This()) void {
        self.style.WindowRounding = 0.0;
        self.style.FrameRounding = 0.0;
        self.style.PopupRounding = 0.0;
        self.style.ScrollbarRounding = 0.0;
        self.style.GrabRounding = 0.0;
        self.style.TabRounding = 0.0;
    }

    fn initBorderSizingStyle(self: @This()) void {
        self.style.WindowBorderSize = 1.0;
        self.style.FrameBorderSize = 1.0;
        self.style.PopupBorderSize = 1.0;
    }

    fn initTextStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_Text] = .{ .x = 0.00, .y = 1.00, .z = pow2_2(erase_gamma, 0.62), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_TextDisabled] = .{ .x = pow2_2(erase_gamma, 0.20), .y = pow2_2(erase_gamma, 0.40), .z = pow2_2(erase_gamma, 0.35), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_TextSelectedBg] = .{ .x = 1.00, .y = pow2_2(erase_gamma, 0.93), .z = pow2_2(erase_gamma, 0.04), .w = pow2_2(erase_gamma, 0.30) };
    }

    fn initBackgroundStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_WindowBg] = .{ .x = pow2_2(erase_gamma, 0.02), .y = pow2_2(erase_gamma, 0.02), .z = pow2_2(erase_gamma, 0.04), .w = pow2_2(erase_gamma, 0.95) };
        self.style.Colors[c.ImGuiCol_ChildBg] = .{ .x = pow2_2(erase_gamma, 0.02), .y = pow2_2(erase_gamma, 0.02), .z = pow2_2(erase_gamma, 0.04), .w = 0.00 };
        self.style.Colors[c.ImGuiCol_PopupBg] = .{ .x = pow2_2(erase_gamma, 0.02), .y = pow2_2(erase_gamma, 0.02), .z = pow2_2(erase_gamma, 0.04), .w = pow2_2(erase_gamma, 0.98) };
    }

    fn initBorderStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_Border] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.60) };
        self.style.Colors[c.ImGuiCol_BorderShadow] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.20) };
    }

    fn initFrameStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_FrameBg] = .{ .x = pow2_2(erase_gamma, 0.05), .y = pow2_2(erase_gamma, 0.05), .z = pow2_2(erase_gamma, 0.10), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_FrameBgHovered] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.20) };
        self.style.Colors[c.ImGuiCol_FrameBgActive] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.40) };
    }

    fn initTitleStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_TitleBg] = .{ .x = pow2_2(erase_gamma, 0.02), .y = pow2_2(erase_gamma, 0.02), .z = pow2_2(erase_gamma, 0.04), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_TitleBgActive] = .{ .x = pow2_2(erase_gamma, 0.05), .y = pow2_2(erase_gamma, 0.05), .z = pow2_2(erase_gamma, 0.10), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_TitleBgCollapsed] = .{ .x = pow2_2(erase_gamma, 0.02), .y = pow2_2(erase_gamma, 0.02), .z = pow2_2(erase_gamma, 0.04), .w = 1.00 };
    }

    fn initMenuStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_MenuBarBg] = .{ .x = pow2_2(erase_gamma, 0.05), .y = pow2_2(erase_gamma, 0.05), .z = pow2_2(erase_gamma, 0.10), .w = 1.00 };
    }

    fn initScrollbarStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_ScrollbarBg] = .{ .x = pow2_2(erase_gamma, 0.02), .y = pow2_2(erase_gamma, 0.02), .z = pow2_2(erase_gamma, 0.04), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_ScrollbarGrab] = .{ .x = 1.00, .y = pow2_2(erase_gamma, 0.93), .z = pow2_2(erase_gamma, 0.04), .w = pow2_2(erase_gamma, 0.60) };
        self.style.Colors[c.ImGuiCol_ScrollbarGrabHovered] = .{ .x = 1.00, .y = pow2_2(erase_gamma, 0.93), .z = pow2_2(erase_gamma, 0.04), .w = pow2_2(erase_gamma, 0.80) };
        self.style.Colors[c.ImGuiCol_ScrollbarGrabActive] = .{ .x = 1.00, .y = pow2_2(erase_gamma, 0.93), .z = pow2_2(erase_gamma, 0.04), .w = 1.00 };
    }

    fn initCheckMarkStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_CheckMark] = .{ .x = 1.00, .y = pow2_2(erase_gamma, 0.93), .z = pow2_2(erase_gamma, 0.04), .w = 1.00 };
    }

    fn initSliderStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_SliderGrab] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.80) };
        self.style.Colors[c.ImGuiCol_SliderGrabActive] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = 1.00 };
    }

    fn initButtonStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_Button] = .{ .x = 0.00, .y = 1.00, .z = pow2_2(erase_gamma, 0.62), .w = pow2_2(erase_gamma, 0.20) };
        self.style.Colors[c.ImGuiCol_ButtonHovered] = .{ .x = 0.00, .y = 1.00, .z = pow2_2(erase_gamma, 0.62), .w = pow2_2(erase_gamma, 0.50) };
        self.style.Colors[c.ImGuiCol_ButtonActive] = .{ .x = 0.00, .y = 1.00, .z = pow2_2(erase_gamma, 0.62), .w = 1.00 };
    }

    fn initHeaderStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_Header] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.30) };
        self.style.Colors[c.ImGuiCol_HeaderHovered] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.50) };
        self.style.Colors[c.ImGuiCol_HeaderActive] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = 1.00 };
    }

    fn initTabStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_Tab] = .{ .x = pow2_2(erase_gamma, 0.05), .y = pow2_2(erase_gamma, 0.05), .z = pow2_2(erase_gamma, 0.10), .w = 1.00 };
        self.style.Colors[c.ImGuiCol_TabHovered] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = pow2_2(erase_gamma, 0.80) };
        self.style.Colors[c.ImGuiCol_TabActive] = .{ .x = pow2_2(erase_gamma, 0.80), .y = 0.00, .z = pow2_2(erase_gamma, 0.20), .w = 1.00 };
    }

    fn initNavStyle(self: @This(), comptime erase_gamma: bool) void {
        self.style.Colors[c.ImGuiCol_NavHighlight] = .{ .x = 1.00, .y = 0.00, .z = pow2_2(erase_gamma, 0.25), .w = 1.00 };
    }

    fn initStyle(self: @This(), comptime erase_gamma: bool) void {
        self.initPaddingStyle();
        self.initSizingStyle();
        self.initRoundingStyle();
        self.initBorderSizingStyle();
        self.initTextStyle(erase_gamma);
        self.initBackgroundStyle(erase_gamma);
        self.initBorderStyle(erase_gamma);
        self.initFrameStyle(erase_gamma);
        self.initTitleStyle(erase_gamma);
        self.initMenuStyle(erase_gamma);
        self.initScrollbarStyle(erase_gamma);
        self.initCheckMarkStyle(erase_gamma);
        self.initSliderStyle(erase_gamma);
        self.initButtonStyle(erase_gamma);
        self.initHeaderStyle(erase_gamma);
        self.initTabStyle(erase_gamma);
        self.initNavStyle(erase_gamma);
    }

    fn newFrame(self: @This()) void {
        self.vtable.new_frame_fn(self.ptr);
        c.ImGui_NewFrame();
    }

    pub fn draw(self: *@This(), window_width: u32, window_height: u32, seed: u32) (std.mem.Allocator.Error || error{ImGuiBegin})!void {
        _ = window_width;
        self.newFrame();

        const ui_pos: c.ImVec2 = .{ .x = 0.0, .y = 0.0 };
        const ui_pivot: c.ImVec2 = .{ .x = 0.0, .y = 0.0 };

        c.ImGui_SetNextWindowPosEx(ui_pos, c.ImGuiCond_FirstUseEver, ui_pivot);

        const ui_size: c.ImVec2 = .{ .x = 300.0, .y = @floatFromInt(window_height) };
        c.ImGui_SetNextWindowSize(ui_size, 0);

        const flags = c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoMove | c.ImGuiWindowFlags_NoResize | c.ImGuiWindowFlags_NoTitleBar;

        if (!self.is_hidden) {
            if (!c.ImGui_Begin("ui", null, flags)) return error.ImGuiBegin;
            defer c.ImGui_End();
            const io: *c.ImGuiIO = c.ImGui_GetIO();

            if (c.ImGui_CollapsingHeader("Help", 0)) {
                c.ImGui_BulletText("Press SPACE to hide/show this panel");
                c.ImGui_BulletText("Press ESPACE to close " ++ build.name);
            }

            if (c.ImGui_CollapsingHeader("Stats", 0)) {
                const fps_text = try std.fmt.allocPrintSentinel(self.gpa, "Average {d:.1} ms/frame ({d:.0} FPS)", .{ std.time.ms_per_s / io.Framerate, io.Framerate }, 0);
                defer self.gpa.free(fps_text);
                c.ImGui_Text(fps_text.ptr);
            }

            if (c.ImGui_CollapsingHeader("Settings", 0)) {
                const seed_text = try std.fmt.allocPrintSentinel(self.gpa, "Seed: {d}", .{seed}, 0);
                defer self.gpa.free(seed_text);
                if (c.ImGui_Button("New Seed")) {
                    self.buttons.new_seed.press();
                }
                c.ImGui_SameLine();
                c.ImGui_Text(seed_text.ptr);
            }

            //if (c.ImGui_CollapsingHeader("Stars", 0)) {
        }

        c.ImGui_Render();
    }

    pub fn render(self: @This()) void {
        self.vtable.render_fn(self.ptr);
    }

    pub fn getScale(self: @This()) f32 {
        return self.vtable.get_scale_fn(self.ptr);
    }
};
