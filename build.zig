const std = @import("std");
const zon = @import("build.zig.zon");
const name = @tagName(zon.name);
const upname = blk: {
    var buf: [name.len]u8 = undefined;
    for (name, 0..) |c, i| buf[i] = std.ascii.toUpper(c);
    break :blk buf;
};
const cimgui = @import("cimgui_zig");
const Renderer = cimgui.Renderer;
const Platform = cimgui.Platform;
const TranslateC = @import("translate_c").Translator;

const BuildOptions = struct {
    target: std.Build.ResolvedTarget,
    mode: std.builtin.OptimizeMode,
};

const ShadersBuildOptions = struct {
    native: BuildOptions,
    tint: BuildOptions,
};

const Root = struct {
    builder: *std.Build,
    native: BuildOptions,
    pages: BuildOptions,
    shader: ShadersBuildOptions,
    pages_build: bool,
    trace_build: bool,
    release_build: bool,
    trace_dir: *std.Build.Step.WriteFile,
    constants_dir: *std.Build.Step.WriteFile,
    libc_dir: *std.Build.Step.WriteFile,
    op_dir: *std.Build.Step.WriteFile,
    webgpu_dir: *std.Build.Step.WriteFile,
    glfw3_dir: *std.Build.Step.WriteFile,
    spirv2wgsl_dir: *std.Build.Step.WriteFile,
    translate_c_dep: *std.Build.Dependency,
    mimalloc_dep: *std.Build.Dependency,
    spirv_headers_dep: *std.Build.Dependency,
    spirv_tools_dep: *std.Build.Dependency,
    dawn_dep: *std.Build.Dependency,
};

fn run(root: *Root, argv: []const []const u8, cwd: std.process.Child.Cwd) ![]u8 {
    return switch (root.builder.runFallible(argv, .{ .stderr_behavior = .ignore, .cwd = cwd })) {
        .success => |stdout| return stdout,
        .spawn_failed => |err| return err,
        .bad_exit_code => return error.ExitCodeFailure,
        .crashed => return error.ProcessTerminated,
    };
}

fn buildOptionsModule(root: *Root) !*std.Build.Module {
    const options = root.builder.addOptions();

    const git = root.builder.findProgram(.{ .names = &.{"git"} }) orelse return error.ProgramNotFound;
    const raw_taglist = try run(root, &[_][]const u8{
        git, "--git-dir", ".git", "tag", "-l", "0.0.0",
    }, .{ .dir = root.builder.root.root_dir.handle });
    if (std.mem.eql(u8, "0.0.0", std.mem.trim(u8, raw_taglist, &std.ascii.whitespace))) {
        _ = try run(root, &[_][]const u8{
            git, "--git-dir", ".git", "tag", "-d", "0.0.0",
        }, .{ .dir = root.builder.root.root_dir.handle });
    }
    const raw_init_commit = try run(root, &[_][]const u8{
        git, "--git-dir", ".git", "rev-list", "--max-parents=0", "HEAD",
    }, .{ .dir = root.builder.root.root_dir.handle });
    const init_commit = std.mem.trim(u8, raw_init_commit, &std.ascii.whitespace);
    _ = try run(root, &[_][]const u8{
        git, "--git-dir", ".git", "tag", "0.0.0", init_commit,
    }, .{ .dir = root.builder.root.root_dir.handle });
    const raw_git_describe = try run(root, &[_][]const u8{
        git, "--git-dir", ".git", "describe", "--match", "*.*.*", "--tags", "--abbrev=9",
    }, .{ .dir = root.builder.root.root_dir.handle });
    const git_describe = std.mem.trim(u8, raw_git_describe, &std.ascii.whitespace);

    const zon_version_sem = try std.SemanticVersion.parse(zon.version);

    var it = std.mem.splitScalar(u8, git_describe, '-');
    const tagged_ancestor = it.first();

    const tagged_ancestor_sem = try std.SemanticVersion.parse(tagged_ancestor);
    if (zon_version_sem.order(tagged_ancestor_sem) != .eq) {
        std.debug.print("build.zig.zon version '{}.{}.{}' must be equal to tagged ancestor '{}.{}.{}'\n", .{
            zon_version_sem.major, zon_version_sem.minor, zon_version_sem.patch, tagged_ancestor_sem.major, tagged_ancestor_sem.minor, tagged_ancestor_sem.patch,
        });
        return error.UnsynchronizedGitAndZON;
    }

    const suffix = switch (std.mem.count(u8, git_describe, "-")) {
        // Tagged commit
        0 => "",
        // Untagged commit
        2 => blk: {
            const commit_height = it.next().?;
            const commit_id = it.next().?;

            // Check that the commit hash is prefixed with a 'g' (a Git convention).
            if (commit_id.len < 1 or commit_id[0] != 'g') {
                std.debug.print("Unexpected `git describe` output: {s}\n", .{git_describe});
                return error.UnexpectedSystemCommandOutput;
            }

            _ = try std.fmt.parseUnsigned(u32, commit_height, 10);
            break :blk root.builder.fmt("-dev.{s}+{s}", .{ commit_height, commit_id[1..] });
        },
        else => {
            std.debug.print("Unexpected `git describe` output: {s}\n", .{git_describe});
            return error.UnexpectedSystemCommandOutput;
        },
    };

    const version_option = root.builder.fmt("{d}.{d}.{d}{s}", .{
        zon_version_sem.major, zon_version_sem.minor, zon_version_sem.patch, suffix,
    });
    options.addOption([:0]const u8, "name", name);
    options.addOption([]const u8, "upname", &upname);
    options.addOption([:0]const u8, "version", root.builder.allocator.dupeSentinel(u8, version_option, 0) catch @panic("OOM"));
    options.addOption(bool, "trace", root.trace_build);
    return options.createModule();
}

fn buildSPIRVShaderExecutable(root: *Root, path: []const u8, spirv_name: []const u8, comptime shader_type: []const u8) std.Build.LazyPath {
    const shader_mod = root.builder.createModule(.{
        .root_source_file = root.builder.path(path),
        .target = @field(root.shader, shader_type).target,
        .optimize = @field(root.shader, shader_type).mode,
    });

    const shader_exe = root.builder.addExecutable(.{
        .name = spirv_name,
        .root_module = shader_mod,
        .use_llvm = false,
        .use_lld = false,
    });

    return shader_exe.getEmittedBin();
}

