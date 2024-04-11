const std = @import ("std");
const c = @import ("c");

const Stage = enum (c_uint)
{
  vert = c.shaderc_glsl_vertex_shader,
  frag = c.shaderc_glsl_fragment_shader,
};

const VulkanEnvVersion = enum (c_uint)
{
  @"0" = c.shaderc_env_version_vulkan_1_0,
  @"1" = c.shaderc_env_version_vulkan_1_1,
  @"2" = c.shaderc_env_version_vulkan_1_2,
  @"3" = c.shaderc_env_version_vulkan_1_3,
};

const Optimization = enum (c_uint)
{
  Zero = c.shaderc_optimization_level_zero,
  Size = c.shaderc_optimization_level_size,
  Performance = c.shaderc_optimization_level_performance,
};

const shaderc_compile_options = extern struct
{
  target_env: c.shaderc_target_env = c.shaderc_target_env_default,
  target_env_version: c_uint = 0,
  compiler: c.shaderc_compiler_t,
  include_resolver: c.shaderc_include_resolve_fn = null,
  include_result_releaser: c.shaderc_include_result_release_fn = null,
  include_user_data: ?*anyopaque = null,
};

pub fn main () !void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  const allocator = arena.allocator ();

  var it = std.process.args ();
  _ = it.next ().?;
  const in = it.next ().?;
  const out = it.next ().?;
  const optimization = std.meta.stringToEnum (Optimization, it.next ().?).?;
  const env_version = std.meta.stringToEnum (VulkanEnvVersion, it.next ().?).?;
  const stage = std.meta.stringToEnum (Stage, in [in.len - 4 ..]).?;

  var dir = try std.fs.openDirAbsolute (std.fs.path.dirname (in).?, .{});
  defer dir.close ();

  const source =
    try dir.readFileAlloc (allocator, in, std.math.maxInt (usize));

  const compiler = c.shaderc_compiler_initialize ();
  defer c.shaderc_compiler_release (compiler);

  var options = shaderc_compile_options
  {
    .target_env = c.shaderc_target_env_vulkan,
    .target_env_version = @intFromEnum (env_version),
    .compiler = compiler,
  };

  c.shaderc_compile_options_set_optimization_level (
    @ptrCast (&options), @intFromEnum (optimization));

  const result = c.shaderc_compile_into_spv (compiler, source.ptr, source.len,
    @intFromEnum (stage), in, out, @ptrCast (&options));
  defer c.shaderc_result_release (result);

  const status = c.shaderc_result_get_compilation_status (result);

  if (status != c.shaderc_compilation_status_success)
  {
    std.debug.print ("Shader compilation error for \"{s}\": {s}",
      .{ in, c.shaderc_result_get_error_message (result), });
  }
}
