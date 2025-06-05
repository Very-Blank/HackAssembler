const std = @import("std");
const FirstPass = @import("firstPass.zig").FirstPass;
const SecondPass = @import("secondPass.zig").SecondPass;
const instruction = @import("instruction.zig");
const SymbolTable = @import("symbolTable.zig").SymbolTable;
const Logger = @import("logger.zig").Logger;

pub const Assembler = struct {
    logger: Logger,
    firstPass: FirstPass,

    pub fn init(allocator: std.mem.Allocator) !Assembler {
        return .{
            .logger = Logger.init(),
            .firstPass = try FirstPass.init(allocator),
        };
    }

    pub fn deinit(self: *Assembler) void {
        self.firstPass.deinit();
    }

    pub fn assemble(self: *Assembler, buffer: []u8) ![]u8 {
        var secondPass: SecondPass = try self.firstPass.firstPass(buffer, self.logger);
        defer secondPass.deinit();

        const assembledCode = try secondPass.secondPass();
        return assembledCode;
    }
};
