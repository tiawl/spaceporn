const std = @import ("std");
const c = @import ("c");

//      // An include result.
//      typedef struct shaderc_include_result {
//        // The name of the source file.  The name should be fully resolved
//        // in the sense that it should be a unique name in the context of the
//        // includer.  For example, if the includer maps source names to files in
//        // a filesystem, then this name should be the absolute path of the file.
//        // For a failed inclusion, this string is empty.
//        const char* source_name;
//        size_t source_name_length;
//        // The text contents of the source file in the normal case.
//        // For a failed inclusion, this contains the error message.
//        const char* content;
//        size_t content_length;
//        // User data to be passed along with this request.
//        void* user_data;
//      } shaderc_include_result;
//
//      // The kinds of include requests.
//      enum shaderc_include_type {
//        shaderc_include_type_relative,  // E.g. #include "source"
//        shaderc_include_type_standard   // E.g. #include <source>
//      };
//
//      // An includer callback type for mapping an #include request to an include
//      // result.  The user_data parameter specifies the client context.  The
//      // requested_source parameter specifies the name of the source being requested.
//      // The type parameter specifies the kind of inclusion request being made.
//      // The requesting_source parameter specifies the name of the source containing
//      // the #include request.  The includer owns the result object and its contents,
//      // and both must remain valid until the release callback is called on the result
//      // object.
//      typedef shaderc_include_result* (*shaderc_include_resolve_fn)(
//          void* user_data, const char* requested_source, int type,
//          const char* requesting_source, size_t include_depth);
//
//      // An includer callback type for destroying an include result.
//      typedef void (*shaderc_include_result_release_fn)(
//          void* user_data, shaderc_include_result* include_result);
//
//      pub const shaderc_include_resolve_fn = ?*const fn (?*anyopaque, [*c]const u8, c_int, [*c]const u8, usize) callconv(.C) [*c]shaderc_include_result;
//      pub const shaderc_include_result_release_fn = ?*const fn (?*anyopaque, [*c]shaderc_include_result) callconv(.C) void;

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

  c.shaderc_compile_options_set_target_env (options,
    c.shaderc_target_env_vulkan, env_version);

  c.shaderc_compile_options_set_optimization_level (options, optimization);

  //c.shaderc_compile_options_set_include_callbacks (options);

  var shaders_path: ?[] const u8 = null;

  while (arg.next ()) |in|
  {
    if (shaders_path == null)
    {
      var it = try std.fs.path.componentIterator (in);
      var skip = it.last ();
      while (skip != null and !std.mem.eql (u8, skip.?.name, "shaders")) skip = it.previous ();
      var components = std.ArrayList ([] const u8).init (allocator);
      if (skip != null and std.mem.eql (u8, skip.?.name, "shaders"))
      {
        try components.append (try allocator.dupe (u8, skip.?.name));
        while (it.previous ()) |prev| try components.append (try allocator.dupe (u8, prev.name));
        std.mem.reverse ([] const u8, components.items);
        shaders_path = try std.fs.path.join (allocator, components.items);
      } else return error.FailedToBuildShadersPath;
    }

    const out = arg.next ().?;
    const stage = @intFromEnum (std.meta.stringToEnum (Stage,
      std.fs.path.extension (in) [1 ..]).?);

    std.log.info ("Compiling {s}", .{ in, });

    in_dir = try std.fs.openDirAbsolute (std.fs.path.dirname (in).?, .{});
    defer in_dir.close ();

    const source = try in_dir.readFileAllocOptions (allocator,
      std.fs.path.basename (in), std.math.maxInt (usize), null, 1, 0);

    const relative = try std.fs.path.relative (allocator, shaders_path.?, in);

    const result = c.shaderc_compile_into_spv (compiler, source.ptr,
      source.len, stage, relative.ptr, std.fs.path.stem (relative).ptr, options);
    defer c.shaderc_result_release (result);

    const status = c.shaderc_result_get_compilation_status (result);

    if (status != c.shaderc_compilation_status_success)
    {
      std.debug.print ("Shader compilation error for \"{s}\": {s}",
        .{ in, c.shaderc_result_get_error_message (result), });
    }

    const bytes = c.shaderc_result_get_bytes (result);
    const length = c.shaderc_result_get_length (result);

    out_dir = try std.fs.openDirAbsolute (std.fs.path.dirname (out).?, .{});
    defer out_dir.close ();

    try out_dir.writeFile (std.fs.path.basename (out),
      std.mem.sliceAsBytes (bytes [0 .. length]));
  }
}
