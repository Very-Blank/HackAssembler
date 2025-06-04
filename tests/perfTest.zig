const std = @import("std");
const FirstPass = @import("HackAsm").FirstPass;
const SecondPass = @import("HackAsm").SecondPass;

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
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\D;JGT // if (i-100)>0 goto END
    \\@i
    \\D=M// D=i
    \\@sum
    \\M=D+M // sum=sum+i
    \\@i
    \\M=M+1 // i=i+1
    \\@LOOP
    \\0;JMP // goto LOOP
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\D;JGT // if (i-100)>0 goto END
    \\@i
    \\D=M// D=i
    \\@sum
    \\M=D+M // sum=sum+i
    \\@i
    \\M=M+1 // i=i+1
    \\@LOOP
    \\0;JMP // goto LOOP
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\D;JGT // if (i-100)>0 goto END
    \\@i
    \\D=M// D=i
    \\@sum
    \\M=D+M // sum=sum+i
    \\@i
    \\M=M+1 // i=i+1
    \\@LOOP
    \\0;JMP // goto LOOP
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
    \\0;JMP // infinite loop
    \\// Adds 1 + ... + 100
    \\@i // This syntax makes me want to puke, it's rather dumb.
    \\// Values and varibales shouldn't be declared with the same symbol!
    \\M=1// i=1
    \\@sum
    \\M=0// sum=0
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
    \\@END
    \\0;JMP // infinite loop
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

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

test "TestProgram" {
    const allocator: std.mem.Allocator = debug_allocator.allocator();
    const iterations = 10_000; // Adjust for your needs
    //
    var timer = try std.time.Timer.start();
    const start = timer.lap();

    for (0..iterations) |_| {
        var firstPass = try FirstPass.init(allocator);
        defer firstPass.deinit();

        var secondPass: SecondPass = firstPass.firstPass(buffer) catch |err| {
            std.debug.print("{any}\n", .{err});
            return err;
        };

        secondPass.deinit();
    }

    const end = timer.read();
    const elapsed_ns = end - start;
    const elapsed_seconds = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;

    std.debug.print("Benchmark results:\n", .{});
    std.debug.print("  Total time: {d:.6} seconds\n", .{elapsed_seconds});
    std.debug.print("  Total runs: {}\n", .{iterations});
    std.debug.print("  Time per run: {d:.3} ns\n", .{@as(f64, @floatFromInt(elapsed_ns)) / iterations});
    std.debug.print("  Time per run: {d:.6} seconds\n", .{elapsed_seconds / iterations});
}
