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

fn addIncludePathsToTranslateC(translate_c: *std.Build.Step.TranslateC, lib: *std.Build.Step.Compile) void {
    for (lib.root_module.include_dirs.items) |*included| {
        switch (included.*) {
            .path => translate_c.addIncludePath(included.path),
            .config_header_step => translate_c.addConfigHeader(included.config_header_step),
            .path_system => translate_c.addSystemIncludePath(included.path_system),
            .other_step => addIncludePathsToTranslateC(translate_c, included.other_step),
            else => unreachable,
        }
    }
}

fn run(builder: *std.Build, argv: []const []const u8) ![]u8 {
    if (@hasDecl(std.Build, "runFaillible")) {
        return switch (builder.runFaillible(argv, .{ .stderr_behavior = .ignore })) {
            .success => |stdout| return stdout,
            .spawn_failed => |err| return err,
            .bad_exit_code => return error.ExitCodeFailure,
            .crashed => return error.ProcessTerminated,
        };
    } else if (@hasDecl(std.Build, "runAllowFail")) {
        var code: u8 = undefined;
        return builder.runAllowFail(argv, &code, .ignore);
    } else unreachable;
}

fn buildOptions(builder: *std.Build) !*std.Build.Module {
    const options = builder.addOptions();

    const git = builder.findProgram(.{ .names = &.{"git"} }) orelse "git";
    const raw_taglist = try run(builder, &[_][]const u8{
        git,   "-C", (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).path orelse ".", "--git-dir", ".git",
        "tag", "-l", "0.0.0",
    });
    if (std.mem.eql(u8, "0.0.0", std.mem.trim(u8, raw_taglist, &std.ascii.whitespace))) {
        _ = try run(builder, &[_][]const u8{
            git,   "-C", (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).path orelse ".", "--git-dir", ".git",
            "tag", "-d", "0.0.0",
        });
    }
    const raw_init_commit = try run(builder, &[_][]const u8{
        git,        "-C",              (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).path orelse ".", "--git-dir", ".git",
        "rev-list", "--max-parents=0", "HEAD",
    });
    const init_commit = std.mem.trim(u8, raw_init_commit, &std.ascii.whitespace);
    _ = try run(builder, &[_][]const u8{
        git,   "-C",    (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).path orelse ".", "--git-dir", ".git",
        "tag", "0.0.0", init_commit,
    });
    const raw_git_describe = try run(builder, &[_][]const u8{
        git,        "-C",      (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).path orelse ".", "--git-dir", ".git",
        "describe", "--match", "*.*.*",                                                                                                                                                    "--tags",    "--abbrev=9",
    });
    const git_describe = std.mem.trim(u8, raw_git_describe, &std.ascii.whitespace);

    var it = std.mem.splitScalar(u8, git_describe, '.');
    const sem_breaking = it.next().?;
    const sem_feature = it.next().?;
    _ = try std.fmt.parseUnsigned(u32, sem_breaking, 10);
    _ = try std.fmt.parseUnsigned(u32, sem_feature, 10);

    const sem_patch = switch (std.mem.count(u8, git_describe, "-")) {
        // Tagged commit
        0 => it.next().?,
        // Untagged commit
        2 => blk: {
            it = std.mem.splitScalar(u8, git_describe, '-');
            const tagged_ancestor = it.first();
            const commit_height = it.next().?;
            const commit_id = it.next().?;

            const sem_version = try std.SemanticVersion.parse(builder.fmt("{s}.{s}.0", .{
                sem_breaking, sem_feature,
            }));
            const ancestor_version = try std.SemanticVersion.parse(tagged_ancestor);
            if (sem_version.order(ancestor_version) != .eq) {
                std.debug.print("Semantic version '{}.{}.{}' must be equal to tagged ancestor '{}.{}.{}'\n", .{
                    sem_version.major, sem_version.minor, sem_version.patch, ancestor_version.major, ancestor_version.minor, ancestor_version.patch,
                });
                std.process.exit(1);
            }

            // Check that the commit hash is prefixed with a 'g' (a Git convention).
            if (commit_id.len < 1 or commit_id[0] != 'g') {
                std.debug.print("Unexpected `git describe` output: {s}\n", .{
                    git_describe,
                });
                std.process.exit(1);
            }

            _ = try std.fmt.parseUnsigned(u32, commit_height, 10);
            break :blk builder.fmt("{s}+{s}", .{
                commit_height, commit_id[1..],
            });
        },
        else => {
            std.debug.print("Unexpected `git describe` output: {s}\n", .{
                git_describe,
            });
            std.process.exit(1);
        },
    };
    const version = builder.fmt("{s}.{s}.{s}", .{
        sem_breaking, sem_feature, sem_patch,
    });
    options.addOption([:0]const u8, "name", name);
    options.addOption([]const u8, "upname", &upname);
    options.addOption([:0]const u8, "version", try builder.allocator.dupeSentinel(u8, version, 0));
    return options.createModule();
}

