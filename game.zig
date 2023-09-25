// Imports
const std = @import("std");
const misc = @import("misc.zig");

// Types
const Attribute = enum(u8) { WATER, FIRE, ICE };
const Card = struct { kind: Attribute, value: u8 };
const Player = struct { cards: [5]Card, wins: [3]u8 };
const Result = enum { win, draw, loss };

const RNG = *std.rand.Xoshiro256;
const TypeChart = std.AutoHashMap(Attribute, Attribute);

/// Game Logic
fn drawCard(rng: RNG) Card {
    const randomType: Attribute = rng.*.random().enumValue(Attribute);
    const randomValue: u8 = rng.*.random().intRangeAtMost(u8, 1, 12);

    const generatedCard = Card{ .kind = randomType, .value = randomValue };

    return generatedCard;
}

fn createPlayer(rng: RNG) Player {
    var cards: [5]Card = undefined;
    for (&cards) |*card| {
        card.* = drawCard(rng);
    }

    var wins = [3]u8{ 0, 0, 0 };
    var finalPlayer = Player{ .cards = cards, .wins = wins };
    return finalPlayer;
}

fn printPlayerCards(player: Player) !void {
    const stdout = std.io.getStdOut().writer();

    for (player.cards, 0..) |card, index| {
        try stdout.print("\t{}. Type: {s}, Value: {}\n", .{ index, @tagName(card.kind), card.value });
    }
}

fn hasWon(player: Player) bool {
    const wins = player.wins;
    var typeWins = [3]bool{ false, false, false };

    for (wins, 0..) |numWins, index| {
        if (numWins == 3) return true;
        if (numWins > 0) typeWins[index] = true;
    }

    if (misc.allTrue(&typeWins)) return true;
    return false;
}

fn checkWin(selected: [2]Card) Result {
    const p1_card = selected[0];
    const p2_card = selected[1];

    var result: Result = switch (p1_card.kind) {
        .FIRE => switch (p2_card.kind) {
            .FIRE => sameTypeResult(p1_card, p2_card),
            .ICE => Result.win,
            .WATER => Result.loss,
        },
        .ICE => switch (p2_card.kind) {
            .FIRE => Result.loss,
            .ICE => sameTypeResult(p1_card, p2_card),
            .WATER => Result.win,
        },
        .WATER => switch (p2_card.kind) {
            .FIRE => Result.win,
            .ICE => Result.loss,
            .WATER => sameTypeResult(p1_card, p2_card),
        },
    };

    return result;
}

fn sameTypeResult(card1: Card, card2: Card) Result {
    const same_value = card1.value == card2.value;
    if (same_value) return Result.draw;

    const final_result: Result = if (card1.value > card2.value) Result.win else Result.loss;
    return final_result;
}

/// Draws the card from the user's deck and replaces it with a new card
fn useCard(player: *Player, card_index: u8, rng: RNG) Card {
    var current_deck = player.*.cards;
    const selected_card = current_deck[card_index];
    const new_card = drawCard(rng);

    // Replace card in the struct
    current_deck[card_index] = new_card;
    player.*.cards = current_deck;

    return selected_card;
}

/// IO functions
fn getUnsignedNumberInput() !u8 {
    const stdin = std.io.getStdIn().reader();
    var buffer: [10]u8 = undefined;
    if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |user_input| {
        return std.fmt.parseInt(u8, user_input, 10);
    } else {
        return @as(u8, 0);
    }
}

// Main
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

    var player_1 = createPlayer(&prng);
    var player_2 = createPlayer(&prng);

    var player1Turn: bool = true;

    var selectedCards: [2]Card = undefined;

    // Game loop
    while (!hasWon(player_1) and !hasWon(player_2)) {
        var playerSelected = if (player1Turn) &player_1 else &player_2;
        var card_choice: u8 = undefined;

        if (player1Turn) {
            // try stdout.print("Available Cards:\n", .{});
            try misc.simplePrint("Available Cards:");
            try printPlayerCards(playerSelected.*);

            card_choice = getUnsignedNumberInput() catch 0;
        } else {
            // var rand = misc.randomGenerator();
            card_choice = prng.random().intRangeAtMost(u8, 0, 4);
        }

        // const cardChoice = getUnsignedNumberInput() catch 0;
        const selectedCard: Card = useCard(playerSelected, card_choice, &prng);

        const player_index: u8 = @intFromBool(!player1Turn);
        // selectedCards[player_index] = selectedCard;
        selectedCards[player_index] = selectedCard;
        try stdout.print("Selected - Type: {s}, Value: {}\n", .{ @tagName(selectedCard.kind), selectedCard.value });

        if (!player1Turn) {
            const result = checkWin(selectedCards);

            switch (result) {
                .win => player_1.wins[@intFromEnum(selectedCards[0].kind)] += 1,
                .loss => player_2.wins[@intFromEnum(selectedCards[1].kind)] += 1,
                .draw => undefined,
            }

            try stdout.print("{s}\n", .{@tagName(result)});
        }

        player1Turn = !player1Turn;
    }

    const player_string = if (hasWon(player_1)) "Player 1" else "Player 2 (CPU)";
    try stdout.print("{s} has won. Game is over.\n", .{player_string});
}
