const std = @import ("std");
const c = @import ("c");

extern fn glslang_default_resource () callconv (.C) *const c.glslang_resource_t;

const Stage = enum (c.glslang_stage_t)
{
  vert = c.GLSLANG_STAGE_VERTEX,
  frag = c.GLSLANG_STAGE_FRAGMENT,
};

const VulkanEnvVersion = enum (c.glslang_target_client_version_t)
{
  @"0" = c.GLSLANG_TARGET_VULKAN_1_0,
  @"1" = c.GLSLANG_TARGET_VULKAN_1_1,
  @"2" = c.GLSLANG_TARGET_VULKAN_1_2,
  @"3" = c.GLSLANG_TARGET_VULKAN_1_3,
};

const Optimization = enum
{
  Zero,
  Performance,
};

fn include_local (context: ?*anyopaque, header_name: [*c] const u8,
  includer_name: [*c] const u8, include_depth: usize) callconv (.C) [*c] c.glsl_include_result_t
{
  const ctx: *const struct { dir: [] const u8, } = @alignCast (@ptrCast (context.?));

  const result = std.heap.c_allocator.create (c.glsl_include_result_t) catch @panic ("oom");

  const includer_name_span = std.mem.span (@as([*:0]const u8, @ptrCast (includer_name)));
  const header_name_span = std.mem.span (@as ([*:0]const u8, @ptrCast (header_name)));

  const includer_dir_relative = std.fs.path.dirname (includer_name_span) orelse "";

  const file_path = std.fs.path.join (std.heap.c_allocator,
    &.{ ctx.dir, includer_dir_relative, header_name_span, }) catch @panic ("oom");

  const relative_to_root = std.fs.path.relative (std.heap.c_allocator,
    ctx.dir, file_path) catch @panic ("");

  std.log.info ("includer: \"{s}\"", .{ includer_name, });
  std.log.info ("includer_depth: {}", .{ include_depth, });
  std.log.info ("header_name: \"{s}\"", .{ header_name, });
  std.log.info ("relative_to_root: \"{s}\"", .{ relative_to_root, });

  const file_contents = std.fs.cwd ().readFileAlloc (std.heap.c_allocator, file_path, std.math.maxInt (u32)) catch return null;

  result.header_name = header_name;
  result.header_length = file_contents.len;
  result.header_data = file_contents.ptr;

  return result;
}

fn free_include_result (context: ?*anyopaque, glsl_include_result: [*c] c.glsl_include_result_t) callconv (.C) c_int
{
  _ = context;

  std.heap.c_allocator.destroy (@as (*c.glsl_include_result_t, @ptrCast (glsl_include_result)));

  return 0;
}

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
  const stage = @intFromEnum (std.meta.stringToEnum (Stage, in [in.len - 4 ..]).?);

  var context = .{ .dir = std.fs.path.dirname (in).?, };

  var dir = try std.fs.openDirAbsolute (context.dir, .{});
  defer dir.close ();

  const source =
    try dir.readFileAlloc (allocator, in, std.math.maxInt (usize));

  if (c.glslang_initialize_process () == 0)
    return error.FailedToInitializeProcess;
  defer c.glslang_finalize_process();

  var input = .{
    .language = c.GLSLANG_SOURCE_GLSL,
    .stage = stage,
    .client = c.GLSLANG_CLIENT_VULKAN,
    .client_version = env_version,
    .target_language = c.GLSLANG_TARGET_SPV,
    .target_language_version = c.GLSLANG_TARGET_SPV_1_5,
    .code = source.ptr,
    .default_version = 450,
    .default_profile = c.GLSLANG_NO_PROFILE,
    .force_default_version_and_profile = @intFromBool (false),
    .forward_compatible = @intFromBool (false),
    .messages = c.GLSLANG_MSG_DEFAULT_BIT | c.GLSLANG_MSG_DEBUG_INFO_BIT |
      c.GLSLANG_MSG_ENHANCED | c.GLSLANG_MSG_CASCADING_ERRORS_BIT,
    .resource = glslang_default_resource (),
    .callbacks = .{
      .include_local = &include_local,
      .include_system = &include_local,
      .free_include_result = &free_include_result,
    },
    .context = &context,
  };

  const shader = c.glslang_shader_create (@ptrCast (&input)) orelse
    return error.FailedToCreateShader;
  defer c.glslang_shader_delete (shader);

  c.glslang_shader_set_options (shader, c.GLSLANG_SHADER_AUTO_MAP_LOCATIONS);

  errdefer
  {
    const info_log = std.mem.span (@as ([*:0] const u8,
      @ptrCast (c.glslang_shader_get_info_log (shader))));

    var info_log_lines = std.mem.tokenize (u8, info_log, &.{ '\n', });

    while (info_log_lines.next ()) |info_log_line|
    {
      const error_token: [] const u8 = "ERROR: ";

      if (std.mem.startsWith (u8, info_log_line, error_token))
      {
        const error_message = info_log_line [error_token.len ..];

        if (std.mem.startsWith (u8, error_message, "0:"))
          std.log.err ("{s}:{s}", .{ in, error_message [2 ..], })
        else std.log.err ("{s}", .{ error_message, });
      }
    }

    const debug_log: ?[*:0] const u8 =
      @ptrCast (c.glslang_shader_get_info_debug_log (shader));

    if (debug_log != null and std.mem.span (debug_log.?).len != 0)
      std.log.debug ("{s}", .{ debug_log.?, });
  }

  if (c.glslang_shader_preprocess (shader, @ptrCast (&input)) == 0) return error.CompileFailed;
  if (c.glslang_shader_parse (shader, @ptrCast (&input)) == 0) return error.CompileFailed;

  const program = c.glslang_program_create () orelse return error.FailedToCreateProgram;
  defer c.glslang_program_delete (program);

  c.glslang_program_add_shader (program, shader);

  if (c.glslang_program_link (program, c.GLSLANG_MSG_SPV_RULES_BIT | c.GLSLANG_MSG_VULKAN_RULES_BIT) == 0) return error.LinkFailed;
  if (c.glslang_program_map_io (program) == 0) return error.InputOutputMappingFailed;

  c.glslang_program_add_source_text (program, stage, source.ptr, source.len);
  c.glslang_program_set_source_file (program, stage, in);

  var spirv_options: c.glslang_spv_options_t = .{
    .generate_debug_info = optimization != .Performance,
    .strip_debug_info = optimization == .Performance,
    .disable_optimizer = optimization != .Performance,
    .optimize_size = false,
    .disassemble = false,
    .validate = true,
    .emit_nonsemantic_shader_debug_info = optimization != .Performance,
    .emit_nonsemantic_shader_debug_source = optimization != .Performance,
  };

  c.glslang_program_SPIRV_generate_with_options (program, stage, &spirv_options);

  const spirv_messages = c.glslang_program_SPIRV_get_messages (program);

  if (spirv_messages != null)
  {
    std.log.err ("{s}", .{ spirv_messages, });
    return error.SpirvGenerationFailed;
  }

  const binary_size = c.glslang_program_SPIRV_get_size (program);
  const spirv_ptr = c.glslang_program_SPIRV_get_ptr (program);

  const spirv_data = spirv_ptr [0 .. binary_size];

  try std.fs.cwd ().writeFile (out, std.mem.sliceAsBytes (spirv_data));
}