fn importSPIRVShaders(root: *Root, module: *std.Build.Module) !void {
    var shaders_dir = try root.builder.root.root_dir.handle.openDir(root.builder.graph.io, root.builder.pathResolve(&.{ "src", "shaders" }), .{ .iterate = true });
    defer shaders_dir.close(root.builder.graph.io);
    var shaders_dir_it = shaders_dir.iterate();
    while (try shaders_dir_it.next(root.builder.graph.io)) |shader| {
        if (shader.kind != .file or !(std.mem.endsWith(u8, shader.name, ".vert.zig") or std.mem.endsWith(u8, shader.name, ".frag.zig"))) continue;
        const spv_name = std.mem.replaceOwned(u8, root.builder.allocator, shader.name, ".zig", ".spv") catch @panic("OOM");
        const shader_path = root.builder.pathResolve(&.{ "src", "shaders", shader.name });
        const spirv_path = buildSPIRVShaderExecutable(root, shader_path, spv_name, "native");
        module.addAnonymousImport(spv_name, .{
            .root_source_file = spirv_path,
        });
    }
}

fn buildPrototypesModule(root: *Root, log_mod: *std.Build.Module, cimgui_mod: *std.Build.Module) !*std.Build.Module {
    var native_source: std.ArrayList(u8) = .empty;
    var prototypes_source: std.ArrayList(u8) = .empty;

    const dir = try root.builder.root.root_dir.handle.openDir(root.builder.graph.io, ".", .{});
    defer dir.close(root.builder.graph.io);
    native_source.appendSlice(root.builder.allocator, dir.readFileAlloc(root.builder.graph.io, root.builder.pathResolve(&.{ "src", "native.zig" }), root.builder.allocator, .unlimited) catch @panic("OOM")) catch @panic("OOM");
    native_source.append(root.builder.allocator, 0) catch @panic("OOM");

    prototypes_source.appendSlice(root.builder.allocator,
        \\const std = @import("std");
        \\const c = @import("c");
        \\const log = @import("log");
        \\
        \\fn _loadStructless(comptime log_callback: ?*const fn(comptime fmt: []const u8, args: anytype) void) void {
        \\    inline for (@typeInfo(@This()).@"struct".decl_names) |decl_name| {
        \\        if (comptime !std.mem.startsWith(u8, decl_name, "vk")) continue;
        \\        if (@field(@This(), "_" ++ decl_name) == null) {
        \\            if (c.glfwGetInstanceProcAddress(null, decl_name ++ "\x00")) |addr| {
        \\                @field(@This(), "_" ++ decl_name) = @ptrCast(addr);
        \\                @field(@This(), decl_name) = @field(@This(), "_" ++ decl_name).?;
        \\                if (log_callback) |logFn| {
        \\                    logFn("loadStructless: {s} loaded", .{decl_name});
        \\                }
        \\            }
        \\        }
        \\    }
        \\}
        \\
        \\pub fn loadStructless() void {
        \\    _loadStructless(null);
        \\}
        \\
        \\pub fn debugLoadStructless() void {
        \\    _loadStructless(log.debug);
        \\}
        \\
        \\fn _loadInstance(instance: *c.VkInstance, comptime log_callback: ?*const fn(comptime fmt: []const u8, args: anytype) void) void {
        \\    inline for (@typeInfo(@This()).@"struct".decl_names) |decl_name| {
        \\        if (comptime !std.mem.startsWith(u8, decl_name, "vk")) continue;
        \\        if (@field(@This(), "_" ++ decl_name) == null) {
        \\            if (c.glfwGetInstanceProcAddress(instance.*, decl_name ++ "\x00")) |addr| {
        \\                @field(@This(), "_" ++ decl_name) = @ptrCast(addr);
        \\                @field(@This(), decl_name) = @field(@This(), "_" ++ decl_name).?;
        \\                if (log_callback) |logFn| {
        \\                    logFn("loadInstance: {s} loaded", .{decl_name});
        \\                }
        \\            }
        \\        }
        \\    }
        \\}
        \\
        \\pub fn loadInstance(instance: *c.VkInstance) void {
        \\    _loadInstance(instance, null);
        \\}
        \\
        \\pub fn debugLoadInstance(instance: *c.VkInstance) void {
        \\    _loadInstance(instance, log.debug);
        \\}
        \\
        \\fn _loadDevice(device: *c.VkDevice, comptime log_callback: ?*const fn(comptime fmt: []const u8, args: anytype) void) void {
        \\    inline for (@typeInfo(@This()).@"struct".decl_names) |decl_name| {
        \\        if (comptime !std.mem.startsWith(u8, decl_name, "vk")) continue;
        \\        if (@field(@This(), "_" ++ decl_name) == null) {
        \\            if (vkGetDeviceProcAddr(device.*, decl_name ++ "\x00")) |addr| {
        \\                @field(@This(), "_" ++ decl_name) = @ptrCast(addr);
        \\                @field(@This(), decl_name) = @field(@This(), "_" ++ decl_name).?;
        \\                if (log_callback) |logFn| {
        \\                    logFn("loadDevice: {s} loaded", .{decl_name});
        \\                }
        \\            }
        \\        }
        \\    }
        \\}
        \\
        \\pub fn loadDevice(device: *c.VkDevice) void {
        \\    _loadDevice(device, null);
        \\}
        \\
        \\pub fn debugLoadDevice(device: *c.VkDevice) void {
        \\    _loadDevice(device, log.debug);
        \\}
        \\
        \\var _vkGetDeviceProcAddr: c.PFN_vkGetDeviceProcAddr = null;
        \\pub var vkGetDeviceProcAddr: @typeInfo(c.PFN_vkGetDeviceProcAddr).optional.child = undefined;
        \\
    ) catch @panic("OOM");

    var it = std.zig.Tokenizer.init(native_source.items[0 .. native_source.items.len - 1 :0]);
    var token = it.next();

    var precedent: [2]?std.zig.Token = @splat(null);
    var set = std.BufSet.init(root.builder.allocator);

    while (token.tag != .eof) {
        if (precedent[precedent.len - 1] != null) {
            if (std.mem.eql(u8, native_source.items[precedent[1].?.loc.start..precedent[1].?.loc.end], "prototypes") and precedent[0].?.tag == .period and std.mem.startsWith(u8, native_source.items[token.loc.start..token.loc.end], "vk") and !set.contains(native_source.items[token.loc.start..token.loc.end])) {
                prototypes_source.appendSlice(root.builder.allocator, "var _") catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, native_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, ": c.PFN_") catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, native_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, " = null;\npub var ") catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, native_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, " : @typeInfo(c.PFN_") catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, native_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(root.builder.allocator, ").optional.child = undefined;\n") catch @panic("OOM");
                try set.insert(native_source.items[token.loc.start..token.loc.end]);
            }
        }

        for (1..precedent.len) |i| precedent[precedent.len - i] = precedent[precedent.len - i - 1];
        precedent[0] = token;
        token = it.next();
    }

    return root.builder.createModule(.{
        .root_source_file = root.builder.addWriteFiles().add("prototypes.zig", prototypes_source.items),
        .target = root.native.target,
        .optimize = root.native.mode,
        .imports = &.{
            .{
                .name = "c",
                .module = cimgui_mod,
            },
            .{
                .name = "log",
                .module = log_mod,
            },
        },
    });
}

