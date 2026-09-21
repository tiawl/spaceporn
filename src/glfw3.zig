const std = @import("std");
const c = @import("c");
const js = @import("js");

var gpa = std.heap.wasm_allocator;

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

// ImGui never set a custom error handler this is why we don't implement this function
pub fn setErrorCallback(callback: c.GLFWerrorfun) callconv(.c) c.GLFWerrorfun {
    _ = callback;
    return null;
}

pub fn getClipboardString(window: ?*c.GLFWwindow) callconv(.c) [*:0]const u8 {
    _ = window;
    return js.platform.clipboard.getText();
}

pub fn setClipboardString(window: ?*c.GLFWwindow, c_str: ?[*:0]const u8) callconv(.c) void {
    _ = window;
    js.platform.clipboard.setText(std.mem.span(c_str orelse ""));
}

pub fn setCursor(window: ?*c.GLFWwindow, c_cursor_opt: ?*c.GLFWcursor) callconv(.c) void {
    _ = window;
    if (c_cursor_opt) |c_cursor| {
        js.platform.mouse.setCursor(@ptrCast(@alignCast(c_cursor)));
    } else js.console.err("{s}: cursor parameter is null", .{@src().fn_name});
}

pub fn getCursorPos(window: ?*c.GLFWwindow, xpos: ?*f64, ypos: ?*f64) callconv(.c) void {
    _ = window;
    if (xpos) |x| x.* = js.platform.mouse.getCursorPosX();
    if (ypos) |y| y.* = js.platform.mouse.getCursorPosY();
}

pub fn setCursorPos(window: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
    _ = .{ window, xpos, ypos };
    std.debug.panic("{s} is not possible to implement: JavaScript can't move the mouse pointer", .{@src().fn_name});
}

pub fn getKey(window: ?*c.GLFWwindow, key: c_int) callconv(.c) c_int {
    _ = window;
    return @backingInt(js.platform.keyboard.getKeyState(@fromBackingInt(key)));
}

pub fn getKeyName(key: c_int, scancode: c_int) callconv(.c) [*:0]const u8 {
    return js.platform.keyboard.getKeyName(@fromBackingInt(key), @fromBackingInt(scancode));
}

// ImGui use this function to pop stacking errors so this is why we don't implement it
pub fn getError(description: ?*?[*:0]const u8) callconv(.c) c_int {
    _ = description;
    return c.GLFW_NO_ERROR;
}

pub fn createStandardCursor(c_shape: c_int) callconv(.c) ?*c.GLFWcursor {
    const cursor = gpa.create(js.platform.Cursor) catch std.debug.panic("{s}: out of memory", .{@src().fn_name});
    cursor.* = .{
        .shape = @fromBackingInt(c_shape),
    };
    return @ptrCast(@alignCast(cursor));
}

pub fn destroyCursor(c_cursor_opt: ?*c.GLFWcursor) callconv(.c) void {
    if (c_cursor_opt) |c_cursor| {
        const cursor: *js.platform.Cursor = @ptrCast(@alignCast(c_cursor));
        gpa.destroy(cursor);
    } else js.console.err("{s}: cursor parameter is null", .{@src().fn_name});
}

pub fn getWindowAttrib(window: ?*c.GLFWwindow, c_attrib: c_int) callconv(.c) c_int {
    _ = window;
    return switch (c_attrib) {
        c.GLFW_FOCUSED => if (js.platform.window.isFocused()) c.GLFW_TRUE else c.GLFW_FALSE,
        else => std.debug.panic("{s}: window attrib ({d}) not supported", .{ @src().fn_name, c_attrib }),
    };
}

pub fn getInputMode(window: ?*c.GLFWwindow, c_mode: c_int) callconv(.c) c_int {
    _ = window;
    return switch (c_mode) {
        c.GLFW_CURSOR => @backingInt(js.platform.mouse.getCursorMode()),
        else => std.debug.panic("{s}: mode ({d}) not supported", .{ @src().fn_name, c_mode }),
    };
}

pub fn setInputMode(window: ?*c.GLFWwindow, c_mode: c_int, c_value: c_int) callconv(.c) void {
    _ = window;
    switch (c_mode) {
        c.GLFW_CURSOR => js.platform.mouse.setCursorMode(@fromBackingInt(c_value)),
        else => std.debug.panic("{s}: mode ({d}) not supported", .{ @src().fn_name, c_mode }),
    }
}

pub fn getGamepadState(jid: c_int, state: ?*c.GLFWgamepadstate) callconv(.c) c_int {
    _ = .{ jid, state };
    return c.GLFW_FALSE; // disable gamepads
}

pub fn getWindowContentScale(window: ?*c.GLFWwindow, xscale: ?*f32, yscale: ?*f32) callconv(.c) void {
    _ = window;
    if (xscale) |x| x.* = js.platform.window.getMonitorScale();
    if (yscale) |y| y.* = js.platform.window.getMonitorScale();
}

pub fn getMonitorContentScale(monitor: ?*c.GLFWmonitor, xscale: ?*f32, yscale: ?*f32) callconv(.c) void {
    _ = .{ monitor, xscale, yscale };
    @panic(@src().fn_name ++ " not implemented");
}

pub fn getWindowSize(window: ?*c.GLFWwindow, width: ?*c_int, height: ?*c_int) callconv(.c) void {
    _ = window;
    if (width) |w| {
        const canvas_width = js.platform.canvas.getWidth();
        w.* = std.math.cast(c_int, canvas_width) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(canvas_width)), @src().fn_name });
    }
    if (height) |h| {
        const canvas_height = js.platform.canvas.getHeight();
        h.* = std.math.cast(c_int, canvas_height) orelse std.debug.panic("{s}: failed to cast {s} to c_int", .{ @typeName(@TypeOf(canvas_height)), @src().fn_name });
    }
}

pub fn getFramebufferSize(window: ?*c.GLFWwindow, width: ?*c_int, height: ?*c_int) callconv(.c) void {
    getWindowSize(window, width, height);
}

pub fn getTime() callconv(.c) f64 {
    return js.time.now() / std.time.ms_per_s;
}
