const std = @import("std");
const c = @import("c");
const build = @import("build");

pub fn setStyle(comptime fix_gamma: bool) void {
    var style: *c.ImGuiStyle = c.ImGui_GetStyle();
    const gamma: f32 = if (fix_gamma) 2.2 else 1.0;

    // Sizing and Spacing
    style.WindowPadding = .{ .x = 10.0, .y = 10.0 };
    style.FramePadding = .{ .x = 6.0, .y = 4.0 };
    style.ItemSpacing = .{ .x = 8.0, .y = 4.0 };
    style.ScrollbarSize = 13.0;
    style.GrabMinSize = 10.0;

    // Borders & Rounding
    style.WindowRounding = 0.0;
    style.FrameRounding = 0.0;
    style.PopupRounding = 0.0;
    style.ScrollbarRounding = 0.0;
    style.GrabRounding = 0.0;
    style.TabRounding = 0.0;

    style.WindowBorderSize = 1.0;
    style.FrameBorderSize = 1.0;
    style.PopupBorderSize = 1.0;

    // Text
    style.Colors[c.ImGuiCol_Text] = .{ .x = 0.00, .y = 1.00, .z = std.math.pow(f32, 0.62, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_TextDisabled] = .{ .x = std.math.pow(f32, 0.20, gamma), .y = std.math.pow(f32, 0.40, gamma), .z = std.math.pow(f32, 0.35, gamma), .w = 1.00 };

    // Backgrounds
    style.Colors[c.ImGuiCol_WindowBg] = .{ .x = std.math.pow(f32, 0.02, gamma), .y = std.math.pow(f32, 0.02, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = std.math.pow(f32, 0.95, gamma) };
    style.Colors[c.ImGuiCol_ChildBg] = .{ .x = std.math.pow(f32, 0.02, gamma), .y = std.math.pow(f32, 0.02, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = 0.00 };
    style.Colors[c.ImGuiCol_PopupBg] = .{ .x = std.math.pow(f32, 0.02, gamma), .y = std.math.pow(f32, 0.02, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = std.math.pow(f32, 0.98, gamma) };

    // Borders
    style.Colors[c.ImGuiCol_Border] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.60, gamma) };
    style.Colors[c.ImGuiCol_BorderShadow] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.20, gamma) };

    // Frames
    style.Colors[c.ImGuiCol_FrameBg] = .{ .x = std.math.pow(f32, 0.05, gamma), .y = std.math.pow(f32, 0.05, gamma), .z = std.math.pow(f32, 0.10, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_FrameBgHovered] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.20, gamma) };
    style.Colors[c.ImGuiCol_FrameBgActive] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.40, gamma) };

    // Title Barsc.
    style.Colors[c.ImGuiCol_TitleBg] = .{ .x = std.math.pow(f32, 0.02, gamma), .y = std.math.pow(f32, 0.02, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_TitleBgActive] = .{ .x = std.math.pow(f32, 0.05, gamma), .y = std.math.pow(f32, 0.05, gamma), .z = std.math.pow(f32, 0.10, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_TitleBgCollapsed] = .{ .x = std.math.pow(f32, 0.02, gamma), .y = std.math.pow(f32, 0.02, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = 1.00 };

    // Menus
    style.Colors[c.ImGuiCol_MenuBarBg] = .{ .x = std.math.pow(f32, 0.05, gamma), .y = std.math.pow(f32, 0.05, gamma), .z = std.math.pow(f32, 0.10, gamma), .w = 1.00 };

    // Scrollbars
    style.Colors[c.ImGuiCol_ScrollbarBg] = .{ .x = std.math.pow(f32, 0.02, gamma), .y = std.math.pow(f32, 0.02, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_ScrollbarGrab] = .{ .x = 1.00, .y = std.math.pow(f32, 0.93, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = std.math.pow(f32, 0.60, gamma) };
    style.Colors[c.ImGuiCol_ScrollbarGrabHovered] = .{ .x = 1.00, .y = std.math.pow(f32, 0.93, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = std.math.pow(f32, 0.80, gamma) };
    style.Colors[c.ImGuiCol_ScrollbarGrabActive] = .{ .x = 1.00, .y = std.math.pow(f32, 0.93, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = 1.00 };

    // Interactables
    style.Colors[c.ImGuiCol_CheckMark] = .{ .x = 1.00, .y = std.math.pow(f32, 0.93, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_SliderGrab] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.80, gamma) };
    style.Colors[c.ImGuiCol_SliderGrabActive] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_Button] = .{ .x = 0.00, .y = 1.00, .z = std.math.pow(f32, 0.62, gamma), .w = std.math.pow(f32, 0.20, gamma) };
    style.Colors[c.ImGuiCol_ButtonHovered] = .{ .x = 0.00, .y = 1.00, .z = std.math.pow(f32, 0.62, gamma), .w = std.math.pow(f32, 0.50, gamma) };
    style.Colors[c.ImGuiCol_ButtonActive] = .{ .x = 0.00, .y = 1.00, .z = std.math.pow(f32, 0.62, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_Header] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.30, gamma) };
    style.Colors[c.ImGuiCol_HeaderHovered] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.50, gamma) };
    style.Colors[c.ImGuiCol_HeaderActive] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = 1.00 };

    // Tabs
    style.Colors[c.ImGuiCol_Tab] = .{ .x = std.math.pow(f32, 0.05, gamma), .y = std.math.pow(f32, 0.05, gamma), .z = std.math.pow(f32, 0.10, gamma), .w = 1.00 };
    style.Colors[c.ImGuiCol_TabHovered] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = std.math.pow(f32, 0.80, gamma) };
    style.Colors[c.ImGuiCol_TabActive] = .{ .x = std.math.pow(f32, 0.80, gamma), .y = 0.00, .z = std.math.pow(f32, 0.20, gamma), .w = 1.00 };

    // Misc
    style.Colors[c.ImGuiCol_TextSelectedBg] = .{ .x = 1.00, .y = std.math.pow(f32, 0.93, gamma), .z = std.math.pow(f32, 0.04, gamma), .w = std.math.pow(f32, 0.30, gamma) };
    style.Colors[c.ImGuiCol_NavHighlight] = .{ .x = 1.00, .y = 0.00, .z = std.math.pow(f32, 0.25, gamma), .w = 1.00 };
}