fn buildNativeCImGuiModule(root: *Root) *std.Build.Module {
    const cimgui_dep = root.builder.dependency("cimgui_zig", .{
        .target = root.native.target,
        .optimize = root.native.mode,
        .platforms = &[_]Platform{.GLFW},
        .renderers = &[_]Renderer{.Vulkan},
    });
    const cimgui_lib = cimgui_dep.artifact("cimgui");

    const c_h = root.builder.addWriteFiles().add("c.h",
        \\#define GLFW_INCLUDE_VULKAN 1
        \\#define GLFW_INCLUDE_NONE 1
        \\#include "GLFW/glfw3.h"
        \\#include "dcimgui.h"
        \\#include "backends/dcimgui_impl_glfw.h"
        \\#include "backends/dcimgui_impl_vulkan.h"
        \\
    );

    return cimgui.createModule(root.builder, cimgui_dep, cimgui_lib, c_h);
}

fn buildLogModule(root: *Root, ffi_imports_mod: *std.Build.Module, pages_build: bool) *std.Build.Module {
    const options = root.builder.addOptions();
    options.addOption(bool, "pages_build", pages_build);
    return root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "log.zig" })),
        .target = if (pages_build) root.pages.target else root.native.target,
        .optimize = if (pages_build) root.pages.mode else root.native.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = pages_build,
        .imports = &.{
            .{
                .name = "build",
                .module = options.createModule(),
            },
            .{
                .name = "imports",
                .module = ffi_imports_mod,
            },
        },
    });
}

fn buildNativeExecutable(root: *Root, options_mod: *std.Build.Module) !void {
    const cimgui_mod = buildNativeCImGuiModule(root);
    const log_mod = buildLogModule(root, root.builder.createModule(.{ .root_source_file = root.builder.addWriteFiles().add("dummy.zig", "") }), false);
    const prototypes_mod = try buildPrototypesModule(root, log_mod, cimgui_mod);

    const native_mod = root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "native.zig" })),
        .target = root.native.target,
        .optimize = root.native.mode,
        .imports = &.{
            .{
                .name = "build",
                .module = options_mod,
            },
            .{
                .name = "c",
                .module = cimgui_mod,
            },
            .{
                .name = "prototypes",
                .module = prototypes_mod,
            },
            .{
                .name = "log",
                .module = log_mod,
            },
        },
    });

    const native_exe = root.builder.addExecutable(.{
        .name = name,
        .version = try std.SemanticVersion.parse(zon.version),
        .root_module = native_mod,
    });

    root.builder.installArtifact(native_exe);

    const run_cmd = root.builder.addRunArtifact(native_exe);
    run_cmd.step.dependOn(root.builder.getInstallStep());

    if (root.trace_build) {
        run_cmd.setEnvironmentVariable("VK_INSTANCE_LAYERS", "VK_LAYER_KHRONOS_validation");
        run_cmd.setEnvironmentVariable(upname ++ "_DEBUG", "true");
    }

    const run_step = root.builder.step("run", "Run natively");
    run_step.dependOn(&run_cmd.step);

    try importSPIRVShaders(root, native_exe.root_module);
}

fn buildShaderTypeModule(root: *Root) *std.Build.Module {
    return root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "shaders", "types.zig" })),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
    });
}

fn buildFFIImportsModule(root: *Root) *std.Build.Module {
    return root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "imports.zig" })),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
        .imports = &.{},
    });
}

fn buildFFIModule(root: *Root, shader_types_mod: *std.Build.Module, log_mod: *std.Build.Module, ffi_imports_mod: *std.Build.Module, options_mod: *std.Build.Module) *std.Build.Module {
    const glfw3_constants_h = root.builder.addConfigHeader(.{
        .style = .{
            .autoconf_undef = root.builder.path(root.builder.pathResolve(&.{ "src", "glfw3.h" })),
        },
    }, .{
        .GLFW3_H_MACROS = true,
        .GLFW3_H_IMPL = false,
        .GLFW3_H_STRUCTS = false,
        .GLFW3_H_FUNCS = false,
    });

    const webgpu_constants_h = root.builder.addConfigHeader(.{
        .style = .{
            .autoconf_undef = root.builder.path(root.builder.pathResolve(&.{ "src", "webgpu.h" })),
        },
    }, .{
        .WEBGPU_H_MACROS = true,
        .WEBGPU_H_ENUMS = true,
        .WEBGPU_H_FLAGS = true,
        .WEBGPU_H_IMPL = false,
        .WEBGPU_H_STRUCTS = false,
        .WEBGPU_H_FUNCS = false,
    });

    _ = root.constants_dir.addCopyFile(webgpu_constants_h.getOutputFile(), root.builder.pathResolve(&.{ "webgpu", "webgpu.h" }));
    _ = root.constants_dir.addCopyFile(glfw3_constants_h.getOutputFile(), root.builder.pathResolve(&.{ "GLFW", "glfw3.h" }));
    const translate_constants = TranslateC.init(root.translate_c_dep, .{
        .c_source_file = root.constants_dir.add("constants.h",
            \\#include "GLFW/glfw3.h"
            \\#include "webgpu/webgpu.h"
            \\
        ),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
    });

    return root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "js.zig" })),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
        .imports = &.{
            .{
                .name = "c",
                .module = translate_constants.mod,
            },
            .{
                .name = "build",
                .module = options_mod,
            },
            .{
                .name = "imports",
                .module = ffi_imports_mod,
            },
            .{
                .name = "shader",
                .module = shader_types_mod,
            },
            .{
                .name = "log",
                .module = log_mod,
            },
        },
    });
}

