const std = @import("std");
const c = @import("c");
const js = @import("js");

var allocator = std.heap.wasm_allocator;

// This GLFW implementation is minimal. It aims to allow imgui compilation with GLFW backend on a wasm-freestanding target.
// It is not aimed to be fully implemented.

var c_windowfocus_callback_opt: c.GLFWwindowfocusfun = null;
var c_cursorpos_callback_opt: c.GLFWcursorposfun = null;
var c_cursorenter_callback_opt: c.GLFWcursorenterfun = null;
var c_mousebutton_callback_opt: c.GLFWmousebuttonfun = null;
var c_scroll_callback_opt: c.GLFWscrollfun = null;
var c_key_callback_opt: c.GLFWkeyfun = null;
var c_char_callback_opt: c.GLFWcharfun = null;
var c_monitor_callback_opt: c.GLFWmonitorfun = null;
var c_error_callback_opt: c.GLFWerrorfun = null;

fn windowFocusCallbackWrapper(window: *js.platform.Window, focused: bool) void {
    if (c_windowfocus_callback_opt) |c_windowfocusCallback| c_windowfocusCallback(@ptrCast(@alignCast(window)), if (focused) c.GLFW_TRUE else c.GLFW_FALSE);
}

fn cursorPosCallbackWrapper(window: *js.platform.Window, xpos: f64, ypos: f64) void {
    if (c_cursorpos_callback_opt) |c_cursorposCallback| c_cursorposCallback(@ptrCast(@alignCast(window)), xpos, ypos);
}

fn cursorEnterCallbackWrapper(window: *js.platform.Window, entered: bool) void {
    if (c_cursorenter_callback_opt) |c_cursorenterCallback| c_cursorenterCallback(@ptrCast(@alignCast(window)), if (entered) c.GLFW_TRUE else c.GLFW_FALSE);
}

fn mouseButtonCallbackWrapper(window: *js.platform.Window, button: js.platform.MouseButton, action: js.platform.Action, mods: js.platform.Mods) void {
    if (c_mousebutton_callback_opt) |c_mousebuttonCallback| c_mousebuttonCallback(@ptrCast(@alignCast(window)), @backingInt(button), @backingInt(action), @backingInt(mods));
}

fn scrollCallbackWrapper(window: *js.platform.Window, xoffset: f64, yoffset: f64) void {
    if (c_scroll_callback_opt) |c_scrollCallback| c_scrollCallback(@ptrCast(@alignCast(window)), xoffset, yoffset);
}

fn keyCallbackWrapper(window: *js.platform.Window, key: js.platform.Key, scancode: i32, action: js.platform.Action, mods: js.platform.Mods) void {
    if (c_key_callback_opt) |c_keyCallback| c_keyCallback(@ptrCast(@alignCast(window)), @backingInt(key), scancode, @backingInt(action), @backingInt(mods));
}

fn charCallbackWrapper(window: *js.platform.Window, codepoint: u32) void {
    if (c_char_callback_opt) |c_charCallback| c_charCallback(@ptrCast(@alignCast(window)), codepoint);
}

fn monitorCallbackWrapper(monitor: *js.platform.Monitor, event: c_int) void {
    if (c_monitor_callback_opt) |c_monitorCallback| c_monitorCallback(@ptrCast(@alignCast(monitor)), event);
}

fn errorCallbackWrapper(error_code: c_int, description: ?[:0]const u8) void {
    if (c_error_callback_opt) |c_errorCallback| c_errorCallback(error_code, description orelse "");
}

