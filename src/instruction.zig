const std = @import("std");

pub const A = union(enum) {
    symbol: []const u8,
    value: u15,

    pub fn debugPrint(self: *const A) void {
        switch (self.*) {
            .symbol => |symbol| {
                std.debug.print("A Instruction (Symbol). Symbol: {s}\n", .{symbol});
            },
            .value => |value| {
                std.debug.print("A Instruction (Value). Value: {any}\n", .{value});
            },
        }
    }
};

pub const Destination = enum(u3) {
    M = 0b001,
    D = 0b010,
    MD = 0b011,
    A = 0b100,
    AM = 0b101,
    AD = 0b110,
    AMD = 0b111,
};

pub const Jump = enum(u3) {
    JGT = 0b001,
    JEQ = 0b010,
    JGE = 0b011,
    JLT = 0b100,
    JNE = 0b101,
    JLE = 0b110,
    JMP = 0b111,
};

pub const Computation = enum(u8) {
    // a=0 computations
    @"0" = 0b0_101010,
    @"1" = 0b0_111111,
    @"-1" = 0b0_111010,
    D = 0b0_001100,
    A = 0b0_110000,
    @"!D" = 0b0_001101,
    @"!A" = 0b0_110001,
    @"-D" = 0b0_001111,
    @"-A" = 0b0_110011,
    @"D+1" = 0b0_011111,
    @"A+1" = 0b0_110111,
    @"D-1" = 0b0_001110,
    @"A-1" = 0b0_110010,
    @"D+A" = 0b0_000010,
    @"D-A" = 0b0_010011,
    @"A-D" = 0b0_000111,
    @"D&A" = 0b0_000000,
    @"D|A" = 0b0_010101,

    // a=1 computations (memory access)
    M = 0b1_110000,
    @"!M" = 0b1_110001,
    @"-M" = 0b1_110011,
    @"M+1" = 0b1_110111,
    @"M-1" = 0b1_110010,
    @"D+M" = 0b1_000010,
    @"D-M" = 0b1_010011,
    @"M-D" = 0b1_000111,
    @"D&M" = 0b1_000000,
    @"D|M" = 0b1_010101,
};

pub const C = union(enum) {
    dcj: struct { dest: Destination, comp: Computation, jump: Jump },
    dc: struct { dest: Destination, comp: Computation },
    cj: struct { comp: Computation, jump: Jump },

    pub inline fn toBinary(self: *const C) u16 {
        switch (self.*) {
            .dcj => |value| return 0b111_0_000000_000_000 + (@as(u16, @intCast(@intFromEnum(value.comp))) << 6) + (@as(u16, @intCast(@intFromEnum(value.dest))) << 3) + @as(u16, @intCast(@intFromEnum(value.jump))),
            .dc => |value| return 0b111_0_000000_000_000 + (@as(u16, @intCast(@intFromEnum(value.comp))) << 6) + (@as(u16, @intCast(@intFromEnum(value.dest))) << 3),
            .cj => |value| return 0b111_0_000000_000_000 + (@as(u16, @intCast(@intFromEnum(value.comp))) << 6) + (@as(u16, @intCast(@intFromEnum(value.jump)))),
        }
    }

    pub fn debugPrint(self: *const C) void {
        switch (self.*) {
            .dcj => |value| std.debug.print("C Instruction (DCJ). Dest: {any}, Comp: {any}, Jump: {any}. In binary: {b}\n", .{ value.dest, value.comp, value.jump, self.toBinary() }),
            .dc => |value| std.debug.print("C Instruction (DC). Dest: {any}, Comp: {any}. In binary: {b}\n", .{ value.dest, value.comp, self.toBinary() }),
            .cj => |value| std.debug.print("C Instruction (CJ). Comp: {any}, Jump: {any}. In binary: {b}\n", .{ value.comp, value.jump, self.toBinary() }),
        }
    }
};

pub const Instruction = struct {
    line: u64,
    type: Type,

    pub fn debugPrint(self: *const Instruction) void {
        std.debug.print("Line {any}, ", .{self.line});
        self.type.debugPrint();
    }
};

pub const Type = union(enum) {
    a: A,
    c: C,
    pub fn debugPrint(self: *const Type) void {
        switch (self.*) {
            .a => |a| a.debugPrint(),
            .c => |c| c.debugPrint(),
        }
    }
};