fn buildTraceLibrary(root: *Root, log_mod: *std.Build.Module) *std.Build.Step.Compile {
    var trace_h: *std.Build.Step.ConfigHeader = undefined;
    var trace_h_path: std.Build.LazyPath = undefined;

    if (root.trace_build) {
        trace_h = root.builder.addConfigHeader(.{
            .style = .{
                .autoconf_undef = root.builder.path(root.builder.pathResolve(&.{ "src", "trace.h" })),
            },
        }, .{
            .TRACE_ENABLED = 1,
        });

        trace_h_path = trace_h.getOutputFile();
    } else {
        trace_h_path = root.builder.path(root.builder.pathResolve(&.{ "src", "trace.h" }));
    }

    const translate_trace = TranslateC.init(root.translate_c_dep, .{
        .c_source_file = root.trace_dir.addCopyFile(trace_h_path, "trace.h"),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
    });

    const trace_mod = root.builder.createModule(.{
        .root_source_file = root.trace_dir.addCopyFile(root.builder.path(root.builder.pathResolve(&.{ "src", "trace.zig" })), "trace.zig"),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
        .imports = &.{
            .{
                .name = "c",
                .module = translate_trace.mod,
            },
            .{
                .name = "log",
                .module = log_mod,
            },
        },
    });

    const trace_lib = root.builder.addLibrary(.{
        .linkage = .static,
        .name = "trace",
        .root_module = trace_mod,
    });

    return trace_lib;
}

fn buildLibCModule(root: *Root, trace_lib: *std.Build.Step.Compile) void {
    const libc_h = root.builder.addConfigHeader(.{
        .style = .{
            .autoconf_undef = root.builder.path(root.builder.pathResolve(&.{ "src", "libc.h" })),
        },
    }, .{
        .LIBC_H_ASSERT = true,
        .LIBC_H_CTYPE = true,
        .LIBC_H_INTTYPES = true,
        .LIBC_H_MATH = true,
        .LIBC_H_STDIO = true,
        .LIBC_H_STDLIB = true,
        .LIBC_H_STRING = true,
        .LIBC_H_SYS_WAIT = true,
        .LIBC_H_TIME = true,
        .LIBC_H_UNISTD = true,
    });

    const translate_libc = TranslateC.init(root.translate_c_dep, .{
        .c_source_file = root.libc_dir.addCopyFile(libc_h.getOutputFile(), "libc.h"),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
    });
    translate_libc.addIncludePath(root.trace_dir.getDirectory());
    translate_libc.mod.linkLibrary(trace_lib);

    for ([_][]const u8{ "assert.h", "ctype.h", "inttypes.h", "math.h", "stdio.h", "stdlib.h", "string.h", root.builder.pathResolve(&.{ "sys", "wait.h" }), "time.h", "unistd.h" }) |libc_header| _ = root.libc_dir.add(libc_header, "#include \"libc.h\"");
}

fn buildWebGPUModule(root: *Root, trace_lib: *std.Build.Step.Compile) void {
    const webgpu_webgpu_h = root.builder.addConfigHeader(.{
        .style = .{
            .autoconf_undef = root.builder.path(root.builder.pathResolve(&.{ "src", "webgpu.h" })),
        },
    }, .{
        .WEBGPU_H_MACROS = true,
        .WEBGPU_H_ENUMS = true,
        .WEBGPU_H_FLAGS = true,
        .WEBGPU_H_IMPL = true,
        .WEBGPU_H_STRUCTS = true,
        .WEBGPU_H_FUNCS = true,
    });

    const translate_full_webgpu = TranslateC.init(root.translate_c_dep, .{
        .c_source_file = root.webgpu_dir.addCopyFile(webgpu_webgpu_h.getOutputFile(), root.builder.pathResolve(&.{ "webgpu", "webgpu.h" })),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
    });
    translate_full_webgpu.addIncludePath(root.trace_dir.getDirectory());
    translate_full_webgpu.mod.linkLibrary(trace_lib);
}

fn buildGLFW3Module(root: *Root, trace_lib: *std.Build.Step.Compile) void {
    const glfw_glfw3_h = root.builder.addConfigHeader(.{
        .style = .{
            .autoconf_undef = root.builder.path(root.builder.pathResolve(&.{ "src", "glfw3.h" })),
        },
    }, .{
        .GLFW3_H_MACROS = true,
        .GLFW3_H_IMPL = true,
        .GLFW3_H_STRUCTS = true,
        .GLFW3_H_FUNCS = true,
    });

    const translate_full_glfw3 = TranslateC.init(root.translate_c_dep, .{
        .c_source_file = root.glfw3_dir.addCopyFile(glfw_glfw3_h.getOutputFile(), root.builder.pathResolve(&.{ "GLFW", "glfw3.h" })),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
    });
    translate_full_glfw3.addIncludePath(root.trace_dir.getDirectory());
    translate_full_glfw3.mod.linkLibrary(trace_lib);
}

fn buildOpLibrary(root: *Root, trace_lib: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const op_mod = root.builder.createModule(.{
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
    });

    op_mod.addIncludePath(root.libc_dir.getDirectory());
    op_mod.linkLibrary(trace_lib);
    op_mod.addIncludePath(root.trace_dir.getDirectory());
    op_mod.addCSourceFile(.{
        .file = root.op_dir.addCopyFile(root.builder.path(root.builder.pathResolve(&.{ "src", "op.cpp" })), "op.cpp"),
        .flags = &.{},
    });

    const op_lib = root.builder.addLibrary(.{
        .linkage = .static,
        .name = "op",
        .root_module = op_mod,
    });

    return op_lib;
}

