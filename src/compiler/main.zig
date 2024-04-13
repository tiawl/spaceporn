const std = @import ("std");
const c = @import ("c");

const IncludeContext = struct
{
  dirname: [] const u8,
};

// An includer callback type for mapping an #include request to an include
// result.
// - The "user_data" parameter specifies the client context.
// - The "requested_source" parameter specifies the name of the source being
//   requested.
// - The "type" parameter specifies the kind of inclusion request being made.
// - The "requesting_source" parameter specifies the name of the source
//   containing the #include request.
// - The includer owns the result object and its contents,and both must remain
//   valid until the release callback is called on the result object.
fn resolve_include (user_data: ?*anyopaque, requested_source: [*c] const u8,
  @"type": c_int, requesting_source: [*c] const u8,
  include_depth: usize) callconv (.C) [*c] c.shaderc_include_result
{
  const context: *const IncludeContext = @alignCast (@ptrCast (user_data.?));
  const includer_name =
    std.mem.span (@as ([*:0] const u8, @ptrCast (requesting_source)));
  const header_name =
    std.mem.span (@as ([*:0] const u8, @ptrCast (requested_source)));

  // The kinds of include requests:
  // - shaderc_include_type_relative: E.g. #include "source"
  // - shaderc_include_type_standard: E.g. #include <source>
  if (@"type" != c.shaderc_include_type_relative)
  {
    std.debug.print ("Shader compilation error for \"{s}\": Only relative included supported",
      .{ includer_name, });
    std.debug.panic ("", .{});
  }

  const result = std.heap.c_allocator.create (c.shaderc_include_result) catch
  {
    std.debug.print ("Shader compilation error for \"{s}\" during include resolution: result allocation failed",
      .{ includer_name, });
    std.debug.panic ("", .{});
  };

  std.log.info ("  includer_name: \"{s}\"", .{ includer_name, });
  std.log.info ("  includer_depth: {}", .{ include_depth, });
  std.log.info ("  header_name: \"{s}\"", .{ header_name, });
  std.log.info ("  context.dirname: \"{s}\"", .{ context.dirname, });

  var dir = std.fs.openDirAbsolute (context.dirname, .{}) catch
  {
    std.debug.print ("Shader compilation error for \"{s}\" during include resolution: open dir failed",
      .{ includer_name, });
    std.debug.panic ("", .{});
  };
  defer dir.close ();

  const content = dir.readFileAllocOptions (std.heap.c_allocator,
    header_name, std.math.maxInt (usize), null, 1, 0) catch
  {
    std.debug.print ("Shader compilation error for \"{s}\" during include resolution: read file allocation failed",
      .{ includer_name, });
    std.debug.panic ("", .{});
  };

  // The name of the source file. The name should be fully resolved
  // in the sense that it should be a unique name in the context of the
  // includer. For example, if the includer maps source names to files in
  // a filesystem, then this name should be the absolute path of the file.
  // For a failed inclusion, this string is empty.
  result.source_name = header_name.ptr;
  result.source_name_length = header_name.len;

  // The text contents of the source file in the normal case.
  // For a failed inclusion, this contains the error message.
  result.content = content.ptr [0 .. :0];
  result.content_length = content.len;

  // User data to be passed along with this request.
  result.user_data = null;

  return result;
}

// An includer callback type for destroying an include result.
fn release_include (user_data: ?*anyopaque,
  include_result: [*c] c.shaderc_include_result) callconv (.C) void
{
  _ = user_data;

  std.heap.c_allocator.destroy (@as (*c.shaderc_include_result,
    @ptrCast (include_result)));
}

const Stage = enum (c.shaderc_shader_kind)
{
  vert = c.shaderc_glsl_vertex_shader,
  frag = c.shaderc_glsl_fragment_shader,
};

const VulkanEnvVersion = enum (c.shaderc_env_version)
{
  @"0" = c.shaderc_env_version_vulkan_1_0,
  @"1" = c.shaderc_env_version_vulkan_1_1,
  @"2" = c.shaderc_env_version_vulkan_1_2,
  @"3" = c.shaderc_env_version_vulkan_1_3,
};

