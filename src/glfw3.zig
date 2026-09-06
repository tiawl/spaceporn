const std = @import("std");
const c = @import("c");
const js = @import("js");

var allocator = std.heap.wasm_allocator;

// This GLFW implementation is minimal. It aims to allow imgui compilation with GLFW backend on a wasm-freestanding target.
// It is not aimed to be fully implemented.

var c_error_callback_opt: c.GLFWerrorfun = null;

fn errorCallbackWrapper(error_code: c_int, description: ?[:0]const u8) void {
    if (c_error_callback_opt) |c_errorCallback| c_errorCallback(error_code, description orelse "");
}

pub fn setWindowFocusCallback(window: ?*c.GLFWwindow, callback: c.GLFWwindowfocusfun) callconv(.c) c.GLFWwindowfocusfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setCursorPosCallback(window: ?*c.GLFWwindow, callback: c.GLFWcursorposfun) callconv(.c) c.GLFWcursorposfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setCursorEnterCallback(window: ?*c.GLFWwindow, callback: c.GLFWcursorenterfun) callconv(.c) c.GLFWcursorenterfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setMouseButtonCallback(window: ?*c.GLFWwindow, callback: c.GLFWmousebuttonfun) callconv(.c) c.GLFWmousebuttonfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setScrollCallback(window: ?*c.GLFWwindow, callback: c.GLFWscrollfun) callconv(.c) c.GLFWscrollfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setKeyCallback(window: ?*c.GLFWwindow, callback: c.GLFWkeyfun) callconv(.c) c.GLFWkeyfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setCharCallback(window: ?*c.GLFWwindow, callback: c.GLFWcharfun) callconv(.c) c.GLFWcharfun {
    _ = .{ window, callback };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn setMonitorCallback(callback: c.GLFWmonitorfun) callconv(.c) c.GLFWmonitorfun {
    _ = callback;
    @panic(@src().fn_name ++ " not implemented");
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
        if (xscale) |x| x.* = window.monitor_scale;
        if (yscale) |y| y.* = window.monitor_scale;
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
        if (width) |w| w.* = std.math.cast(c_int, window.canvas.width) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(window.canvas.width)), @src().fn_name });
        if (height) |h| h.* = std.math.cast(c_int, window.canvas.height) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(window.canvas.height)), @src().fn_name });
    } else js.console.err("{s}: window parameter is null", .{@src().fn_name});
}

pub fn getFramebufferSize(window: ?*c.GLFWwindow, width: ?*c_int, height: ?*c_int) callconv(.c) void {
    getWindowSize(window, width, height);
}

pub fn getTime() callconv(.c) f64 {
    return js.time.now();
}