fn buildWASMCImGuiModule(root: *Root, op_lib: *std.Build.Step.Compile, trace_lib: *std.Build.Step.Compile) *std.Build.Module {
    const cimgui_dep = root.builder.dependency("cimgui_zig", .{
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .platforms = &[_]Platform{},
        .renderers = &[_]Renderer{},
        .no_platform = true,
        .no_renderer = true,
        .link_libc = false,
    });
    const cimgui_lib = cimgui_dep.artifact("cimgui");
    const cimgui_builder = cimgui_dep.builder;

    const webgpu_flags = [_][]const u8{"-DIMGUI_IMPL_WEBGPU_BACKEND_WGVK"};
    const glfw3_flags = [_][]const u8{};
    cimgui_lib.root_module.addCSourceFile(.{ .file = cimgui_builder.path(root.builder.pathResolve(&.{ "dcimgui", "master", "backends", "imgui_impl_wgpu.cpp" })), .flags = &webgpu_flags });
    cimgui_lib.root_module.addCSourceFile(.{ .file = cimgui_builder.path(root.builder.pathResolve(&.{ "dcimgui", "master", "backends", "dcimgui_impl_wgpu.cpp" })), .flags = &webgpu_flags });
    cimgui_lib.root_module.addCSourceFile(.{ .file = cimgui_builder.path(root.builder.pathResolve(&.{ "dcimgui", "master", "backends", "imgui_impl_glfw.cpp" })), .flags = &glfw3_flags });
    cimgui_lib.root_module.addCSourceFile(.{ .file = cimgui_builder.path(root.builder.pathResolve(&.{ "dcimgui", "master", "backends", "dcimgui_impl_glfw.cpp" })), .flags = &glfw3_flags });

    cimgui_lib.root_module.linkLibrary(trace_lib);
    cimgui_lib.root_module.addIncludePath(root.trace_dir.getDirectory());
    cimgui_lib.root_module.addIncludePath(root.libc_dir.getDirectory());
    cimgui_lib.root_module.addIncludePath(root.webgpu_dir.getDirectory());
    cimgui_lib.root_module.addIncludePath(root.glfw3_dir.getDirectory());
    cimgui_lib.root_module.linkLibrary(op_lib);

    const c_h = root.builder.addWriteFiles().add("c.h",
        \\#include "libc.h"
        \\#include "dcimgui.h"
        \\#include "GLFW/glfw3.h"
        \\#include "webgpu/webgpu.h"
        \\#include "backends/dcimgui_impl_glfw.h"
        \\#include "backends/dcimgui_impl_wgpu.h"
        \\
    );

    return cimgui.createModule(root.builder, cimgui_dep, cimgui_lib, c_h);
}

fn buildSPIRVToolsLibrary(root: *Root) !*std.Build.Step.Compile {
    const spirv_tools_mod = root.builder.createModule(.{
        .root_source_file = root.builder.addWriteFiles().add("dummy.zig", ""),
        .target = root.native.target,
        .optimize = root.native.mode,
        .link_libc = true,
        .link_libcpp = true,
    });

    const spirv_tools_lib = root.builder.addLibrary(.{
        .name = "KhronosGroup.SPIRV-Tools",
        .linkage = .static,
        .root_module = spirv_tools_mod,
    });

    const python3 = root.builder.findProgram(.{ .names = &.{"python3"} }) orelse return error.ProgramNotFound;

    const build_version_inc_cmd = root.builder.addSystemCommand(&.{python3});
    build_version_inc_cmd.addFileArg2(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "utils", "update_build_version.py" })), .{});
    build_version_inc_cmd.addFileArg2(root.spirv_tools_dep.builder.path("CHANGES"), .{});
    build_version_inc_cmd.addFileArg2(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "build", "build-version.inc" })), .{});
    build_version_inc_cmd.setCwd(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "build", "source" })));
    spirv_tools_lib.step.dependOn(&build_version_inc_cmd.step);

    const ggt_cmd = root.builder.addSystemCommand(&.{python3});
    ggt_cmd.addFileArg2(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "utils", "ggt.py" })), .{});
    ggt_cmd.addFileArg2(root.spirv_tools_dep.builder.path("core_tables_body.inc"), .{ .prefix = "--core-tables-body-output=" });
    ggt_cmd.addFileArg2(root.spirv_tools_dep.builder.path("core_tables_header.inc"), .{ .prefix = "--core-tables-header-output=" });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "spirv.core.grammar.json" })), .{ .prefix = "--spirv-core-grammar=" });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.glsl.std.450.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.opencl.std.100.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.opencl.debuginfo.100.grammar.json" })), .{ .prefix = "--extinst=CLDEBUG100_," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.nonsemantic.shader.debuginfo.100.grammar.json" })), .{ .prefix = "--extinst=SHDEBUG100_," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.spv-amd-shader-explicit-vertex-parameter.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.spv-amd-shader-trinary-minmax.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.spv-amd-gcn-shader.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.spv-amd-shader-ballot.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.debuginfo.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.nonsemantic.clspvreflection.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.nonsemantic.vkspreflection.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.tosa.001000.1.grammar.json" })), .{ .prefix = "--extinst=TOSA_," });
    ggt_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1", "extinst.arm.motion-engine.100.grammar.json" })), .{ .prefix = "--extinst=," });
    ggt_cmd.setCwd(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "build", "source" })));
    spirv_tools_lib.step.dependOn(&ggt_cmd.step);

    const registry_tables_cmd = root.builder.addSystemCommand(&.{python3});
    registry_tables_cmd.addFileArg2(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "utils", "generate_registry_tables.py" })), .{});
    registry_tables_cmd.addFileArg2(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "spir-v.xml" })), .{ .prefix = "--xml=" });
    registry_tables_cmd.addFileArg2(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "build", "generators.inc" })), .{ .prefix = "--generator-output=" });
    registry_tables_cmd.setCwd(root.spirv_tools_dep.builder.path(root.spirv_tools_dep.builder.pathResolve(&.{ "build", "source" })));
    spirv_tools_lib.step.dependOn(&registry_tables_cmd.step);

    const spirv_tools_source_dir = try root.spirv_tools_dep.builder.root.root_dir.handle.openDir(root.builder.graph.io, "source", .{ .iterate = true });
    defer spirv_tools_source_dir.close(root.builder.graph.io);
    var walker = try spirv_tools_source_dir.walk(root.builder.allocator);
    {
        defer walker.deinit();
        var is_cpp_source = false;
        while (try walker.next(root.builder.graph.io)) |entry| {
            const entry_path = root.spirv_tools_dep.builder.pathResolve(&.{ "source", entry.path });
            switch (entry.kind) {
                .file => {
                    is_cpp_source = false;
                    inline for (&.{ ".c", ".cc", ".cpp", ".cxx" }) |ext| is_cpp_source = (is_cpp_source or std.mem.endsWith(u8, entry.basename, ext));
                    if (std.fs.path.dirname(entry.path)) |dirname| {
                        var it = std.fs.path.componentIterator(dirname);
                        if (std.mem.eql(u8, it.first().?.name, "opt") or std.mem.eql(u8, it.first().?.name, "val") or std.mem.eql(u8, it.first().?.name, "util")) {
                            if (is_cpp_source) spirv_tools_lib.root_module.addCSourceFile(.{ .file = root.spirv_tools_dep.builder.path(entry_path) });
                        }
                    } else if (is_cpp_source) {
                        spirv_tools_lib.root_module.addCSourceFile(.{ .file = root.spirv_tools_dep.builder.path(entry_path) });
                    }
                },
                else => {},
            }
        }
    }

    const spirv_tools_build_dir = try root.spirv_tools_dep.builder.root.createDirPathOpen(root.builder.graph.io, "build", .{ .open_options = .{ .iterate = true } });
    defer spirv_tools_build_dir.close(root.builder.graph.io);
    try root.spirv_tools_dep.builder.root.createDirPath(root.builder.graph.io, root.spirv_tools_dep.builder.pathResolve(&.{ "build", "source" }));

    spirv_tools_lib.root_module.addCSourceFile(.{
        .file = root.mimalloc_dep.builder.path(root.mimalloc_dep.builder.pathResolve(&.{ "src", "static.c" })),
        .flags = &.{"-Wno-date-time"},
    });

    spirv_tools_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("."));
    spirv_tools_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("build"));
    spirv_tools_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("source"));
    spirv_tools_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("include"));
    spirv_tools_lib.root_module.addIncludePath(root.spirv_headers_dep.builder.path("."));
    spirv_tools_lib.root_module.addIncludePath(root.spirv_headers_dep.builder.path("include"));
    spirv_tools_lib.root_module.addIncludePath(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1" })));
    spirv_tools_lib.root_module.addIncludePath(root.mimalloc_dep.builder.path("."));
    spirv_tools_lib.root_module.addIncludePath(root.mimalloc_dep.builder.path("include"));

    return spirv_tools_lib;
}

