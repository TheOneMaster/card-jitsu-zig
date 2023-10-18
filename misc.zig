const std = @import("std");
const logic = @import("logic.zig");

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

pub fn printPlayerCards(player: logic.Player) !void {
    const stdout = std.io.getStdOut().writer();

    for (player.cards, 0..) |card, index| {
        try stdout.print("\t{}. Type: {s}, Value: {}\n", .{ index, @tagName(card.kind), card.value });
    }
}

pub fn getUnsignedNumberInput() !u8 {
    const stdin = std.io.getStdIn().reader();
    var buffer: [10]u8 = undefined;
    if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |user_input| {
        return std.fmt.parseInt(u8, user_input, 10);
    } else {
        return 0;
    }
}
