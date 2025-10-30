const std = @import("std");
const Build = std.Build;
const Context = @import("Context.zig");

const CompileDesc = @This();

/// The kind of the module.
kind: Kind,
/// The name of the module.
name: []const u8,
/// The root source file of the module. If not provided it is derived from the module kind.
root: ?[]const u8 = null,
/// The module visibility. By default all modules are public.
vis: Visibility = .public,
/// Imports available in this module.
imports: []const Import = &.{},
/// The steps this module should be part of. If not define they are drived from the module kind.
steps: ?[]const Step = null,

/// Defines which type of steps its included in by default and where is source file is located.
pub const Kind = enum {
    lib,
    exe,
    mod,

    /// Returns the default root source file path of the module.
    pub fn defaultRoot(self: Kind) []const u8 {
        return switch (self) {
            .lib, .mod => "src/root.zig",
            .exe => "src/main.zig",
        };
    }

    /// Returns the default steps in which the the module should be included in.
    pub fn defaultSteps(self: Kind) []const Step {
        return switch (self) {
            .lib, .mod => &.{ .check, .@"test", .doc },
            .exe => &.{ .check, .@"test", .run },
        };
    }

    /// Get the compile step for the module.
    pub fn getCompile(self: Kind, ctx: *Context, module: *Build.Module, name: []const u8) *Build.Step.Compile {
        return switch (self) {
            .lib, .mod => ctx.b.addLibrary(.{ .root_module = module, .name = name }),
            .exe => ctx.b.addExecutable(.{ .root_module = module, .name = name }),
        };
    }
};

/// Visibility of the module.
pub const Visibility = enum {
    private,
    public,
};

/// All kind of steps the module can be included in.
pub const Step = enum {
    check,
    @"test",
    run,
    doc,
};

/// Module import description.
pub const Import = struct {
    /// Name of the module import.
    name: []const u8,
    /// Rename the module for the use inside the module.
    as: ?[]const u8 = null,
};

/// Get a compile build step depending on the type of module.
pub fn getCompile(self: *const CompileDesc, ctx: *Context) *Build.Step.Compile {
    const module = ctx.modules.get(self.name).?;
    return self.kind.getCompile(ctx, module, self.name);
}
