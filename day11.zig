const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const Id = u24;
const Destinations = std.ArrayList(Id);
const WaysToGetToId = std.AutoArrayHashMap(Id, usize);
const ParsedInput = std.AutoArrayHashMap(Id, Destinations);

const Path = std.ArrayList(Id);

inline fn toId(str: []const u8) Id {
    assert(str.len == 3);
    return std.mem.bytesToValue(Id, std.mem.sliceAsBytes(str));
}

fn lessThan(dists: *WaysToGetToId, a: Id, b: Id) std.math.Order {
    const dist_a = dists.get(a) orelse @panic("unexpected dist");
    const dist_b = dists.get(b) orelse @panic("unexpected dist");
    return std.math.order(dist_a, dist_b);
}

fn parse(allocator: Allocator, input: []const u8) !ParsedInput {
    var destinations = ParsedInput.init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const from = toId(line[0..3]);
        var current_destinations = try Destinations.initCapacity(allocator, 24);

        var words = std.mem.tokenizeScalar(u8, line[5..], ' ');
        while (words.next()) |str| {
            const to = toId(str);
            current_destinations.appendAssumeCapacity(to);
        }

        try destinations.put(from, current_destinations);
    }

    return destinations;
}

fn countNumberOfWays(comptime start: Id, comptime end: Id, allocator: Allocator, destinations: ParsedInput) !?u64 {
    var ways = WaysToGetToId.init(allocator);
    var queue = std.PriorityQueue(Id, *WaysToGetToId, lessThan).init(allocator, &ways);
    defer queue.deinit();

    try queue.add(start);
    while (queue.count() > 0) {
        const current = queue.remove();

        if (destinations.get(current)) |dests_for_current| {
            for (dests_for_current.items) |d| {
                const c = ways.get(d) orelse 0;
                try ways.put(d, c + 1);
                if (d != end) try queue.add(d);
            }
        }
    }

    return ways.get(end);
}

fn partA(alloc: Allocator, input: []const u8) !u64 {
    const starting = comptime toId("you");
    const destination = comptime toId("out");

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const allocator = arena.allocator();

    const destinations = try parse(allocator, input);
    return (try countNumberOfWays(starting, destination, allocator, destinations)).?;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day11.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 11\nInput File: {s}\n", .{file});

    const part_a = try partA(gpa, input);
    // const part_b = try partB(gpa, input);

    print("Part A: {d}\n", .{part_a});
    // print("Part B: {d}\n", .{part_b});
}

test "day11a" {
    const input = @embedFile("example11a.txt");
    var allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();

    try std.testing.expectEqual(5, partA(gpa, input));
}
