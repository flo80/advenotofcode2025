const std = @import("std");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day01.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    std.debug.print("Day 01\nInput File: {s}\n", .{file});

    var partA: i32 = 0;
    var partB: i32 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var pos: i32 = 50;

    while (lines.next()) |line| {
        const sign: i32 = if (line[0] == 'R') 1 else -1;
        const val = (try std.fmt.parseInt(i32, line[1..], 10)) * sign;

        if (val > 0) {
            partB += @divFloor(pos + val, 100) - @divFloor(pos, 100);
        } else {
            partB += @divFloor(pos - 1, 100) - @divFloor(pos - 1 + val, 100);
        }

        pos = @mod(pos + val, 100);
        partA += if (pos == 0) 1 else 0;
    }
    std.debug.print("Part A: {d}\n", .{partA});
    std.debug.print("Part B: {d}\n", .{partB});
}
