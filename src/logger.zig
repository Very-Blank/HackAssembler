const std = @import("std");

const MIN = 30;
const MAX = 20;

// const BufferedWriter = std.io.BufferedWriter(4096, std.io.GenericWriter(std.fs.File, std.posix.WriteError, std.fs.File.write));
const Writer = std.io.GenericWriter(std.fs.File, std.posix.WriteError, std.fs.File.write);
// const Writer = std.io.GenericWriter(*BufferedWriter, std.posix.WriteError, BufferedWriter.write);

test "quick test" {
    var logger = Logger.init();
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

    try logger.printError("{s} {any}\n", .{ "Unexpected character, on line", 20 });
    try logger.highlightError(buffer, 40);
}

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

    pub fn printError(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
        var bw = std.io.bufferedWriter(self.stderrWriter);
        const stderrBw = bw.writer();

        try self.tty.setColor(stderrBw, .red);
        _ = try stderrBw.write("error: ");
        try self.tty.setColor(stderrBw, .reset);
        _ = try stderrBw.print(fmt, args);
        try bw.flush();
    }

    pub fn highlightError(self: *Logger, buffer: []const u8, errPos: u64) !void {
        std.debug.assert(errPos < buffer.len);

        var bw = std.io.bufferedWriter(self.stderrWriter);
        const stderrBw = bw.writer();

        var slice = buffer[if (MIN < errPos) errPos - MIN else 0..if (errPos + MAX < buffer.len) errPos + MAX + 1 else buffer.len];
        var pos = if (MIN < errPos) MIN else errPos;

        for (0..pos) |i| {
            if (slice[i] == '\n') {
                if (i + 1 != pos) {
                    slice = slice[i + 1 .. slice.len];
                    pos -= i + 1;
                }
                break;
            }
        }

        for (pos + 1..slice.len) |i| {
            if (slice[i] == '\n') {
                slice = slice[0..i];
                pos += i;
                break;
            }
        }

        for (slice) |c| {
            if (c != '\n') {
                try stderrBw.writeByte(c);
            } else {
                _ = try stderrBw.write("\\n ");
            }
        }

        _ = try stderrBw.write("...");
        try stderrBw.writeByte('\n');

        for (slice, 0..) |c, i| {
            if (i != pos) {
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
