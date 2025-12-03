const std = @import("std");
const print = std.debug.print;

fn part_a(min: u64, max: u64) !u64 {
    var buf = [_]u8{0} ** 16;
    var result: u64 = 0;

    for (min..max + 1) |nr| {
        const s = try std.fmt.bufPrint(&buf, "{d}", .{nr});
        if (s.len % 2 == 1) continue;
        if (std.mem.eql(u8, s[0 .. s.len / 2], s[s.len / 2 ..])) result += nr;
    }

    return result;
}

fn part_b(min: u64, max: u64) !u64 {
    var buf = [_]u8{0} ** 16;
    var result: u64 = 0;

    check: for (min..max + 1) |nr| {
        const s = try std.fmt.bufPrint(&buf, "{d}", .{nr});

        len: for (1..@divTrunc(s.len, 2) + 1) |length| {
            if (s.len % length != 0) continue;
            const parts = s.len / length;

            for (1..parts) |i| {
                const offset = i * length;
                if (!std.mem.eql(u8, s[0..length], s[offset .. offset + length])) continue :len;
            }

            result += nr;
            continue :check;
        }
    }

    return result;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day02.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 02\nInput File: {s}\n", .{file});

    var partA: u64 = 0;
    var partB: u64 = 0;

    var lines = std.mem.tokenizeScalar(u8, std.mem.trimEnd(u8, input, "\n"), ',');

    while (lines.next()) |line| {
        const range = std.mem.indexOfScalar(u8, line, '-') orelse unreachable;
        const min = try std.fmt.parseInt(u64, line[0..range], 10);
        const max = try std.fmt.parseInt(u64, line[range + 1 ..], 10);
        partA += try part_a(min, max);
        partB += try part_b(min, max);
    }
    print("Part A: {d}\n", .{partA});
    print("Part B: {d}\n", .{partB});
}
