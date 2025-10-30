//! The context is where all the steps and modules declared are stored.
//!
//! If needed before the build description is evaluated you can initialise the context yourself and add modules.
//! One use case is to add modules created using code gen to the context.
//!
//! It defines 4 steps:
//!   - `run`: Runs the executable if one is defined. If multiple `.exe` modules are deifned you will need to pass the option: `-Dname=<exe_name>`
//!   - `check`: Only checks the modules qre valid but don't emit anything. 
//!   - `test`: run the tests.
//!   - `docs`: generate the documentation of the modules.
const std = @import("std");
const Build = std.Build;

const Context = @This();

b: *Build,
/// Module storage by name.
modules: std.StringHashMap(*Build.Module),
/// Target of the build.
target: Build.ResolvedTarget,
/// Optimization mode of the build.
optimize: std.builtin.OptimizeMode,
/// The step checking the modules without producing artifacts.
check_step: *Build.Step = undefined,
/// The step running the tests.
test_step: *Build.Step = undefined,
/// The step running the executable.
run_step: *Build.Step = undefined,
/// The step for building the command to run with the executable.
exe_step: ?*Build.Step.Run = null,
/// The step running the executable.
doc_step: *Build.Step = undefined,
/// The name of the module to filter by.
target_module_name: ?[]const u8,

/// Initialize the context with standard arguments.
pub fn init(b: *std.Build) Context {
    return .{
        .b = b,
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .modules = .init(b.allocator),
        .check_step = b.step("check", "Check that all modules, libraries and binaries compile."),
        .test_step = b.step("test", "Run all the tests."),
        .run_step = b.step("run", "Run the default executable."),
        .doc_step = b.step("doc", "Run the default executable."),
        .target_module_name = b.option(
            []const u8,
            "name",
            "Filter the module/executable/library name to run/check/test.",
        ),
    };
}

/// Add a module to the context. If added before evaluating the build description the modules are available as imports in the description. Be careful of the name matching.
pub fn addModule(self: *Context, name: []const u8, mod: *Build.Module) void {
    self.modules.put(name, mod) catch @panic("OOM");
}