fn addTintCSourceFile(root: *Root, tint_mod: *std.Build.Module, filename: []const u8, path: []const u8, flags: []const []const u8) void {
    switch (root.native.target.result.os.tag) {
        .windows => if ((std.mem.endsWith(u8, filename, "_linux.cc")) or (std.mem.endsWith(u8, filename, "_posix.cc")) or (std.mem.endsWith(u8, filename, "_mac.cc"))) return,
        .macos => if ((std.mem.endsWith(u8, filename, "_linux.cc")) or (std.mem.endsWith(u8, filename, "_posix.cc")) or (std.mem.endsWith(u8, filename, "_windows.cc"))) return,
        else => if ((std.mem.endsWith(u8, filename, "_mac.cc")) or (std.mem.endsWith(u8, filename, "_windows.cc"))) return,
    }
    if (std.mem.eql(u8, filename, "parse_num.cc")) return;
    if ((std.mem.endsWith(u8, filename, ".cc")) and !(std.mem.endsWith(u8, filename, "_bench.cc")) and !(std.mem.endsWith(u8, filename, "_test.cc"))) {
        tint_mod.addCSourceFile(.{ .file = root.dawn_dep.builder.path(path), .flags = flags });
    }
}

fn buildTintLibrary(root: *Root) !*std.Build.Step.Compile {
    const tint_mod = root.builder.createModule(.{
        .root_source_file = root.builder.addWriteFiles().add("dummy.zig", ""),
        .target = root.native.target,
        .optimize = root.native.mode,
        .link_libc = true,
        .link_libcpp = true,
    });

    const tint_lib = root.builder.addLibrary(.{
        .linkage = .static,
        .name = "google.tint",
        .root_module = tint_mod,
    });

    const flags = [_][]const u8{
        "-std=c++20",
        "-DTINT_BUILD_GLSL_WRITER=0",
        "-DTINT_BUILD_HLSL_WRITER=0",
        "-DTINT_BUILD_MSL_WRITER=0",
        "-DTINT_BUILD_NULL_WRITER=0",
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=0",
        "-DTINT_BUILD_WGSL_READER=0",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_IR_BINARY=0",
        "-Wno-unknown-warning-option",
    };

    var resolved_path: []const u8 = undefined;
    var dir: std.Io.Dir = undefined;
    var walker: std.Io.Dir.Walker = undefined;

    for ([_][]const []const u8{
        &.{ "src", "tint", "lang", "core", "constant" },
        &.{ "src", "tint", "lang", "core", "intrinsic" },
        &.{ "src", "tint", "lang", "core", "ir", "analysis" },
        &.{ "src", "tint", "lang", "core", "ir", "transform" },
        &.{ "src", "tint", "lang", "core", "ir", "validator" },
        &.{ "src", "tint", "lang", "core", "type" },
        &.{ "src", "tint", "lang", "spirv", "intrinsic" },
        &.{ "src", "tint", "lang", "spirv", "ir" },
        &.{ "src", "tint", "lang", "spirv", "reader" },
        &.{ "src", "tint", "lang", "spirv", "type" },
        &.{ "src", "tint", "lang", "spirv", "validate" },
        &.{ "src", "tint", "lang", "wgsl", "ast" },
        &.{ "src", "tint", "lang", "wgsl", "inspector" },
        &.{ "src", "tint", "lang", "wgsl", "intrinsic" },
        &.{ "src", "tint", "lang", "wgsl", "ir" },
        &.{ "src", "tint", "lang", "wgsl", "program" },
        &.{ "src", "tint", "lang", "wgsl", "resolver" },
        &.{ "src", "tint", "lang", "wgsl", "sem" },
        &.{ "src", "tint", "lang", "wgsl", "writer" },
        &.{ "src", "tint", "utils" },
    }) |paths| {
        resolved_path = root.dawn_dep.builder.pathResolve(paths);
        dir = try root.dawn_dep.builder.root.root_dir.handle.openDir(root.builder.graph.io, resolved_path, .{ .iterate = true });
        defer dir.close(root.builder.graph.io);

        walker = try dir.walk(root.builder.allocator);
        defer walker.deinit();
        while (try walker.next(root.builder.graph.io)) |entry| {
            const entry_path = root.dawn_dep.builder.pathResolve(&.{ resolved_path, entry.path });
            switch (entry.kind) {
                .file => addTintCSourceFile(root, tint_mod, entry.basename, entry_path, &flags),
                else => {},
            }
        }
    }

    var it: std.Io.Dir.Iterator = undefined;

    for ([_][]const []const u8{
        &.{ "src", "tint", "lang", "wgsl" },
        &.{ "src", "tint", "lang", "core" },
        &.{ "src", "tint", "lang", "core", "ir" },
        &.{ "src", "tint", "lang", "spirv" },
    }) |paths| {
        resolved_path = root.dawn_dep.builder.pathResolve(paths);
        dir = try root.dawn_dep.builder.root.root_dir.handle.openDir(root.builder.graph.io, resolved_path, .{ .iterate = true });
        defer dir.close(root.builder.graph.io);

        it = dir.iterate();
        while (try it.next(root.builder.graph.io)) |entry| {
            const entry_path = root.dawn_dep.builder.pathResolve(&.{ resolved_path, entry.name });
            switch (entry.kind) {
                .file => addTintCSourceFile(root, tint_mod, entry.name, entry_path, &flags),
                else => {},
            }
        }
    }

    tint_mod.addCSourceFile(.{ .file = root.dawn_dep.builder.path(root.dawn_dep.builder.pathResolve(&.{ "src", "tint", "api", "common", "vertex_pulling_config.cc" })), .flags = &flags });
    tint_mod.addCSourceFile(.{ .file = root.dawn_dep.builder.path(root.dawn_dep.builder.pathResolve(&.{ "src", "tint", "api", "tint.cc" })), .flags = &flags });

    tint_lib.root_module.addIncludePath(root.dawn_dep.builder.path("."));
    tint_lib.root_module.addIncludePath(root.dawn_dep.builder.path("include"));
    tint_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("."));
    tint_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("build"));
    tint_lib.root_module.addIncludePath(root.spirv_tools_dep.builder.path("include"));
    tint_lib.root_module.addIncludePath(root.spirv_headers_dep.builder.path("include"));
    tint_lib.root_module.addIncludePath(root.spirv_headers_dep.builder.path(root.spirv_headers_dep.builder.pathResolve(&.{ "include", "spirv", "unified1" })));

    tint_mod.addCSourceFile(.{
        .file = root.spirv2wgsl_dir.addCopyFile(root.builder.path(root.builder.pathResolve(&.{ "src", "c_tint.cpp" })), "c_tint.cpp"),
        .flags = &.{"-std=c++20"},
    });
    _ = root.spirv2wgsl_dir.addCopyFile(root.builder.path(root.builder.pathResolve(&.{ "src", "c_tint.h" })), "c_tint.h");

    tint_lib.root_module.addIncludePath(root.spirv2wgsl_dir.getDirectory());

    return tint_lib;
}

