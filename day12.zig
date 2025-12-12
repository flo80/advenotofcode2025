const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

fn partA(input: []const u8) !usize {
    var part_a: usize = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (line.len == 2) {
            // beginning of a pattern
            inline for (0..3) |_| _ = lines.next();
            continue;
        }

        // challenge line
        const x = try std.fmt.parseInt(usize, line[0..2], 10);
        const y = try std.fmt.parseInt(usize, line[3..5], 10);
        const size = 3 * 3;

        var count: usize = 0;

        var tokens = std.mem.tokenizeScalar(u8, line[7..], ' ');
        while (tokens.next()) |token| {
            const value = try std.fmt.parseInt(u8, token, 10);
            count += value;
        }

        if (count * size <= x * y) part_a += 1;
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
    const file = args.next() orelse "day12.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 12\nInput File: {s}\n", .{file});

    const part_a = try partA(input);
    const part_b = try partB(gpa, input);

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}
