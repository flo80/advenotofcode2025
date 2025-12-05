const std = @import("std");
const print = std.debug.print;

const Range = struct {
    min: u64,
    max: u64,

    pub inline fn items(self: Range) u64 {
        return self.max - self.min + 1;
    }

    pub inline fn includes(self: Range, val: u64) bool {
        return val >= self.min and val <= self.max;
    }

    pub fn extend(self: *Range, other: Range) bool {
        // other fully inside self
        if (other.min >= self.min and other.max <= self.max) {
            return true;
        }

        // other strictly bigger than self
        if (other.min <= self.min and other.max >= self.max) {
            self.min = other.min;
            self.max = other.max;
            return true;
        }

        // other extends to the left
        if (other.min <= self.min and other.max >= self.min) {
            self.min = other.min;
            return true;
        }

        // other extends to the right
        if (other.min <= self.max and other.max >= self.max) {
            self.max = other.max;
            return true;
        }
        return false;
    }
};

fn parseRanges(gpa: std.mem.Allocator, block: []const u8) !std.ArrayList(Range) {
    var ranges = try std.ArrayList(Range).initCapacity(gpa, 200);

    var lines = std.mem.tokenizeScalar(u8, block, '\n');
    while (lines.next()) |line| {
        const sep = std.mem.indexOfScalar(u8, line, '-') orelse unreachable;

        const range = Range{
            .min = try std.fmt.parseInt(u64, line[0..sep], 10),
            .max = try std.fmt.parseInt(u64, line[sep + 1 ..], 10),
        };

        try ranges.append(gpa, range);
    }

    consolidateRanges(&ranges);

    return ranges;
}

fn consolidateRanges(ranges: *std.ArrayList(Range)) void {
    var curr: usize = 0;
    consolidate: while (curr < ranges.items.len) {
        var current = &ranges.items[curr];

        for (curr + 1..ranges.items.len) |i| {
            if (current.extend(ranges.items[i])) {
                _ = ranges.swapRemove(i);
                continue :consolidate;
            }
        }
        // nothing was consolidated
        curr += 1;
    }
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day05.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 05\nInput File: {s}\n", .{file});

    var part_a: u64 = 0;
    var part_b: u64 = 0;

    var blocks = std.mem.tokenizeSequence(u8, std.mem.trimEnd(u8, input, "\n"), "\n\n");

    var ranges = try parseRanges(gpa, blocks.next() orelse unreachable);
    defer ranges.deinit(gpa);

    var lines = std.mem.tokenizeScalar(u8, blocks.next() orelse unreachable, '\n');
    check: while (lines.next()) |line| {
        const val = try std.fmt.parseInt(u64, line, 10);

        for (ranges.items) |range| {
            if (range.includes(val)) {
                part_a += 1;
                continue :check;
            }
        }
    }

    for (ranges.items) |range| {
        part_b += range.items();
    }

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}
