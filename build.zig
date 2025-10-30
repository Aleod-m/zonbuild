const std = @import("std");
const Build = std.Build;
const lib = @import("./src/root.zig");
// Reexports
pub const Context = lib.Context;
pub const CompileDesc = lib.CompileDesc;
pub const BuildDesc = lib.BuildDesc;
pub const runDescWithContext = lib.runDescWithContext;
pub const runBuildDesc = lib.runBuildDesc;

pub fn build(b: *Build) void {
    // Generate documentation.
    const docs_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    const docs_compile_step = b.addObject(.{
        .name = "zonBuild",
        .root_module = docs_mod,
    });
    const docs_install = b.addInstallDirectory(.{
        .source_dir = docs_compile_step.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs/zonBuild",
    });

    const docs_step = b.step("docs", "Generate and install documentation");
    docs_step.dependOn(&docs_install.step);

    // Check step
    const check_lib = b.addLibrary(.{ .root_module = docs_mod, .name = "zonbuild" });
    const check_step = b.step("check", "Checks the code. without installing the artifact.");
    check_step.dependOn(&check_lib.step);
    
}


