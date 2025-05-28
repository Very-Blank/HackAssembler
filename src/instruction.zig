pub const A = union(enum) {
    symbol: []const u8,
    value: u64,
};

pub const Destination = enum { M, D, MD, A, AM, AD, AMD };

pub const Computation = enum {
    // zig fmt: off
    @"0", @"1", @"-1", D,
    A, @"!D", @"!A", @"-D",
    @"-A", @"D+1", @"A+1", @"D-1",
    @"A-1", @"D+A", @"D-A", @"A-D",
    @"D&A", @"D|A", M, @"!M",
    @"-M", @"M+1", @"M-1", @"D+M",
    @"D-M", @"M-D", @"D&M", @"D|M",
    // zig fmt: on
};

pub const Jump = enum { JGT, JEQ, JGE, JLT, JNE, JLE, JMP };

pub const C = union(enum) {
    dcj: struct { dest: Destination, comp: Computation, jump: Jump },
    dc: struct { dest: Destination, comp: Computation },
    cj: struct { comp: Computation, jump: Jump },
};

pub const Instruction = struct {
    line: u64,
    type: Type,
};

pub const Type = union(enum) {
    a: A,
    c: C,
};
