const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Button = u16;
const Light = Button;
const max_buttons = @bitSizeOf(Button);
const BitInButton = std.math.Log2Int(Button);

fn parseLight(str: []const u8) Light {
    var result: Light = 0;
    for (str[1 .. str.len - 1], 0..) |char, i| {
        if (char == '#') result |= @as(Light, 1) << @as(BitInButton, @intCast(i));
    }
    return result;
}

fn parseButton(str: []const u8) !Button {
    var nrs = std.mem.splitScalar(u8, str[1 .. str.len - 1], ',');
    var result: Button = 0;
    while (nrs.next()) |nr_string| {
        const nr = try std.fmt.parseInt(BitInButton, nr_string, 10);
        result |= @as(Button, 1) << nr;
    }
    return result;
}

fn sortByPopCount(_: void, a: Button, b: Button) bool {
    return @popCount(a) < @popCount(b);
}

fn partA(allocator: Allocator, input: []const u8) !usize {
    _ = allocator;
    var part_a: usize = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    check: while (lines.next()) |line| {
        if (line.len == 0) continue;

        var tokens = std.mem.splitScalar(u8, line, ' ');
        const lights = parseLight(tokens.next().?);

        var buttons_buffer: [max_buttons]Button = undefined;
        var buttons = std.ArrayList(Button).initBuffer(&buttons_buffer);

        while (tokens.next()) |token| {
            if (token[0] == '{') break;
            const button = try parseButton(token);
            buttons.appendAssumeCapacity(button);
        }

        var potential_options_buffer: [(1 << max_buttons)]Button = undefined;
        var potential_options = std.ArrayList(Button).initBuffer(&potential_options_buffer);
        for (1..(@as(Button, 1) << @as(BitInButton, @truncate(buttons.items.len)))) |b| potential_options.appendAssumeCapacity(@as(Button, @truncate(b)));
        std.mem.sortUnstable(Button, potential_options.items, {}, sortByPopCount);

        for (potential_options.items) |used_buttons| {
            var current_lights: Button = 0;
            for (buttons.items, 0..) |button_value, i| {
                const button_number = @as(Button, 1) << @as(BitInButton, @truncate(i));
                if (button_number & used_buttons > 0)
                    current_lights ^= button_value;
            }

            if (current_lights == lights) {
                part_a += @popCount(used_buttons);
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
