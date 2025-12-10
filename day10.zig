const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

fn parseLight(str: []const u8) u16 {
    var result: u16 = 0;
    for (str[1 .. str.len - 1], 0..) |char, i| {
        if (char == '#') result |= @as(u16, 1) << @as(u4, @intCast(i));
    }
    return result;
}

fn parseButton(str: []const u8) !u16 {
    var nrs = std.mem.splitScalar(u8, str[1 .. str.len - 1], ',');
    var result: u16 = 0;
    while (nrs.next()) |nr_string| {
        const nr = try std.fmt.parseInt(u4, nr_string, 10);
        result |= @as(u16, 1) << nr;
    }
    return result;
}

const maxButtons = 16;

fn findCombination(target: u16, buttons: []u16, number_of_buttons: u4) bool {
    var used_buttons_buffer: [maxButtons]u4 = undefined;
    var used_buttons = std.ArrayList(u4).initBuffer(&used_buttons_buffer);

    std.debug.assert(number_of_buttons <= buttons.len);

    for (0..number_of_buttons) |button_nr| {
        used_buttons.appendAssumeCapacity(@as(u4, @truncate(button_nr)));
    }
    std.debug.assert(used_buttons.items.len == number_of_buttons);

    check: while (true) {
        var current_number: u16 = 0;
        for (used_buttons.items) |button_nr| current_number ^= buttons[button_nr];

        if (current_number == target) return true;

        getNr: while (true) {
            if (used_buttons.pop()) |last| {
                if (last < buttons.len - 1) {
                    used_buttons.appendAssumeCapacity(last + 1);

                    while (used_buttons.items.len < number_of_buttons) {
                        const next = used_buttons.getLast() + 1;
                        if (next >= buttons.len) continue :getNr;
                        used_buttons.appendAssumeCapacity(next);
                    }

                    continue :check;
                } // else: go back to popping last number
            } else {
                // we ran out of options for the first number
                return false;
            }
        }
        return false;
    }
}

fn partA(allocator: Allocator, input: []const u8) !usize {
    _ = allocator;
    var part_a: usize = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    check: while (lines.next()) |line| {
        if (line.len == 0) continue;

        var tokens = std.mem.splitScalar(u8, line, ' ');
        const lights = parseLight(tokens.next().?);

        var buttons_buffer: [maxButtons]u16 = undefined;
        var buttons = std.ArrayList(u16).initBuffer(&buttons_buffer);

        while (tokens.next()) |token| {
            if (token[0] == '{') break;
            const button = try parseButton(token);
            buttons.appendAssumeCapacity(button);
        }

        for (1..buttons.items.len + 1) |max_buttons| {
            if (findCombination(lights, buttons.items, @as(u4, @truncate(max_buttons)))) {
                part_a += max_buttons;
                continue :check;
            }
        }

        @panic("No combination found");
    }

    return part_a;
}

fn partB(allocator: Allocator, input: []const u8) !u64 {
    _ = allocator;
    _ = input;
    return 0;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day10.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 10\nInput File: {s}\n", .{file});

    const part_a = try partA(gpa, input);
    const part_b = try partB(gpa, input);

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}

test "day10" {
    const input = @embedFile("example10.txt");
    var allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();

    try std.testing.expectEqual(7, partA(gpa, input));
    try std.testing.expectEqual(0, partB(gpa, input));
}
