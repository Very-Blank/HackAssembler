const std = @import("std");

const MIN = 5;
const MAX = 5;

pub const Logger = struct {
    errWriter: std.io.GenericWriter(std.io.File, std.io.File.WriteError, std.io.File.write),

    pub fn init() Logger {
        return .{
            .errWriter = std.io.getStdErr().writer(),
        };
    }

    pub fn highlightError(self: *Logger, slice: []const u8, i: u64) void {
        const start = if (MIN < i) i - 5 else 0;
        const end = if (i + MAX < slice.len) i + MAX else slice.len;

        // NOTE: this is pretty bad.

        // self.errWriter.print("{s}\n", .{slice[start..end]});
        // for (slice[start..end]) |c| {
        //     if (c != '\n') self.errWriter.print("{c}", .{c});
        // }
        //
        // for (start..i) |_| {
        //     self.errWriter.print("_");
        // }
        //
        // self.errWriter.print("^");
    }
};
