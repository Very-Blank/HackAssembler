const std = @import("std");

pub const SymbolTable = struct {
    labels: std.StringHashMap(u15),
    addresses: std.StringHashMap(u15),
    variableCount: u15 = 15,

    pub fn init(allocator: std.mem.Allocator) SymbolTable {
        return .{
            .labels = std.StringHashMap(u15).init(allocator),
            .addresses = std.StringHashMap(u15).init(allocator),
        };
    }

    pub fn addVariable(self: *SymbolTable, symbol: []const u8) !u15 {
        const value = self.variableCount;
        self.variableCount += 1;

        try self.addresses.put(symbol, value);
        return value;
    }

    pub fn deinit(self: *SymbolTable) void {
        self.labels.deinit();
        self.addresses.deinit();
    }
};
