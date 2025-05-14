const std = @import("std");

pub const Line = struct {
    start: u64,
    end: u64,

    pub const init: Line = .{ .start = 0, .end = 0 };
};

pub const BufferReader = struct {
    buffer: []u8,
    line: Line,

    pub fn init(buffer: []u8) {}

};

