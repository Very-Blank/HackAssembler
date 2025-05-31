const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const SymbolTable = @import("symbolTable.zig").SymbolTable;

pub const SecondPass = struct {
    instructions: []Instruction,
    symbolTable: SymbolTable,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *SecondPass) void {
        self.allocator.free(self.instructions);
        self.symbolTable.deinit();
    }

    /// Caller owns the memory allocated for the buffer.
    pub fn secondPass(self: *SecondPass) ![]u8 {
        std.debug.assert(self.instructions.len != 0);

        var buffer: []u8 = try self.allocator.alloc(u8, self.instructions.len * 16 + self.instructions.len);
        errdefer self.allocator.free(buffer);

        var i: u64 = 0;
        for (self.instructions) |instruction| {
            switch (instruction.type) {
                .c => |c| {
                    const binary: u16 = c.toBinary();
                    inline for (0..16) |j| {
                        buffer[i] = if (binary & 1 << (15 - j) == 1 << (15 - j)) '1' else '0';
                        i += 1;
                    }

                    buffer[i] = '\n';
                    i += 1;
                },
                .a => |a| {
                    switch (a) {
                        .symbol => |symbol| {
                            const binary: u16 = if (self.symbolTable.labels.get(symbol)) |label| @intCast(label) else if (self.symbolTable.addresses.get(symbol)) |variable| @intCast(variable) else @intCast(try self.symbolTable.addVariable(symbol));

                            inline for (0..16) |j| {
                                buffer[i] = if (binary & 1 << (15 - j) == 1 << (15 - j)) '1' else '0';
                                i += 1;
                            }

                            buffer[i] = '\n';
                            i += 1;
                        },
                        .value => |value| {
                            const binary: u16 = @intCast(value);
                            inline for (0..16) |j| {
                                buffer[i] = if (binary & 1 << (15 - j) == 1 << (15 - j)) '1' else '0';
                                i += 1;
                            }

                            buffer[i] = '\n';
                            i += 1;
                        },
                    }
                },
            }
        }

        return buffer;
    }
};
