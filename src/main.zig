const std = @import("std");
const builtin = @import("builtin");
const parser = @import("parser.zig");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const allocator: std.mem.Allocator, const is_debug: bool = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };

    defer if (is_debug) {
        std.debug.print("Debug allocator: {any}\n", .{debug_allocator.deinit()});
    };

    const file: std.fs.File = try std.fs.cwd().openFile("src/compTest.txt", .{});
    const length: u64 = try file.getEndPos();
    const buffer: []u8 = try allocator.alloc(u8, length);
    defer allocator.free(buffer);
    _ = try file.readAll(buffer);

    try parser.Parser.firstPass(buffer);
}
