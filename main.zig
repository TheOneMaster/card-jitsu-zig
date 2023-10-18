// Imports
const std = @import("std");
const misc = @import("misc.zig");
const logic = @import("logic.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    // try stdout.print("Card-Jitsu demo\n", .{});
    try misc.simplePrint("Card-Jitsu demo");

    // Objects
    // var rand = misc.randomGenerator();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.os.getrandom(std.mem.asBytes(&seed)) catch {};
        break :blk seed;
    });

    var player_1 = logic.createPlayer(&prng);
    var player_2 = logic.createPlayer(&prng);

    var player1Turn: bool = true;

    var selectedCards: [2]logic.Card = undefined;

    // Game loop
    while (!logic.hasWon(player_1) and !logic.hasWon(player_2)) {
        var playerSelected = if (player1Turn) &player_1 else &player_2;
        var card_choice: u8 = undefined;

        if (player1Turn) {
            // try stdout.print("Available Cards:\n", .{});
            try misc.simplePrint("Available Cards:");
            try misc.printPlayerCards(playerSelected.*);

            card_choice = misc.getUnsignedNumberInput() catch 0;
        } else {
            card_choice = prng.random().intRangeAtMost(u8, 0, 4);
        }

        // const cardChoice = getUnsignedNumberInput() catch 0;
        const selectedCard: logic.Card = logic.useCard(playerSelected, card_choice, &prng);

        const player_index: u8 = @intFromBool(!player1Turn);
        // selectedCards[player_index] = selectedCard;
        selectedCards[player_index] = selectedCard;
        try stdout.print("Selected - Type: {s}, Value: {}\n", .{ @tagName(selectedCard.kind), selectedCard.value });

        if (!player1Turn) {
            const result = logic.checkWin(selectedCards);

            switch (result) {
                .win => player_1.wins[@intFromEnum(selectedCards[0].kind)] += 1,
                .loss => player_2.wins[@intFromEnum(selectedCards[1].kind)] += 1,
                .draw => {},
            }

            try stdout.print("{s}\n", .{@tagName(result)});
        }

        player1Turn = !player1Turn;
    }

    const player_string = if (logic.hasWon(player_1)) "Player 1" else "Player 2 (CPU)";
    try stdout.print("{s} has won. Game is over.\n", .{player_string});
}
