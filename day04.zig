const std = @import("std");
const print = std.debug.print;

const Grid = struct {
    max_x: usize = 0,
    max_y: usize = 0,
    grid: []u8 = undefined,
    default: u8 = undefined,

    pub fn init(grid: []u8, default: u8) Grid {
        const max_x = std.mem.indexOfScalar(u8, grid, '\n') orelse unreachable;
        const max_y = grid.len / (max_x + 1);

        return @This(){
            .max_x = max_x,
            .max_y = max_y,
            .grid = grid,
            .default = default,
        };
    }

    pub fn get(self: @This(), x: isize, y: isize) u8 {
        if (x < 0 or y < 0 or x >= self.max_x or y >= self.max_y) return self.default;
        const ox: usize = @intCast(x);
        const oy: usize = @intCast(y);

        return self.grid[oy * (self.max_x + 1) + ox];
    }

    pub fn set(self: @This(), x: isize, y: isize, val: u8) void {
        if (x < 0 or y < 0 or x >= self.max_x or y >= self.max_y) return;
        const ox: usize = @intCast(x);
        const oy: usize = @intCast(y);

        self.grid[oy * (self.max_x + 1) + ox] = val;
    }

    pub fn neighbors(self: @This(), x: isize, y: isize) [8]u8 {
        return [8]u8{
            self.get(x - 1, y - 1),
            self.get(x - 1, y),
            self.get(x - 1, y + 1),

            self.get(x, y - 1),
            self.get(x, y + 1),

            self.get(x + 1, y - 1),
            self.get(x + 1, y),
            self.get(x + 1, y + 1),
        };
    }
};

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day04.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 04\nInput File: {s}\n", .{file});

    var part_a: u64 = 0;
    var part_b: u64 = 0;

    var grid = Grid.init(input, '.');

    print("Grid: {d}x{d}\n", .{ grid.max_x, grid.max_y });

    var y: isize = 0;
    while (y < grid.max_y) {
        var x: isize = 0;
        while (x < grid.max_x) {
            const c = grid.get(x, y);
            if (c == '@') {
                const neighbors = grid.neighbors(@intCast(x), @intCast(y));
                const count = std.mem.count(u8, &neighbors, "@");
                if (count < 4) {
                    part_a += 1;
                }
            }
            x += 1;
        }
        y += 1;
    }

    var removed: usize = 1;
    while (removed > 0) {
        y = 0;
        removed = 0;
        while (y < grid.max_y) {
            var x: isize = 0;
            while (x < grid.max_x) {
                const c = grid.get(x, y);
                if (c == '@') {
                    const neighbors = grid.neighbors(@intCast(x), @intCast(y));
                    const count = std.mem.count(u8, &neighbors, "@");
                    if (count < 4) {
                        part_b += 1;
                        grid.set(x, y, '.');
                        removed += 1;
                    }
                }
                x += 1;
            }
            y += 1;
        }
    }

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}
