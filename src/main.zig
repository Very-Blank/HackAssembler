const std = @import("std");
const builtin = @import("builtin");

const FirstPass = @import("firstPass.zig").FirstPass;
const SecondPass = @import("secondPass.zig").SecondPass;
const instruction = @import("instruction.zig");
const SymbolTable = @import("symbolTable.zig").SymbolTable;
const Logger = @import("logger.zig").Logger;

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

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const logger: Logger = Logger.init();

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    for (1..args.len) |i| {
        const fileName = try getFileName(args[i], allocator);
        defer allocator.free(fileName);

        const file: std.fs.File = try std.fs.cwd().openFile(args[i], .{});
        defer file.close();

        const length: u64 = try file.getEndPos();

        const buffer: []u8 = try allocator.alloc(u8, length);
        defer allocator.free(buffer);

        _ = try file.readAll(buffer);

        var secondPass: SecondPass = try firstPass.firstPass(buffer, &logger);
        defer secondPass.deinit();

        if (secondPass.instructions.len == 0) {
            return logger.printError("No instructions found in the file\n", .{});
        }

        const hack = try secondPass.secondPass();
        defer allocator.free(hack);

        const newFile: std.fs.File = try std.fs.cwd().createFile(fileName, .{});
        defer newFile.close();

        try newFile.writeAll(hack);
    }
}

inline fn getFileName(buffer: []u8, allocator: std.mem.Allocator) ![]u8 {
    std.debug.assert(buffer.len > 0);
    var i: u64 = buffer.len - 1;

    while (0 < i) : (i -= 1) {
        if (buffer[i] == '.') {
            if (std.mem.eql(u8, buffer[i..buffer.len], ".asm")) {
                const fileName = try allocator.alloc(u8, buffer[0..i].len + 5);
                @memcpy(fileName[0..i], buffer[0..i]);
                @memcpy(fileName[i..fileName.len], ".hack");
                return fileName;
            }
        }
    }

    return error.@"File is not .asm";
}
