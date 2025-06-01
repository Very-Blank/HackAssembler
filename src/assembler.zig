const std = @import("std");
const FirstPass = @import("HackAsm").FirstPass;
const SecondPass = @import("HackAsm").SecondPass;
const instruction = @import("HackAsm");
const SymbolTable = @import("HackAsm").SymbolTable;

pub const Assembler = struct {
    firstPass: FirstPass,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Assembler {
        return .{
            .firstPass = try FirstPass.init(allocator),
        };
    }

    pub fn deinit(self: *Assembler) void {
        self.firstPass.deinit();
    }

    pub fn assemble(self: *Assembler, buffer: []u8) []u8 {
        var secondPass: SecondPass = try self.firstPass.firstPass(buffer);
        defer secondPass.deinit();

        const assembledCode = try secondPass.secondPass();
        return assembledCode;
    }
};
