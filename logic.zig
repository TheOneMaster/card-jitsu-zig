const std = @import("std");
const misc = @import("misc.zig");

pub const Attribute = enum(u8) { WATER, FIRE, ICE };
pub const Card = struct { kind: Attribute, value: u8 };
pub const Player = struct { cards: [5]Card, wins: [3]u8 };
pub const Result = enum { win, draw, loss };

const RNG = *std.rand.Xoshiro256;
pub const TypeChart = std.AutoHashMap(Attribute, Attribute);

pub fn drawCard(rng: RNG) Card {
    const randomType: Attribute = rng.*.random().enumValue(Attribute);
    const randomValue: u8 = rng.*.random().intRangeAtMost(u8, 1, 12);

    const generatedCard = Card{ .kind = randomType, .value = randomValue };

    return generatedCard;
}

pub fn createPlayer(rng: RNG) Player {
    var cards: [5]Card = undefined;
    for (&cards) |*card| {
        card.* = drawCard(rng);
    }

    var wins = [3]u8{ 0, 0, 0 };
    var finalPlayer = Player{ .cards = cards, .wins = wins };
    return finalPlayer;
}

pub fn hasWon(player: Player) bool {
    const wins = player.wins;
    var typeWins = [3]bool{ false, false, false };

    for (wins, 0..) |numWins, index| {
        if (numWins == 3) return true;
        if (numWins > 0) typeWins[index] = true;
    }

    if (misc.allTrue(&typeWins)) return true;
    return false;
}

pub fn checkWin(selected: [2]Card) Result {
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

pub fn sameTypeResult(card1: Card, card2: Card) Result {
    const same_value = card1.value == card2.value;
    if (same_value) return Result.draw;

    const final_result: Result = if (card1.value > card2.value) Result.win else Result.loss;
    return final_result;
}

/// Draws the card from the user's deck and replaces it with a new card
pub fn useCard(player: *Player, card_index: u8, rng: RNG) Card {
    var current_deck = player.*.cards;
    const selected_card = current_deck[card_index];
    const new_card = drawCard(rng);

    // Replace card in the struct
    current_deck[card_index] = new_card;
    player.*.cards = current_deck;

    return selected_card;
}