fn importWGSLShaders(root: *Root, module: *std.Build.Module) !void {
    var shaders_dir = try root.builder.root.root_dir.handle.openDir(root.builder.graph.io, root.builder.pathResolve(&.{ "src", "shaders" }), .{ .iterate = true });
    defer shaders_dir.close(root.builder.graph.io);

    const spirv_tools_lib = try buildSPIRVToolsLibrary(root);
    const tint_lib = try buildTintLibrary(root);

    const translate_libspirv_and_tint = TranslateC.init(root.translate_c_dep, .{
        .c_source_file = root.spirv2wgsl_dir.add("libspirv_and_tint.h",
            \\#include "spirv-tools/libspirv.h"
            \\#include "c_tint.h"
            \\
        ),
        .target = root.native.target,
        .optimize = root.native.mode,
        .link_libc = true,
    });
    translate_libspirv_and_tint.addIncludePath(root.spirv2wgsl_dir.getDirectory());
    translate_libspirv_and_tint.linkLibrary(spirv_tools_lib);
    translate_libspirv_and_tint.linkLibrary(tint_lib);

    translate_libspirv_and_tint.addIncludePath(root.spirv_tools_dep.builder.path("include"));

    const spirv2wgsl_mod = root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "spirv2wgsl.zig" })),
        .target = root.native.target,
        .optimize = root.native.mode,
        .imports = &.{
            .{
                .name = "c",
                .module = translate_libspirv_and_tint.mod,
            },
        },
    });

    const spirv2wgsl_exe = root.builder.addExecutable(.{
        .name = "spirv2wgsl",
        .root_module = spirv2wgsl_mod,
    });

    const spirv2wgsl_install = root.builder.addInstallArtifact(spirv2wgsl_exe, .{});
    root.builder.install_tls.step.dependOn(&spirv2wgsl_install.step);

    var spirv2wgsl: *std.Build.Step.Run = undefined;

    var shaders_dir_it = shaders_dir.iterate();
    while (try shaders_dir_it.next(root.builder.graph.io)) |shader| {
        if (shader.kind != .file or !(std.mem.endsWith(u8, shader.name, ".vert.zig") or std.mem.endsWith(u8, shader.name, ".frag.zig"))) continue;
        const shader_path = root.builder.pathResolve(&.{ "src", "shaders", shader.name });
        const wgsl_name = std.mem.replaceOwned(u8, root.builder.allocator, shader.name, ".zig", ".wgsl") catch @panic("OOM");
        const spv_name = std.mem.replaceOwned(u8, root.builder.allocator, shader.name, ".zig", ".spv") catch @panic("OOM");
        const spirv_path = buildSPIRVShaderExecutable(root, shader_path, spv_name, "tint");

        spirv2wgsl = root.builder.addRunArtifact(spirv2wgsl_exe);
        spirv2wgsl.step.dependOn(&spirv2wgsl_install.step);
        spirv2wgsl.addFileArg2(spirv_path, .{});
        const wgsl_path = spirv2wgsl.addOutputFileArg2(wgsl_name, .{});

        module.addAnonymousImport(wgsl_name, .{
            .root_source_file = wgsl_path,
        });
    }
}

