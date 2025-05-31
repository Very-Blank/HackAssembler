const std = @import("std");
const parser = @import("parser.zig");
const SecondPass = @import("secondPass.zig").SecondPass;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

test "TestProgram" {
    const allocator: std.mem.Allocator = debug_allocator.allocator();
    const buffer: []const u8 =
        \\@2
        \\D=A
        \\@3
        \\D=D+A
        \\@0
        \\M=D
        \\(INFINITE_LOOP)
        \\@INFINITE_LOOP
        \\0;JMP
    ;

    var par = try parser.Parser.init(allocator);
    defer par.deinit();

    var value: SecondPass = par.firstPass(buffer) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    defer value.deinit();

    const expectedOutput: []const u8 =
        \\0000000000000010
        \\1110110000010000
        \\0000000000000011
        \\1110000010010000
        \\0000000000000000
        \\1110001100001000
        \\0000000000000110
        \\1110101010000111
    ;

    const hack = try value.secondPass();
    defer allocator.free(hack);

    if (hack.len - 1 != expectedOutput.len) return error.@"Didn't match to expected output";

    for (0..hack.len - 1) |i| {
        if (hack[i] != expectedOutput[i]) {
            std.debug.print("Instruction was assembeled wrongly line: {any}, instruction: {any}\n", .{ value.instructions[i / 17].line, value.instructions[i / 17].type });
            return error.@"Didn't match to expected output";
        }
    }
}
