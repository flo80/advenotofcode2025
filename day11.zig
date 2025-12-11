const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const Id = u24;
const Destinations = std.ArrayList(Id);
const ParsedInput = std.AutoArrayHashMap(Id, Destinations);

inline fn toId(str: []const u8) Id {
    assert(str.len == 3);
    return std.mem.bytesToValue(Id, std.mem.sliceAsBytes(str));
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

const MemoizedCount = struct {
    destinations: ParsedInput,
    cache: std.AutoHashMap(u48, u64),

    pub fn init(allocator: Allocator, destinations: ParsedInput) @This() {
        return .{
            .destinations = destinations,
            .cache = std.AutoHashMap(u48, u64).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.cache.deinit();
    }

    pub fn count(self: *@This(), start: Id, end: Id) !u64 {
        if (start == end) return 1;

        const key = @as(u48, start) << 24 | @as(u48, end);
        if (self.cache.get(key)) |res| return res;

        var value: u64 = 0;
        if (self.destinations.get(start)) |dests_for_current| {
            for (dests_for_current.items) |d| {
                value += try self.count(d, end);
            }
        }

        try self.cache.put(key, value);
        return value;
    }
};

fn partA(ct: *MemoizedCount) !u64 {
    return try ct.count(comptime toId("you"), comptime toId("out"));
}

fn partB(ct: *MemoizedCount) !u64 {
    const svr_dac_fft_out =
        try ct.count(comptime toId("svr"), comptime toId("dac")) *
        try ct.count(comptime toId("dac"), comptime toId("fft")) *
        try ct.count(comptime toId("fft"), comptime toId("out"));

    const svr_fft_dac_out =
        try ct.count(comptime toId("svr"), comptime toId("fft")) *
        try ct.count(comptime toId("fft"), comptime toId("dac")) *
        try ct.count(comptime toId("dac"), comptime toId("out"));

    return svr_dac_fft_out + svr_fft_dac_out;
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

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const destinations = try parse(arena_allocator, input);
    var memo_count = MemoizedCount.init(arena_allocator, destinations);

    const part_a = try partA(&memo_count);
    const part_b = try partB(&memo_count);

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}

test "day11a" {
    const input = @embedFile("example11a.txt");
    var allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const destinations = try parse(arena_allocator, input);
    var memo_count = MemoizedCount.init(arena_allocator, destinations);

    try std.testing.expectEqual(5, partA(&memo_count));
}

test "day11b" {
    const input = @embedFile("example11b.txt");
    var allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const destinations = try parse(arena_allocator, input);
    var memo_count = MemoizedCount.init(arena_allocator, destinations);

    try std.testing.expectEqual(2, partB(&memo_count));
}