fn buildPagesExecutable(root: *Root, options_mod: *std.Build.Module) !void {
    const shader_types_mod = buildShaderTypeModule(root);
    const ffi_imports_mod = buildFFIImportsModule(root);
    const log_mod = buildLogModule(root, ffi_imports_mod, true);
    const trace_lib = buildTraceLibrary(root, log_mod);
    buildLibCModule(root, trace_lib);
    buildWebGPUModule(root, trace_lib);
    buildGLFW3Module(root, trace_lib);
    const ffi_mod = buildFFIModule(root, shader_types_mod, log_mod, ffi_imports_mod, options_mod);
    const op_lib = buildOpLibrary(root, trace_lib);
    const cimgui_mod = buildWASMCImGuiModule(root, op_lib, trace_lib);

    const pages_mod = root.builder.createModule(.{
        .root_source_file = root.builder.path(root.builder.pathResolve(&.{ "src", "pages.zig" })),
        .target = root.pages.target,
        .optimize = root.pages.mode,
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
        .imports = &.{
            .{
                .name = "build",
                .module = options_mod,
            },
            .{
                .name = "c",
                .module = cimgui_mod,
            },
            .{
                .name = "js",
                .module = ffi_mod,
            },
            .{
                .name = "shader",
                .module = shader_types_mod,
            },
        },
    });

    try importWGSLShaders(root, pages_mod);

    const pages_exe = root.builder.addExecutable(.{
        .name = name,
        .version = try std.SemanticVersion.parse(zon.version),
        .root_module = pages_mod,
    });

    pages_exe.entry = .disabled;
    pages_exe.rdynamic = true;
    pages_exe.export_memory = true;

    pages_exe.stack_size = std.wasm.page_size * 512; // 32MB
    pages_exe.initial_memory = std.wasm.page_size * 1024; // 64MB

    const install = root.builder.addInstallArtifact(pages_exe, .{
        .dest_dir = .{ .override = .{ .custom = root.builder.pathResolve(&.{ "..", "src", "pages" }) } },
    });

    if (root.release_build) {
        const wasm_opt = root.builder.findProgram(.{ .names = &.{"wasm-opt"} }) orelse return error.ProgramNotFound;

        const wasm_opt_run_cmd = root.builder.addSystemCommand(&.{
            wasm_opt, "--enable-simd", "--enable-bulk-memory", "--enable-nontrapping-float-to-int", "--enable-sign-ext", "-Oz", "-o",
        });
        wasm_opt_run_cmd.addFileArg2(install.emitted_bin.?, .{});
        wasm_opt_run_cmd.addFileArg2(install.emitted_bin.?, .{});

        install.step.dependOn(&wasm_opt_run_cmd.step);
    }
    root.builder.getInstallStep().dependOn(&install.step);
}

pub fn build(builder: *std.Build) !void {
    var root: Root = .{
        .builder = builder,
        .native = .{
            .target = builder.standardTargetOptions(.{}),
            .mode = builder.standardOptimizeOption(.{}),
        },
        .pages = .{
            .target = builder.resolveTargetQuery(.{
                .cpu_arch = .wasm32,
                .os_tag = .freestanding,
                .abi = .none,
                .cpu_features_add = std.Target.wasm.featureSet(&.{
                    .simd128,
                    .bulk_memory,
                    .nontrapping_fptoint,
                    .sign_ext,
                }),
            }),
            .mode = .small,
        },
        .shader = .{
            .native = .{
                .target = builder.resolveTargetQuery(.{
                    .cpu_arch = .spirv32,
                    .cpu_model = .{ .explicit = &std.Target.spirv.cpu.vulkan_v1_2 },
                    .cpu_features_add = std.Target.spirv.featureSet(&.{.int64}),
                    .cpu_features_sub = std.Target.spirv.featureSet(&.{}),
                    .os_tag = .vulkan,
                    .ofmt = .spirv,
                }),
                .mode = .fast,
            },
            .tint = .{
                .target = builder.resolveTargetQuery(.{
                    .cpu_arch = .spirv32,
                    .cpu_model = .{ .explicit = &std.Target.spirv.cpu.generic },
                    .cpu_features_add = std.Target.spirv.featureSet(&.{.v1_3}),
                    .cpu_features_sub = std.Target.spirv.featureSet(&.{}),
                    .os_tag = .vulkan,
                    .ofmt = .spirv,
                }),
                .mode = .fast,
            },
        },
        .pages_build = builder.option(bool, "pages", "Perform pages build") orelse false,
        .trace_build = builder.option(bool, "trace", "Set a debug environment for native run and pages build") orelse false,
        .release_build = builder.option(bool, "release", "Performs optimization for release build") orelse false,
        .trace_dir = builder.addWriteFiles(),
        .constants_dir = builder.addWriteFiles(),
        .libc_dir = builder.addWriteFiles(),
        .op_dir = builder.addWriteFiles(),
        .webgpu_dir = builder.addWriteFiles(),
        .glfw3_dir = builder.addWriteFiles(),
        .spirv2wgsl_dir = builder.addWriteFiles(),
        .translate_c_dep = builder.dependency("translate_c", .{}),
        .mimalloc_dep = undefined,
        .spirv_headers_dep = undefined,
        .spirv_tools_dep = undefined,
        .dawn_dep = undefined,
    };

    const options_mod = try buildOptionsModule(&root);
    try buildNativeExecutable(&root, options_mod);
    if (root.pages_build) {
        var fetched_deps = true;
        if (builder.dependencyLazy("mimalloc", .{})) |dep| root.mimalloc_dep = dep else |_| fetched_deps = false;
        if (builder.dependencyLazy("SPIRV-Headers", .{})) |dep| root.spirv_headers_dep = dep else |_| fetched_deps = false;
        if (builder.dependencyLazy("SPIRV-Tools", .{})) |dep| root.spirv_tools_dep = dep else |_| fetched_deps = false;
        if (builder.dependencyLazy("dawn", .{})) |dep| root.dawn_dep = dep else |_| fetched_deps = false;
        if (fetched_deps) try buildPagesExecutable(&root, options_mod);
    }
}
