const std = @import("std");
const FirstPass = @import("HackAsm").FirstPass;
const SecondPass = @import("HackAsm").SecondPass;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

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

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    var secondPass: SecondPass = firstPass.firstPass(buffer) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    secondPass.deinit();
}

test "Invalid" {
    const allocator: std.mem.Allocator = debug_allocator.allocator();

    const buffers: [52][]const u8 = .{ "M=Dx", "D=0?", "A-DJMP", "D;JGT^", "D|A;JEQ#", "ADM=M-1;JGE@", "MD=M-1", "AMD=!M", "MD", "0JMP", "D+MJGE", "D=MJNE", "AM=D+1JGE", "AD=0JMP", "MD=D-1JGT", "M=1JLT", "A=D&AJEQ", "AMD=!MJLE", "D=D|MJMP", "ADM=M-1JGE", "B=0", "X=D", "A=2", "D=!", "M-1;JUMP", "0;J", "D|A;JGEQ", "D;JGT!", "M=D;123", "AMD=!M;J", "ADM=M-1;JMPX", "=1;JMP", "D=;", "M-1;", "0;", "=;JMP", "D=1;", "A=;", "D+A", "1", "JMP", "A=1;;", "=D", "=1;JMP", "D=;", "D=;JMP", "0;", "D|A;", "=M;JMP", "=;JMP", "D=1;", "A=;" };

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    for (buffers) |buffer| {
        var secondPass: SecondPass = firstPass.firstPass(buffer) catch {
            continue;
        };

        secondPass.deinit();
        return error.TestFailed;
    }
}
