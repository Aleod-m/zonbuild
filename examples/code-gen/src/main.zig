const std = @import("std");
const gen = @import("generated");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    gen.printFromGen();
}
