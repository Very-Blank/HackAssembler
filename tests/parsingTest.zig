const std = @import("std");
const FirstPass = @import("HackAsm").FirstPass;
const SecondPass = @import("HackAsm").SecondPass;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

test "TestProgram" {
    const allocator: std.mem.Allocator = debug_allocator.allocator();
    const buffer: []const u8 =
        \\// Adds 1 + ... + 100
        \\@i // This syntax makes me want to puke, it's rather dumb.
        \\// Values and varibales shouldn't be declared with the same symbol!
        \\M=1// i=1
        \\@sum
        \\M=0// sum=0
        \\(LOOP)
        \\@i
        \\D=M // D=i
        \\@100
        \\D=D-A // D=i-100
        \\@END
        \\D;JGT // if (i-100)>0 goto END
        \\@i
        \\D=M// D=i
        \\@sum
        \\M=D+M // sum=sum+i
        \\@i
        \\M=M+1 // i=i+1
        \\@LOOP
        \\0;JMP // goto LOOP
        \\(END)
        \\@END
        \\0;JMP // infinite loop
    ;

    var firstPass = try FirstPass.init(allocator);
    defer firstPass.deinit();

    var secondPass: SecondPass = firstPass.firstPass(buffer) catch |err| {
        std.debug.print("{any}\n", .{err});
        return err;
    };

    secondPass.deinit();
}