fn compileShader(builder: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, module: *std.Build.Module, path: []const u8, out_name: []const u8) void {
    const shader = builder.addObject(.{
        .name = out_name,
        .root_module = builder.createModule(.{
            .root_source_file = builder.path(path),
            .target = target,
            .optimize = optimize,
        }),
        .use_llvm = false,
        .use_lld = false,
    });
    module.addAnonymousImport(out_name, .{
        .root_source_file = shader.getEmittedBin(),
    });
}

fn compileShaders(builder: *std.Build, optimize: std.builtin.OptimizeMode, exe: *std.Build.Step.Compile) !void {
    const vulkan12_target = builder.resolveTargetQuery(.{
        .cpu_arch = .spirv64,
        .cpu_model = .{ .explicit = &std.Target.spirv.cpu.vulkan_v1_2 },
        .cpu_features_add = std.Target.spirv.featureSet(&.{.int64}),
        .os_tag = .vulkan,
        .ofmt = .spirv,
    });

    var shaders_dir = try (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).handle.openDir(builder.graph.io, builder.pathResolve(&.{ "src", "shaders" }), .{ .iterate = true });
    defer shaders_dir.close(builder.graph.io);
    var shaders_dir_it = shaders_dir.iterate();
    while (try shaders_dir_it.next(builder.graph.io)) |shader| {
        if (shader.kind != .file or !(std.mem.endsWith(u8, shader.name, ".vert.zig") or std.mem.endsWith(u8, shader.name, ".frag.zig"))) continue;
        const spv_name = try std.mem.replaceOwned(u8, builder.allocator, shader.name, ".zig", ".spv");
        const shader_path = builder.pathResolve(&.{ "src", "shaders", shader.name });
        compileShader(builder, vulkan12_target, optimize, exe.root_module, shader_path, spv_name);
    }
}

