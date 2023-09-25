const std = @import("std");

pub fn allTrue(arr: []bool) bool {
    for (arr) |val| {
        if (!val) return false;
    }
    return true;
}

pub fn simplePrint(comptime string: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{string});
}