pub fn draw(ui_is_hidden: bool, gpa: std.mem.Allocator, window_width: u32, window_height: u32, new_seed_button_pressed: *bool, seed: *u32, random: std.Random) (std.mem.Allocator.Error || error{ImGuiBegin})!void {
    _ = window_width;
    c.ImGui_NewFrame();

    const ui_pos: c.ImVec2 = .{ .x = 0.0, .y = 0.0 };
    const ui_pivot: c.ImVec2 = .{ .x = 0.0, .y = 0.0 };

    c.ImGui_SetNextWindowPosEx(ui_pos, c.ImGuiCond_FirstUseEver, ui_pivot);

    const ui_size: c.ImVec2 = .{ .x = 300.0, .y = @floatFromInt(window_height) };
    c.ImGui_SetNextWindowSize(ui_size, 0);

    const flags = c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoMove | c.ImGuiWindowFlags_NoResize | c.ImGuiWindowFlags_NoTitleBar;

    if (!ui_is_hidden) {
        if (!c.ImGui_Begin("ui", null, flags)) return error.ImGuiBegin;
        defer c.ImGui_End();
        const io: *c.ImGuiIO = c.ImGui_GetIO();

        if (c.ImGui_CollapsingHeader("Help", 0)) {
            c.ImGui_BulletText("Press SPACE to hide/show this panel");
            c.ImGui_BulletText("Press ESPACE to close " ++ build.name);
        }

        if (c.ImGui_CollapsingHeader("Stats", 0)) {
            const fps_text = try std.fmt.allocPrintSentinel(gpa, "Average {d:.1} ms/frame ({d:.0} FPS)", .{ std.time.ms_per_s / io.Framerate, io.Framerate }, 0);
            defer gpa.free(fps_text);
            c.ImGui_Text(fps_text.ptr);
        }

        if (c.ImGui_CollapsingHeader("Settings", 0)) {
            const seed_text = try std.fmt.allocPrintSentinel(gpa, "Seed: {d}", .{seed.*}, 0);
            defer gpa.free(seed_text);
            if (c.ImGui_Button("New Seed")) {
                seed.* = random.int(u32);
                new_seed_button_pressed.* = true;
            }
            c.ImGui_SameLine();
            c.ImGui_Text(seed_text.ptr);
        }

        //if (c.ImGui_CollapsingHeader("Stars", 0)) {
    }

    c.ImGui_Render();
}
