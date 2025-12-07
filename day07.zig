const std = @import("std");
const print = std.debug.print;

const Grid = struct {
    max_x: usize = 0,
    max_y: usize = 0,
    grid: []const u8 = undefined,

    pub fn init(grid: []const u8) Grid {
        const max_x = std.mem.indexOfScalar(u8, grid, '\n') orelse unreachable;
        const max_y = grid.len / (max_x + 1);

        return @This(){
            .max_x = max_x,
            .max_y = max_y,
            .grid = grid,
        };
    }

    pub fn get(self: @This(), x: usize, y: usize) ?u8 {
        if (x >= self.max_x or y >= self.max_y) return null;
        return self.grid[y * (self.max_x + 1) + x];
    }
};

fn runBeams(grid: Grid) struct { splits: usize, ways: usize } {
    std.debug.assert(grid.max_x < 256);
    var beams: @Vector(256, usize) = [_]usize{0} ** 256;

    var splits: usize = 0;

    const start_position = std.mem.indexOfScalar(u8, grid.grid, 'S') orelse unreachable;
    beams[start_position] = 1;

    for (1..grid.max_y) |y| {
        for (0..grid.max_x + 1) |x| {
            const val = grid.get(x, y) orelse continue;

            if (val == '^' and beams[x] > 0) {
                beams[x - 1] += beams[x];
                beams[x + 1] += beams[x];
                beams[x] = 0;
                splits += 1;
            }
        }
    }
    return .{
        .splits = splits,
        .ways = @reduce(.Add, beams),
    };
}

fn partA(grid: Grid) !usize {
    const res = runBeams(grid);
    return res.splits;
}

fn partB(grid: Grid) !usize {
    const res = runBeams(grid);
    return @reduce(.Add, res.ways);
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day07.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 07\nInput File: {s}\n", .{file});
    const grid = Grid.init(input);
    const result = runBeams(grid);

    print("Part A: {d}\n", .{result.splits});
    print("Part B: {d}\n", .{result.ways});
}

test "day07" {
    const input = @embedFile("example07.txt");

    const grid = Grid.init(input);

    try std.testing.expectEqual(15, grid.max_x);
    try std.testing.expectEqual(16, grid.max_y);

    const result = runBeams(grid);

    try std.testing.expectEqual(21, result.splits);
    try std.testing.expectEqual(40, result.ways);
}
