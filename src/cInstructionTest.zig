const std = @import("std");
const parser = @import("parser.zig");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
test "Valid, normal spacing" {
    // const allocator: std.mem.Allocator = debug_allocator.allocator();
}

test "Valid, random spacing" {
    const allocator: std.mem.Allocator = debug_allocator.allocator();
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

    var par = try parser.Parser.init(allocator);
    defer par.deinit();

    par.firstPass(buffer) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };
}

test "Invalid, normal spacing" {
    // const allocator: std.mem.Allocator = debug_allocator.allocator();
}

test "Invalid, random spacing" {
    // const allocator: std.mem.Allocator = debug_allocator.allocator();
}
