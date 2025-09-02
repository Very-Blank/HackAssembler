const std = @import("std");
const instruction = @import("instruction.zig");
const SecondPass = @import("secondPass.zig").SecondPass;
const FirstPass = @import("firstPass.zig").FirstPass;
const Parser = @import("parser.zig").Parser;
const Logger = @import("logger.zig").Logger;

test "Valid, random spacing" {
    const allocator = std.testing.allocator;
    const buffer: []const u8 =
        \\AMD=!M;JLE
        \\D =D|M;JMP
        \\AD =0;JMP
        \\M =1;JLT
        \\D  =  M;JNE
        \\A  =D&A;  JEQ
        \\MD  =  D-1; JGT
        \\  AM=!M
        \\AMD  =  M-1;JGE
        \\  AD  =  D&A
        \\  D=  0
        \\M  =D
        \\  AMD  =  D|M
        \\A  =  1
        \\D  =  -1
        \\AMD  =M+1
        \\  0  ;  JMP
        \\D+M;JGE  
        \\M-1;JNE
        \\  D|A  ;  JEQ
        \\D;JGT  
        \\  1  ;JLE
        \\  -M;  JLT
        \\A-D;JMP
        \\D&A;JLT
        \\  AM  =  D+1;JGE
        \\  AD  =  0;  JMP
        \\MD  =  D-1;  JGT
        \\  M=1  ;JLT
        \\A  =  D&A  ;JEQ
        \\  AMD=  !M  ;JLE
        \\D  =  D|M  ;JMP
        \\AMD  =  M-1;JGE
        \\  M  =  D
        \\D=  0  
        \\AM  =  !M
        \\MD  =M-1
        \\AD  =D&A
        \\  AMD  =  D|M
        \\A=1  
        \\D=  -1
        \\AMD=  M+1
        \\0  ;JMP  
        \\D+M  ;JGE
        \\  M-1  ;JNE
        \\D|A  ;JEQ  
        \\D  ;  JGT
        \\  1;  JLE
        \\-M  ;  JLT
        \\  A-D  ;  JMP
        \\D&A;  JLT
        \\D  =  M;JNE
        \\  AM  =  D+1;JGE
        \\AD  =0;JMP  
        \\  MD  =  D-1;JGT
        \\M  =1  ;JLT
        \\A  =  D&A;JEQ
        \\AMD=!M;  JLE
        \\D  =D|M  ;JMP
        \\AMD  =M-1  ;JGE
        \\  M=D  
        \\D  =  0
        \\  AM=  !M
        \\  MD  =  M-1
        \\AD  =  D&A
        \\  AMD  =D|M
        \\A  =1
        \\  D  =  -1
        \\  AMD  =  M+1
        \\0;  JMP
        \\D+M;JGE  
        \\M-1  ;JNE
        \\  D|A;JEQ  
        \\D  ;JGT
        \\1;  JLE
        \\  -M  ;JLT
        \\A-D  ;JMP
        \\D&A  ;JLT
        \\  D=M  ;JNE
        \\AM  =  D+1  ;JGE
        \\AD  =  0;JMP
        \\  MD=D-1;  JGT
        \\M  =1;JLT
        \\  A  =D&A  ;JEQ
        \\  AMD  =  !M;JLE
        \\D  =D|M;  JMP
        \\AMD  =  M-1;JGE
    ;

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    const logger: Logger = Logger.init();
    var secondPass: SecondPass = firstPass.firstPass(buffer, &logger) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    secondPass.deinit();
}

test "Add" {
    const allocator = std.testing.allocator;
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

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    const logger: Logger = Logger.init();
    var secondPass: SecondPass = firstPass.firstPass(buffer, &logger) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    defer secondPass.deinit();

    const hack = try secondPass.secondPass();
    defer allocator.free(hack);

    try std.testing.expectEqualSlices(u8, expectedOutput, hack[0 .. hack.len - 1]);
}

test "Max" {
    const allocator = std.testing.allocator;

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

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    const logger: Logger = Logger.init();
    var secondPass: SecondPass = firstPass.firstPass(buffer, &logger) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    defer secondPass.deinit();

    const hack = try secondPass.secondPass();
    defer allocator.free(hack);

    try std.testing.expectEqualSlices(u8, expectedOutput, hack[0 .. hack.len - 1]);
}

test "Add 1 to 100" {
    const allocator = std.testing.allocator;
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

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    const logger: Logger = Logger.init();
    var secondPass: SecondPass = firstPass.firstPass(buffer, &logger) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    defer secondPass.deinit();

    const hack = try secondPass.secondPass();
    defer allocator.free(hack);

    try std.testing.expectEqualSlices(u8, expectedOutput, hack[0 .. hack.len - 1]);
}

test "Mult" {
    const allocator = std.testing.allocator;
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

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    const logger: Logger = Logger.init();
    var secondPass: SecondPass = firstPass.firstPass(buffer, &logger) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    defer secondPass.deinit();

    const hack = try secondPass.secondPass();
    defer allocator.free(hack);

    try std.testing.expectEqualSlices(u8, expectedOutput, hack[0 .. hack.len - 1]);
}
