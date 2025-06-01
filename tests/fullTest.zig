const std = @import("std");
const FirstPass = @import("HackAsm").FirstPass;
const SecondPass = @import("HackAsm").SecondPass;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

fn fullTest(buffer: []const u8, expectedOutput: []const u8) !void {
    const allocator: std.mem.Allocator = debug_allocator.allocator();

    var parser = try FirstPass.init(allocator);
    defer parser.deinit();

    var secondPass: SecondPass = parser.firstPass(buffer) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    defer secondPass.deinit();

    const hack = try secondPass.secondPass();
    defer allocator.free(hack);

    if ((hack.len < expectedOutput.len and expectedOutput.len - hack.len > 16) or hack.len > expectedOutput.len and hack.len - expectedOutput.len > 16) {
        std.debug.print("Expected length: {any}\n", .{expectedOutput.len});
        std.debug.print("Was length: {any}\n", .{hack.len});
        return error.@"Didn't match to expected output";
    }

    for (0..hack.len - 1) |i| {
        if (hack[i] != expectedOutput[i]) {
            std.debug.print("Instruction was assembeled wrongly, debug info: \n", .{});
            std.debug.print("Instruction was : {s}\n", .{hack[(i / 17) * 17 .. (i / 17 + 1) * 17]});
            std.debug.print("Instruction expected: {s}\n", .{expectedOutput[(i / 17) * 17 .. (i / 17 + 1) * 17]});
            secondPass.instructions[i / 17].debugPrint();

            return error.@"Didn't match to expected output";
        }
    }
}
test "Add" {
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

    try fullTest(buffer, expectedOutput);
}

test "Max" {
    const buffer: []const u8 =
        \\@R0
        \\D=M
        \\@R1
        \\D=D-M
        \\@OUTPUT_FIRST
        \\D;JGT
        \\@R1
        \\D=M
        \\@OUTPUT_D
        \\0;JMP
        \\
        \\(OUTPUT_FIRST)
        \\@R0
        \\D=M
        \\
        \\(OUTPUT_D)
        \\@R2
        \\M=D
        \\
        \\(INFINITE_LOOP)
        \\@INFINITE_LOOP
        \\0;JMP
    ;

    const expectedOutput: []const u8 =
        \\0000000000000000
        \\1111110000010000
        \\0000000000000001
        \\1111010011010000
        \\0000000000001010
        \\1110001100000001
        \\0000000000000001
        \\1111110000010000
        \\0000000000001100
        \\1110101010000111
        \\0000000000000000
        \\1111110000010000
        \\0000000000000010
        \\1110001100001000
        \\0000000000001110
        \\1110101010000111
    ;

    try fullTest(buffer, expectedOutput);
}

test "Add 1 to 100" {
    const buffer: []const u8 =
        \\@i
        \\M=1
        \\@sum
        \\M=0
        \\(LOOP)
        \\@i
        \\D=M
        \\@100
        \\D=D-A
        \\@END
        \\D;JGT
        \\@i
        \\D=M
        \\@sum
        \\M=D+M
        \\@i
        \\M=M+1
        \\@LOOP
        \\0;JMP
        \\(END)
        \\@END
        \\0;JMP
    ;

    const expectedOutput: []const u8 =
        \\0000000000010000
        \\1110111111001000
        \\0000000000010001
        \\1110101010001000
        \\0000000000010000
        \\1111110000010000
        \\0000000001100100
        \\1110010011010000
        \\0000000000010010
        \\1110001100000001
        \\0000000000010000
        \\1111110000010000
        \\0000000000010001
        \\1111000010001000
        \\0000000000010000
        \\1111110111001000
        \\0000000000000100
        \\1110101010000111
        \\0000000000010010
        \\1110101010000111
    ;

    try fullTest(buffer, expectedOutput);
}

test "Mult" {
    const buffer: []const u8 =
        \\@2
        \\M=0
        \\@i
        \\M=0
        \\(LOOP)
        \\@i
        \\D=M
        \\@0
        \\D=D-M
        \\@END
        \\D;JGE
        \\
        \\@1
        \\D=M
        \\@2
        \\M=D+M
        \\@i
        \\M=M+1
        \\@LOOP
        \\0;JMP
        \\
        \\(END)
        \\@END
        \\0;JMP
    ;

    const expectedOutput: []const u8 =
        \\0000000000000010
        \\1110101010001000
        \\0000000000010000
        \\1110101010001000
        \\0000000000010000
        \\1111110000010000
        \\0000000000000000
        \\1111010011010000
        \\0000000000010010
        \\1110001100000011
        \\0000000000000001
        \\1111110000010000
        \\0000000000000010
        \\1111000010001000
        \\0000000000010000
        \\1111110111001000
        \\0000000000000100
        \\1110101010000111
        \\0000000000010010
        \\1110101010000111
    ;

    try fullTest(buffer, expectedOutput);
}

// Expected ouput was assembled by: https://github.com/aalhour/Assembler.hack.git
// NOTE: Seems to have a bug, with some invalid instructions getting through. But below was checked for those.
test "Deepseek's program" {
    // const buffer: []const u8 =
    // ;

    //
    // const expectedOutput: []const u8 =
    // ;
    //
    // try fullTest(buffer, expectedOutput);
}