fn prototypesModule(builder: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, c_module: *std.Build.Module) !*std.Build.Module {
    var main_source: std.ArrayList(u8) = .empty;
    var prototypes_source: std.ArrayList(u8) = .empty;

    const dir = try (if (@hasField(std.Build, "build_root")) builder.build_root else if (@hasField(std.Build, "root")) builder.root.root_dir else unreachable).handle.openDir(builder.graph.io, ".", .{});
    defer dir.close(builder.graph.io);
    main_source.appendSlice(builder.allocator, dir.readFileAlloc(builder.graph.io, builder.pathResolve(&.{ "src", "main.zig" }), builder.allocator, .unlimited) catch @panic("OOM")) catch @panic("OOM");
    main_source.append(builder.allocator, 0) catch @panic("OOM");

    prototypes_source.appendSlice(builder.allocator,
        \\const std = @import("std");
        \\const c = @import("c");
        \\
        \\const logCallback = std.log.debug;
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
        \\    _loadStructless(logCallback);
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
        \\    _loadInstance(instance, logCallback);
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
        \\    _loadDevice(device, logCallback);
        \\}
        \\
        \\var _vkGetDeviceProcAddr: c.PFN_vkGetDeviceProcAddr = null;
        \\pub var vkGetDeviceProcAddr: @typeInfo(c.PFN_vkGetDeviceProcAddr).optional.child = undefined;
        \\
    ) catch @panic("OOM");

    var it = std.zig.Tokenizer.init(main_source.items[0 .. main_source.items.len - 1 :0]);
    var token = it.next();

    var precedent: [2]?std.zig.Token = @splat(null);
    var set = std.BufSet.init(builder.allocator);

    while (token.tag != .eof) {
        if (precedent[precedent.len - 1] != null) {
            if (std.mem.eql(u8, main_source.items[precedent[1].?.loc.start..precedent[1].?.loc.end], "prototypes") and precedent[0].?.tag == .period and std.mem.startsWith(u8, main_source.items[token.loc.start..token.loc.end], "vk") and !set.contains(main_source.items[token.loc.start..token.loc.end])) {
                prototypes_source.appendSlice(builder.allocator, "var _") catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, main_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, ": c.PFN_") catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, main_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, " = null;\npub var ") catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, main_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, " : @typeInfo(c.PFN_") catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, main_source.items[token.loc.start..token.loc.end]) catch @panic("OOM");
                prototypes_source.appendSlice(builder.allocator, ").optional.child = undefined;\n") catch @panic("OOM");
                try set.insert(main_source.items[token.loc.start..token.loc.end]);
            }
        }

        for (1..precedent.len) |i| precedent[precedent.len - i] = precedent[precedent.len - i - 1];
        precedent[0] = token;
        token = it.next();
    }

    return builder.createModule(.{
        .root_source_file = builder.addWriteFiles().add("prototypes.zig", prototypes_source.items),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "c",
                .module = c_module,
            },
        },
    });
}

fn compileExe(builder: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const options_module = try buildOptions(builder);

    const cimgui_dep = builder.dependency("cimgui_zig", .{
        .target = target,
        .optimize = optimize,
        .platforms = &[_]Platform{.GLFW},
        .renderers = &[_]Renderer{.Vulkan},
    });

    const cimgui_lib = cimgui_dep.artifact("cimgui");

    const translate_c = builder.addTranslateC(.{
        .root_source_file = builder.addWriteFiles().add("c.h",
            \\#define GLFW_INCLUDE_VULKAN 1
            \\#define GLFW_INCLUDE_NONE 1
            \\#include "GLFW/glfw3.h"
            \\#include "dcimgui.h"
            \\#include "backends/dcimgui_impl_glfw.h"
            \\#include "backends/dcimgui_impl_vulkan.h"
            \\
        ),
        .target = target,
        .optimize = optimize,
    });

    addIncludePathsToTranslateC(translate_c, cimgui_lib);
    const c_module = translate_c.createModule();
    c_module.linkLibrary(cimgui_lib);

    const prototypes_module = try prototypesModule(builder, target, optimize, c_module);

    const exe = builder.addExecutable(.{
        .name = name,
        .root_module = builder.createModule(.{
            .root_source_file = builder.path(builder.pathResolve(&.{ "src", "main.zig" })),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "build",
                    .module = options_module,
                },
                .{
                    .name = "c",
                    .module = c_module,
                },
                .{
                    .name = "prototypes",
                    .module = prototypes_module,
                },
            },
        }),
    });

    builder.installArtifact(exe);

    return exe;
}

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    const exe = try compileExe(builder, target, optimize);
    try compileShaders(builder, optimize, exe);

    const run_cmd = builder.addRunArtifact(exe);
    run_cmd.step.dependOn(builder.getInstallStep());

    const dev = builder.option(bool, "dev", "Run for dev usage") orelse false;
    if (dev) {
        run_cmd.setEnvironmentVariable("VK_INSTANCE_LAYERS", "VK_LAYER_KHRONOS_validation");
        run_cmd.setEnvironmentVariable(upname ++ "_DEBUG", "true");
    }

    const run_step = builder.step("run", "Run with Vulkan validation layer");
    run_step.dependOn(&run_cmd.step);
}
