const std = @import("std");

const MAX = 50;

// const BufferedWriter = std.io.BufferedWriter(4096, std.io.GenericWriter(std.fs.File, std.posix.WriteError, std.fs.File.write));
const Writer = std.io.GenericWriter(std.fs.File, std.posix.WriteError, std.fs.File.write);
// const Writer = std.io.GenericWriter(*BufferedWriter, std.posix.WriteError, BufferedWriter.write);

// test "quick test" {
//     var logger = Logger.init();
//     const buffer: []const u8 =
//         \\// Adds 1 + ... + 100
//         \\@i // This syntax makes me want to puke, it's rather dumb.
//         \\// Values and varibales shouldn't be declared with the same symbol!
//         \\M=1// i=1
//         \\@sum
//         \\M=0// sum=0
//         \\(LOOP)
//         \\@i
//         \\D=M // D=i
//         \\@100
//         \\D=D-A // D=i-100
//         \\@END
//         \\D;JGT // if (i-100)>0 goto END
//         \\@i
//         \\D=M// D=i
//         \\@sum
//         \\M=D+M // sum=sum+i
//         \\@i
//         \\M=M+1 // i=i+1
//         \\@LOOP
//         \\0;JMP // goto LOOP
//         \\(END)
//         \\@END
//         \\0;JMP // infinite loop
//     ;
//
//     try logger.printError("{s} {any}\n", .{ "Unexpected character, on line", 20 });
//     try logger.highlightError(buffer, 40);
// }

pub const Logger = struct {
    stderrWriter: Writer,
    stderr: std.fs.File,
    tty: std.io.tty.Config,

    pub fn init() Logger {
        const stderr = std.io.getStdErr();

        return .{
            .stderrWriter = stderr.writer(),
            .stderr = stderr,
            .tty = std.io.tty.detectConfig(stderr),
        };
    }

    pub fn printError(self: *const Logger, comptime fmt: []const u8, args: anytype) !void {
        var bw = std.io.bufferedWriter(self.stderrWriter);
        const stderrBw = bw.writer();

        try self.tty.setColor(stderrBw, .red);
        _ = try stderrBw.write("error: ");
        try self.tty.setColor(stderrBw, .reset);
        _ = try stderrBw.print(fmt, args);
        try bw.flush();
    }

    pub fn highlightError(self: *const Logger, buffer: []const u8, currentLineStart: u64, errPos: u64) !void {
        std.debug.assert(errPos < buffer.len and currentLineStart < errPos);

        var bw = std.io.bufferedWriter(self.stderrWriter);
        const stderrBw = bw.writer();

        var i: u64 = errPos;
        while (i < buffer.len and i < errPos + MAX) : (i += 1) {
            if (buffer[i] == '\n') break;
        }

        const slice = buffer[currentLineStart..i];
        const pos = errPos - currentLineStart;

        _ = try stderrBw.write(slice);
        _ = try stderrBw.write(" ...\n");

        for (slice, 0..) |c, j| {
            if (j != pos) {
                switch (c) {
                    ' ', '\t', '\r', std.ascii.control_code.vt, std.ascii.control_code.ff => |whitespace| {
                        try stderrBw.writeByte(whitespace);
                    },
                    '\n' => {
                        _ = try stderrBw.write(" " ** 3);
                    },
                    else => {
                        try stderrBw.writeByte(' ');
                    },
                }
            } else {
                try self.tty.setColor(stderrBw, .red);
                try stderrBw.writeByte('^');
                try self.tty.setColor(stderrBw, .reset);
            }
        }

        try stderrBw.writeByte('\n');
        try bw.flush();
    }
};