pub fn setWindowFocusCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWwindowfocusfun) callconv(.c) c.GLFWwindowfocusfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.focusCallback = windowFocusCallbackWrapper;
        defer c_windowfocus_callback_opt = c_callback;
        return c_windowfocus_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setCursorPosCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWcursorposfun) callconv(.c) c.GLFWcursorposfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.cursorposCallback = cursorPosCallbackWrapper;
        defer c_cursorpos_callback_opt = c_callback;
        return c_cursorpos_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setCursorEnterCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWcursorenterfun) callconv(.c) c.GLFWcursorenterfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.cursorenterCallback = cursorEnterCallbackWrapper;
        defer c_cursorenter_callback_opt = c_callback;
        return c_cursorenter_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setMouseButtonCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWmousebuttonfun) callconv(.c) c.GLFWmousebuttonfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.mousebuttonCallback = mouseButtonCallbackWrapper;
        defer c_mousebutton_callback_opt = c_callback;
        return c_mousebutton_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setScrollCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWscrollfun) callconv(.c) c.GLFWscrollfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.scrollCallback = scrollCallbackWrapper;
        defer c_scroll_callback_opt = c_callback;
        return c_scroll_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setKeyCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWkeyfun) callconv(.c) c.GLFWkeyfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.keyCallback = keyCallbackWrapper;
        defer c_key_callback_opt = c_callback;
        return c_key_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setCharCallback(c_window_opt: ?*c.GLFWwindow, c_callback: c.GLFWcharfun) callconv(.c) c.GLFWcharfun {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        window.charCallback = charCallbackWrapper;
        defer c_char_callback_opt = c_callback;
        return c_char_callback_opt;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setMonitorCallback(c_callback: c.GLFWmonitorfun) callconv(.c) c.GLFWmonitorfun {
    js.platform.monitorCallback = monitorCallbackWrapper;
    defer c_monitor_callback_opt = c_callback;
    return c_monitor_callback_opt;
}

pub fn setErrorCallback(c_callback: c.GLFWerrorfun) callconv(.c) c.GLFWerrorfun {
    js.platform.ErrorHandler.setErrorCallback(errorCallbackWrapper);
    defer c_error_callback_opt = c_callback;
    return c_error_callback_opt;
}

pub fn getClipboardString(window: ?*c.GLFWwindow) callconv(.c) [*:0]const u8 {
    _ = window;
    return js.platform.Clipboard.getText();
}

pub fn setClipboardString(window: ?*c.GLFWwindow, c_str: ?[*:0]const u8) callconv(.c) void {
    _ = window;
    js.platform.Clipboard.setText(std.mem.span(c_str orelse ""));
}

pub fn setCursor(c_window_opt: ?*c.GLFWwindow, c_cursor_opt: ?*c.GLFWcursor) callconv(.c) void {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        if (c_cursor_opt) |c_cursor| {
            window.setCursor(@ptrCast(@alignCast(c_cursor)));
        } else js.console.err("{s}: cursor parameter is null", .{@src().fn_name});
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getCursorPos(c_window_opt: ?*c.GLFWwindow, xpos: ?*f64, ypos: ?*f64) callconv(.c) void {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        if (xpos) |x| x.* = window.mouse.cursor_pos_x;
        if (ypos) |y| y.* = window.mouse.cursor_pos_y;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setCursorPos(window: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
    _ = .{ window, xpos, ypos };
    std.debug.panic("{s} is not possible to implement: JavaScript can't move the mouse pointer", .{@src().fn_name});
}

pub fn getKey(c_window_opt: ?*c.GLFWwindow, key: c_int) callconv(.c) c_int {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        return @backingInt(window.getKeyState(@fromBackingInt(key)));
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getKeyName(key: c_int, scancode: c_int) callconv(.c) [*:0]const u8 {
    return js.platform.Keyboard.getKeyName(@fromBackingInt(key), @fromBackingInt(scancode));
}

pub fn getError(c_description_opt: ?*?[*:0]const u8) callconv(.c) c_int {
    var description: [:0]const u8 = undefined;

    const maybe_code = js.platform.ErrorHandler.popError(if (c_description_opt == null) null else &description);

    if (c_description_opt) |c_description| {
        c_description.* = if (maybe_code != null) description.ptr else null;
    }

    return maybe_code orelse c.GLFW_NO_ERROR;
}

pub fn createStandardCursor(c_shape: c_int) callconv(.c) ?*c.GLFWcursor {
    const cursor = allocator.create(js.platform.Cursor) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    cursor.* = .{
        .shape = @fromBackingInt(c_shape),
    };
    return @ptrCast(@alignCast(cursor));
}

pub fn destroyCursor(c_cursor_opt: ?*c.GLFWcursor) callconv(.c) void {
    if (c_cursor_opt) |c_cursor| {
        const cursor: *js.platform.Cursor = @ptrCast(@alignCast(c_cursor));
        allocator.destroy(cursor);
    } else js.console.err("{s}: cursor parameter is null", .{@src().fn_name});
}

pub fn getWindowAttrib(c_window_opt: ?*c.GLFWwindow, c_attrib: c_int) callconv(.c) c_int {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        return switch (c_attrib) {
            c.GLFW_FOCUSED => if (window.focused) c.GLFW_TRUE else c.GLFW_FALSE,
            else => std.debug.panic("{s}: window attrib ({d}) not supported", .{ @src().fn_name, c_attrib }),
        };
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getInputMode(c_window_opt: ?*c.GLFWwindow, c_mode: c_int) callconv(.c) c_int {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        return switch (c_mode) {
            c.GLFW_CURSOR => @backingInt(window.mouse.cursor_mode),
            else => std.debug.panic("{s}: mode ({d}) not supported", .{ @src().fn_name, c_mode }),
        };
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn setInputMode(c_window_opt: ?*c.GLFWwindow, c_mode: c_int, c_value: c_int) callconv(.c) void {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        switch (c_mode) {
            c.GLFW_CURSOR => window.mouse.cursor_mode = @fromBackingInt(c_value),
            else => std.debug.panic("{s}: mode ({d}) not supported", .{ @src().fn_name, c_mode }),
        }
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getGamepadState(jid: c_int, state: ?*c.GLFWgamepadstate) callconv(.c) c_int {
    _ = .{ jid, state };
    return c.GLFW_FALSE; // disable gamepads
}

pub fn getWindowContentScale(c_window_opt: ?*c.GLFWwindow, xscale: ?*f32, yscale: ?*f32) callconv(.c) void {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        const scale = if (window.isHiDPIAware()) window.monitor_scale else 1.0;
        if (xscale) |x| x.* = scale;
        if (yscale) |y| y.* = scale;
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getMonitorContentScale(c_monitor_opt: ?*c.GLFWmonitor, xscale: ?*f32, yscale: ?*f32) callconv(.c) void {
    if (c_monitor_opt) |c_monitor| {
        const monitor: *js.platform.Monitor = @ptrCast(@alignCast(c_monitor));
        if (xscale) |x| x.* = monitor.scale;
        if (yscale) |y| y.* = monitor.scale;
    } else js.console.err("{s}: monitor parameter is null", .{@src().fn_name});
}

pub fn getWindowSize(c_window_opt: ?*c.GLFWwindow, width: ?*c_int, height: ?*c_int) callconv(.c) void {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        if (width) |w| w.* = std.math.cast(c_int, window.width) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(window.framebuffer_height)), @src().fn_name });
        if (height) |h| h.* = std.math.cast(c_int, window.height) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(window.framebuffer_height)), @src().fn_name });
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getFramebufferSize(c_window_opt: ?*c.GLFWwindow, width: ?*c_int, height: ?*c_int) callconv(.c) void {
    if (c_window_opt) |c_window| {
        const window: *js.platform.Window = @ptrCast(@alignCast(c_window));
        if (width) |w| w.* = std.math.cast(c_int, window.framebuffer_width) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(window.framebuffer_height)), @src().fn_name });
        if (height) |h| h.* = std.math.cast(c_int, window.framebuffer_height) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(window.framebuffer_height)), @src().fn_name });
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getTime() callconv(.c) f64 {
    return js.time.now();
}
