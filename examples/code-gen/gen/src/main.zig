const std = @import("std");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var argsiter = std.process.args();
    _ = argsiter.next(); // Discard name.
    
    var output_dir: ?std.fs.Dir = null;

    while (argsiter.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-o")) {
            const path = std.mem.trimLeft(u8, arg, "-o");
            output_dir = try std.fs.cwd().openDir(path, .{});
        }
    }
    const dir = output_dir orelse return error.NoFilePath;
    const output = try dir.createFile("root.zig", .{});
    try output.writeAll(
      \\const std = @import("std");
      \\pub fn printFromGen() void {
      \\    std.debug.print("Hello from gen!", .{});
      \\}
    );
    output.close();
    
    return;
}
