const std = @import("std");
const print = std.debug.print;

fn part_a(line: []const u8) u32 {
    var posA: usize = 0;
    for (1..line.len - 1) |i| {
        if (line[i] > line[posA]) posA = i;
    }

    var posB: usize = posA + 1;
    for (posA + 2..line.len) |i| {
        if (line[i] > line[posB]) posB = i;
    }

    const nr = (line[posA] - '0') * 10 + (line[posB] - '0');
    return nr;
}

fn solve(comptime digits: u8, line: []const u8) u64 {
    var positions = [_]usize{0} ** digits;
    var nr: u64 = 0;

    inline for (0..digits) |p| {
        const start = if (p == 0) 1 else positions[p - 1] + 2;
        const end = line.len - (digits - p) + 1;
        positions[p] = start - 1;
        for (start..end) |i| {
            if (line[i] > line[positions[p]]) positions[p] = i;
        }
        nr = nr * 10 + (line[positions[p]] - '0');
    }

    return nr;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day03.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 03\nInput File: {s}\n", .{file});

    var partA: u64 = 0;
    var partB: u64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        partA += solve(2, line);
        partB += solve(12, line);
    }
    print("Part A: {d}\n", .{partA});
    print("Part B: {d}\n", .{partB});
}
