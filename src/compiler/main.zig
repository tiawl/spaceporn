const std = @import ("std");
const shaderc = @import ("shaderc");

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
  include_depth: usize) callconv (.C) [*c] shaderc.Include.Result
{
  const context: *const IncludeContext = @alignCast (@ptrCast (user_data.?));
  const includer_name =
    std.mem.span (@as ([*:0] const u8, @ptrCast (requesting_source)));
  const c_header_name: [*:0] const u8 = @ptrCast (requested_source);
  const header_name = std.mem.span (c_header_name);

  if (@"type" != @intFromEnum (shaderc.Include.Type.Relative))
  {
    std.debug.print ("Shader compilation error for \"{s}\": Only relative included supported",
      .{ includer_name, });
    std.debug.panic ("", .{});
  }

  const result = std.heap.c_allocator.create (shaderc.Include.Result) catch
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
  result.source_name = c_header_name;
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
fn release_include (_: ?*anyopaque,
  include_result: [*c] shaderc.Include.Result) callconv (.C) void
{
  std.heap.c_allocator.destroy (@as (*shaderc.Include.Result,
    @ptrCast (include_result)));
}

pub fn main () !void
{
  var arena = std.heap.ArenaAllocator.init (std.heap.page_allocator);
  defer arena.deinit ();
  const allocator = arena.allocator ();

  var arg = try std.process.ArgIterator.initWithAllocator (allocator);
  _ = arg.next ().?;
  const optimization = std.meta.stringToEnum (
    shaderc.OptimizationLevel, arg.next ().?).?;
  const env_version = std.meta.stringToEnum (
    shaderc.Env.VulkanVersion, arg.next ().?).?;

  var in_dir: std.fs.Dir = undefined;
  var out_dir: std.fs.Dir = undefined;

  const compiler = shaderc.Compiler.initialize ();
  defer compiler.release ();

  const options = shaderc.CompileOptions.initialize ();
  defer options.release ();

  options.setSourceLanguage (shaderc.SourceLanguage.GLSL);
  options.setVulkanVersion (env_version);
  options.setOptimizationLevel (optimization);

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
    const kind = shaderc.ShaderKind.init (std.fs.path.extension (in));

    include_context.dirname = std.fs.path.dirname (in).?;
    options.setIncludeCallbacks (resolve_include, release_include,
      &include_context);

    in_dir = try std.fs.openDirAbsolute (include_context.dirname, .{});
    defer in_dir.close ();

    const source = try in_dir.readFileAlloc (allocator,
      std.fs.path.basename (in), std.math.maxInt (usize));

    const relative = try std.fs.path.relative (allocator, shaders_path.?, in);

    const result = try compiler.compileIntoSpv (allocator, source, kind,
      relative, options);
    defer result.release ();

    const status = result.getCompilationStatus ();

    if (status != shaderc.Compilation.Status.Success)
    {
      std.debug.print ("{s}", .{ result.getErrorMessage (), });
      return error.CompilationFailed;
    }

    const bytes = result.getBytes ();

    out_dir = try std.fs.openDirAbsolute (std.fs.path.dirname (out).?, .{});
    defer out_dir.close ();

    try out_dir.writeFile (.{ .sub_path = std.fs.path.basename (out), .data = bytes, });
  }
}