const Optimization = enum (c.shaderc_optimization_level)
{
  Zero = c.shaderc_optimization_level_zero,
  Performance = c.shaderc_optimization_level_performance,
};

pub fn main () !void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  const allocator = arena.allocator ();

  var arg = std.process.args ();
  _ = arg.next ().?;
  const optimization =
    @intFromEnum (std.meta.stringToEnum (Optimization, arg.next ().?).?);
  const env_version =
    @intFromEnum (std.meta.stringToEnum (VulkanEnvVersion, arg.next ().?).?);

  var in_dir: std.fs.Dir = undefined;
  var out_dir: std.fs.Dir = undefined;

  const compiler = c.shaderc_compiler_initialize ();
  defer c.shaderc_compiler_release (compiler);

  const options = c.shaderc_compile_options_initialize ();
  defer c.shaderc_compile_options_release (options);

  c.shaderc_compile_options_set_source_language (options,
    c.shaderc_source_language_glsl);

  c.shaderc_compile_options_set_target_env (options,
    c.shaderc_target_env_vulkan, env_version);

  c.shaderc_compile_options_set_optimization_level (options, optimization);

  var include_context: IncludeContext = undefined;
  var shaders_path: ?[] const u8 = null;

  while (arg.next ()) |in|
  {
    std.log.info ("Compiling {s}", .{ in, });

    if (shaders_path == null)
    {
      var it = try std.fs.path.componentIterator (in);
      var skip = it.last ();
      while (skip != null and !std.mem.eql (u8, skip.?.name, "shaders"))
        skip = it.previous ();
      var components = std.ArrayList ([] const u8).init (allocator);
      if (skip != null and std.mem.eql (u8, skip.?.name, "shaders"))
      {
        try components.append (try allocator.dupe (u8, skip.?.name));
        while (it.previous ()) |prev| try components.append (
          try allocator.dupe (u8, prev.name));
        try components.append ("/");
        std.mem.reverse ([] const u8, components.items);
        shaders_path = try std.fs.path.join (allocator, components.items);
      } else return error.FailedToBuildShadersPath;
    }

    const out = arg.next ().?;
    const stage = @intFromEnum (std.meta.stringToEnum (Stage,
      std.fs.path.extension (in) [1 ..]).?);

    include_context.dirname = std.fs.path.dirname (in).?;
    c.shaderc_compile_options_set_include_callbacks (options,
      resolve_include, release_include, &include_context);

    in_dir = try std.fs.openDirAbsolute (include_context.dirname, .{});
    defer in_dir.close ();

    const source = try in_dir.readFileAllocOptions (allocator,
      std.fs.path.basename (in), std.math.maxInt (usize), null, 1, 0);

    const relative = try std.fs.path.relative (allocator, shaders_path.?, in);

    // // The "input_file_name" is a null-termintated string. It is used as a
    // // tag to identify the source string in cases like emitting error
    // // messages. It doesn't have to be a 'file name'.
    // // The "entry_point_name" null-terminated string defines the name of
    // // the entry point to associate with this GLSL source:
    // fn shaderc_compile_into_spv (compiler: shaderc_compiler_t,
    //   source_text: [*c] const u8, source_text_size: usize,
    //   shader_kind: shaderc_shader_kind, input_file_name: [*c] const u8,
    //   entry_point_name: [*c] const u8,
    //   additional_options: shaderc_compile_options_t)
    //     shaderc_compilation_result_t;
    const result = c.shaderc_compile_into_spv (compiler, source.ptr [0 .. : 0],
      source.len, stage, relative.ptr, "main", options);
    defer c.shaderc_result_release (result);

    const status = c.shaderc_result_get_compilation_status (result);

    if (status != c.shaderc_compilation_status_success)
    {
      std.debug.print ("{s}",
        .{ c.shaderc_result_get_error_message (result), });
      return error.CompilationFailed;
    }

    const bytes = c.shaderc_result_get_bytes (result);
    const length = c.shaderc_result_get_length (result);

    out_dir = try std.fs.openDirAbsolute (std.fs.path.dirname (out).?, .{});
    defer out_dir.close ();

    try out_dir.writeFile (std.fs.path.basename (out),
      std.mem.sliceAsBytes (bytes [0 .. length]));
  }
}
