const std = @import("std");

pub const SymbolTable = struct {
    // Altough they could be in the same hashmap, since they mean different things I will keep them seperate.
    labels: std.StringHashMap(u64),
    variables: std.StringHashMap(u64),

    pub fn init(allocator: std.mem.Allocator) SymbolTable {
        return .{
            .labels = std.StringHashMap(u64).init(allocator),
            .variables = std.StringHashMap(u64).init(allocator),
        };
    }

    pub fn deinit(self: *SymbolTable) void {
        self.labels.deinit();
        self.variables.deinit();
    }
};
